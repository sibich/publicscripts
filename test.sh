#!/bin/bash

user=$(whoami)
folder=$(pwd)
echo "Hello $user from ARM in $folder" > /home/vitaly/test_`date +%d-%m-%Y"_"%H_%M_%S`.txt
#prerequisites
apt-get update
apt-get upgrade -y
apt-get install -y apt-transport-https curl ca-certificates gnupg2 software-properties-common

swapoff -a

#install docker
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
sleep 10s
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
apt-get -y update
apt-cache policy docker-ce
apt-get install -y docker-ce docker-ce-cli containerd.io
dockerver=$(docker --version)
echo "Docker version is $dockerver" > /home/vitaly/setup.log

#install k8s
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sleep 10s
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubeadm kubelet
apt-mark hold kubelet kubeadm

kubeadmver=$(kubeadm version)
echo "Kubeadm version is $kubeadmver" >> /home/vitaly/setup.log