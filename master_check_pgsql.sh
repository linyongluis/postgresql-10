#!/usr/bin/env bash
#set slaveip
slaveip=192.168.59.2

#set pg data location
PGDATA=/var/lib/pgsql/10/data/

#set replication user
replicUser=pgrepuser
replicPassword=pgreppass

#check vip location
viplocation=`ip addr | grep 192.168.59.100 | wc -l`

#check vip status
echo -e "\n"|telnet $slaveip 5432 2> tmpstatus
slavestatus=`grep refused tmpstatus|wc -l`


function removedata() {
    sudo su - postgres -c "cd /var/lib/pgsql/10/data/ &&  rm -rf *"
    if [[ $? != 0 ]] ; then
        echo "`date` remove PGDATA error" >> /etc/keepalived/log/postgresql_keep.log
        exit 1
    fi
}

function backuptomaster() {
    sudo su - postgres -c "PGPASSWORD=$replicPassword /usr/pgsql-10/bin/pg_basebackup -D $PGDATA -Fp -Xs -v -P -h $slaveip -U $replicUser"
    sudo su - postgres -c "sed 's/#hot_standby = on/hot_standby = on/g' -i $PGDATA/postgresql.conf"
    if [[ $? != 0 ]] ; then
        echo "`date` backuptomaster failed" >> /etc/keepalived/log/postgresql_keep.log
        exit 1
    fi

}


function addrecover() {
    sudo su - postgres -c "rm -f /var/lib/pgsql/10/data/recovery.done"
    sudo su - postgres -c "rm -f /var/lib/pgsql/10/data/recovery.conf"
    sudo su - postgres -c "cat << EOF > /var/lib/pgsql/10/data/recovery.conf
    standby_mode = 'on'
    primary_conninfo = 'host=$slaveip port=5432 user=$replicUser password=$replicPassword'
    trigger_file = 'failover.now'
    recovery_target_timeline = 'latest'
EOF"
    if [[ $? != 0 ]] ; then
        echo "`date` addrecover configfile failed" >> /etc/keepalived/log/postgresql_keep.log
        exit 1
    fi
}

function upgrademaster() {
   sudo su - postgres -c "/usr/pgsql-10/bin/pg_ctl promote -D $PGDATA"
   if [[ $? != 0 ]] ; then
        echo "`date` upgrademaster failed" >> /etc/keepalived/log/postgresql_keep.log
        exit 1
    fi


}

#check psql status
pgsqlstatus=`sudo systemctl status postgresql-10|grep Active|awk -F ":" '{print $2}'| awk -F "[()]" '{print $2}'`
if [[ $pgsqlstatus != "running" && $slavestatus == 0 ]] ; then

    removedata
    backuptomaster
    addrecover
    sudo systemctl start postgresql-10

    echo "`date` change mode to slave" >> /etc/keepalived/log/postgresql_keep.log
    exit 1
elif [[ $pgsqlstatus == "running" && $slavestatus == 1 ]] ; then
      status=`sudo su - postgres -c "psql -At -c 'select  pg_is_in_recovery();' "`
      if [ $status == "t" ] ; then
        upgrademaster
        echo "`date` change mode to master" >> /etc/keepalived/log/postgresql_keep.log
      fi
elif [[ $pgsqlstatus != "running" && $slavestatus == 1 ]]; then
    if [ $viplocation == 1 ] ; then
        sudo systemctl start postgresql-10
        status=`sudo su - postgres -c "psql -At -c 'select  pg_is_in_recovery();' "`
        if [ $status == "t" ] ; then
            upgrademaster
            echo "`date` change mode to master" >> /etc/keepalived/log/postgresql_keep.log
        fi
    else


         sudo systemctl start postgresql-10

    fi
    exit 1
elif [[ $pgsqlstatus == "running" && $slavestatus == 0 ]]; then
    if [ $viplocation == 1 ] ; then
        status=`sudo su - postgres -c "psql -At -c 'select  pg_is_in_recovery();' "`
        if [ $status == "t" ] ; then
            upgrademaster
            echo "`date` change mode to master" >> /etc/keepalived/log/postgresql_keep.log
        fi
    else
        status=`sudo su - postgres -c "psql -At -c 'select  pg_is_in_recovery();' "`
        if [ $status == "f" ] ; then
            removedata
            backuptomaster
            addrecover
            sudo systemctl start postgresql-10
            echo "`date` change mode to slave" >> /etc/keepalived/log/postgresql_keep.log
        fi
    fi

else
    echo "`date` nothing to do" >> /etc/keepalived/log/postgresql_keep.log

fi

exit 0
