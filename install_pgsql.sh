#!/usr/bin/env bash

PGDATA=/var/lib/pgsql/10/data/
masterip=192.168.59.1
replicUser=pgrepuser
replicPassword=pgreppass

function addrecovery() {
    sudo su - postgres -c "cat << EOF > /var/lib/pgsql/10/data/recovery.conf
    standby_mode = 'on'
    primary_conninfo = 'host=$masterip port=5432 user=$replicUser password=$replicPassword'
    trigger_file = 'failover.now'
    recovery_target_timeline = 'latest'
EOF"
    if [[ $? != 0 ]] ; then
        echo "`date` addrecovery failed"
        exit 1
    fi
}

function masterinstall() {
    #install and init , start service
    sudo curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
    sudo yum install -y https://download.postgresql.org/pub/repos/yum/10/redhat/rhel-7-x86_64/pgdg-centos10-10-2.noarch.rpm
    sudo yum install -y postgresql10
    sudo yum install -y postgresql10-server
    sudo /usr/pgsql-10/bin/postgresql-10-setup initdb
    sudo systemctl enable postgresql-10
    sudo systemctl start postgresql-10

    #exec sql file,insert_sql path to /var/lib/pgsql/
    sudo cp insert_sql /var/lib/pgsql/
    sudo su - postgres -c "psql -f insert_sql"
    if [[ $? != 0 ]] ; then
        echo "`date` insert sql failed"
        exit 1
    fi

    #modfiy $PGDATA/postgresql.conf and pg_hba.conf, modfiy_postgresqlconf.sh path to /var/lib/pgsql/
    sudo cp modfiy_postgresqlconf.sh /var/lib/pgsql/
    sudo su - postgres -c "sh modfiy_postgresqlconf.sh"
    if [[ $? != 0 ]] ; then
        echo "`date` master modfiy config failed"
        exit 1
    fi



    #reload config file
    sudo su - postgres -c  "/usr/pgsql-10/bin/pg_ctl reload -D $PGDATA"


    if [[ $? == 0 ]] ; then
        echo "master install successed"
    else
        echo "master install failed"
    fi

}


function slaveinstall() {
    sudo curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
    sudo yum install -y https://download.postgresql.org/pub/repos/yum/10/redhat/rhel-7-x86_64/pgdg-centos10-10-2.noarch.rpm
    sudo yum install -y postgresql10
    sudo yum install -y postgresql10-server
    sudo systemctl enable postgresql-10



    #backup to master
    sudo su - postgres -c "PGPASSWORD=$replicPassword /usr/pgsql-10/bin/pg_basebackup -D $PGDATA -Fp -Xs -v -P -h $masterip -U $replicUser -w"
    if [[ $? != 0 ]] ; then
        echo "`date` backuptomaster failed"
        exit 1
    fi



    #modfiy $PGDATA/postgresql.conf
    sudo su - postgres -c "sed 's/#hot_standby = on/hot_standby = on/g' -i $PGDATA/postgresql.conf"
    if [[ $? != 0 ]] ; then
        echo "`date` modfiy postgresql.conf failed"
        exit 1
    fi

    #add recovery.conf
    addrecovery

    #start postgresql
    sudo systemctl start postgresql-10

    if [[ $? == 0 ]] ; then
        echo "slave install successed"
    else
        echo "slave install failed"
    fi


}

function usage() {
    echo "Usage: please input masterinstall or slaveinstall"
}


case $1 in
    masterinstall)
        masterinstall
        ;;
    slaveinstall)
        slaveinstall
        ;;
    *)

        usage
        ;;
esac
