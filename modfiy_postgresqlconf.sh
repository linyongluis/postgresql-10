#!/usr/bin/env bash
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" $PGDATA/postgresql.conf
sed -i "s/max_connections = 100/max_connections = 1000/g" $PGDATA/postgresql.conf
sed -i "s/#password_encryption/password_encryption/g" $PGDATA/postgresql.conf
sed -i "s/#wal_level = replica/wal_level = hot_standby/g" $PGDATA/postgresql.conf
sed -i "s/#archive_mode = off/archive_mode = on/g" $PGDATA/postgresql.conf
sed -i "s/#max_wal_senders/max_wal_senders/g" $PGDATA/postgresql.conf
sed -i "s/#wal_keep_segments = 0/wal_keep_segments = 10/g" $PGDATA/postgresql.conf
sed -i "s/#hot_standby = on/hot_standby = on/g" $PGDATA/postgresql.conf

echo "host replication pgrepuser 0.0.0.0/0 md5" >>  $PGDATA/pg_hba.conf
sed -i "s/host    all             all             127\.0\.0\.1\/32            ident/host    all             all             0\.0\.0\.0\/0            md5/g" $PGDATA/pg_hba.conf
