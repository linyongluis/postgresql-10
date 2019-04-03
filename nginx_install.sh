#!/usr/bin/env bash

sudo cat << EOF > /etc/yum.repos.d/nginx.repo
[nginx]
name=nginx repo
baseurl=https://nginx.org/packages/centos/7/$basearch/
gpgcheck=0
enabled=1
EOF

sudo yum install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx