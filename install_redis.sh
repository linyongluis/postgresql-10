#!/usr/bin/env bash
install_dir=/phd

sudo mkdir $install_dir
sudo yum install gcc -y
sudo yum install wget -y
sudo yum install tcl -y
cd /$install_dir
sudo wget http://download.redis.io/releases/redis-5.0.4.tar.gz
sudo tar zxf redis-5.0.4.tar.gz
cd redis-5.0.4/
sudo make MALLOC=libc && sudo make test
sudo mkdir conf bin pid dump aof logs
sudo mv redis.conf conf/ && sudo mv sentinel.conf conf/
sudo mv src/redis-s* bin/ && sudo mv src/redis-cli  bin/
cd conf/
sudo sed -i "s#timeout 0#timeout 30#g" redis.conf
sudo sed -i "s#daemonize no#daemonize yes#g" redis.conf
sudo sed -i "s#pidfile \/var\/run\/redis_6379\.pid#pidfile $install_dir\/redis\/pid\/redis_6379\.pid#g" redis.conf
sudo sed -i "s#logfile \"\"#logfile \"$install_dir\/redis\/logs/redis_6379.log\"#g" redis.conf
sudo sed -i "s#save 900 1#save \"\"#g" redis.conf
sudo sed -i "s#dir \.\/#dir \/$install_dir\/redis\/dump\/#g" redis.conf
sudo sed -i "s#appendonly no#appendonly yes#g" redis.conf
sudo ln -s /$install_dir/redis-5.0.4 /$install_dir/redis
sudo ../bin/redis-server redis.conf