#!/usr/bin/env bash
sudo systemctl stop firewalld
sudo sed -i "s#SELINUX=enforcing#SELINUX=disabled#g" /etc/selinux/config
sudo setenforce 0