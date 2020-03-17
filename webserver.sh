#!/bin/bash
#modified 17.03
user=$(whoami)
folder=$(pwd)
date=$(date +%d-%m-%Y" "%H:%M:%S)
echo "Script started: $date" > /home/vitaly/webserver_setup.log
echo "Current user is $user, working in $folder folder" >> /home/vitaly/webserver_setup.log
#prerequisites
apt-get update
apt-get upgrade -y
apt-get install -y curl lsb-release apt-transport-https ca-certificates

curlver=$(curl --version)
echo "Curl version is $curlver" >> /home/vitaly/webserver_setup.log

#install nginx:
apt-get install -y gnupg gnupg1 gnupg2
wget http://nginx.org/keys/nginx_signing.key
apt-key add nginx_signing.key
echo "deb http://nginx.org/packages/debian/ buster nginx" > /etc/apt/sources.list.d/nginx.list
echo "deb-src http://nginx.org/packages/debian/ buster nginx" >> /etc/apt/sources.list.d/nginx.list
apt-get update
apt-get install -y nginx
sed -i -e 's/        keepalive_timeout 65;/        keepalive_timeout 2;/g' /etc/nginx/nginx.conf
systemctl start nginx
