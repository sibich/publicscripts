#!/bin/bash

user=$(whoami)
folder=$(pwd)
date=$(date +%d-%m-%Y" "%H:%M:%S)
echo "Script started: $date" > /home/vitaly/setup.log
echo "Current user is $user, working in $folder folder" >> /home/vitaly/setup.log
#prerequisites
apt-get update
apt-get upgrade -y
apt-get install -y apt-transport-https curl ca-certificates gnupg2 software-properties-common

#disabling swap
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

#install docker
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
sleep 10s
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
apt-get -y update
apt-cache policy docker-ce
apt-get install -y docker-ce docker-ce-cli containerd.io
dockerver=$(docker --version)
echo "Docker version is $dockerver" >> /home/vitaly/setup.log

#install k8s
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sleep 10s
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubeadm kubelet kubectl kubernetes-cni
apt-mark hold kubelet kubeadm kubectl

kubeadmver=$(kubeadm version)
echo "Kubeadm version is $kubeadmver" >> /home/vitaly/setup.log

bash -c 'cat << EOF > /etc/docker/daemon.json
{
   "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF'

systemctl restart docker

sudo -u vitaly mkdir -p /home/vitaly/.kube
sudo -u vitaly echo "source <(kubectl completion bash)" >> /home/vitaly/.bashrc