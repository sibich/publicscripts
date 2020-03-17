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
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
echo "deb http://nginx.org/packages/debian/ buster nginx" > /etc/apt/sources.list.d/nginx.list
echo "deb-src http://nginx.org/packages/debian/ buster nginx" >> /etc/apt/sources.list.d/nginx.list
apt-get update
apt-get install -y nginx
apt-get install -y php7.2 php-pear php7.2-pgsql php7.2-gd php7.2-fpm php7.2-cli php7.2-dom php7.2-xml

#install php7
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list

systemctl start nginx
