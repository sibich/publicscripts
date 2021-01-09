#!/bin/bash

user=$(whoami)
folder=$(pwd)
date=$(date +%d-%m-%Y" "%H:%M:%S)
echo "Script started: $date" > /home/vitaly/setup.log
echo "Current user is $user, working in $folder folder" >> /home/vitaly/setup.log
#prerequisites
apt-get update
apt-get upgrade -y
apt-get install -y apt-transport-https curl ca-certificates gnupg2 software-properties-common hyperv-daemons

#disabling swap
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

#enable forwarding
sed -i -e 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf

#enable forwarding
iptables -P FORWARD ACCEPT
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
apt-get -y install iptables-persistent

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
apt-get install -y kubeadm=1.18.2-00 kubelet=1.18.2-00 kubectl=1.18.2-00 kubernetes-cni
apt-mark hold kubelet kubeadm kubectl

kubeadmver=$(kubeadm version)
echo "Kubeadm version is $kubeadmver" >> /home/vitaly/setup.log

bash -c 'cat << EOF > /etc/docker/daemon.json
{
   "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF'

systemctl restart docker

#enable kubectl completion
sudo -u vitaly echo "source <(kubectl completion bash)" >> /home/vitaly/.bashrc
# add node to master (only for slave nodes)
 >> /home/vitaly/setup.log