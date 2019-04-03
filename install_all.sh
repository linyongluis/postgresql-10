#!/usr/bin/env bash
./enviroment_set.sh
#keepalive配置文件需要手工copy过去
./install_keepalived.sh
./install_pgsql.sh
./nginx_install.sh
./install_redis.sh



