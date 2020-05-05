#!/bin/bash

user=$(whoami)
folder=$(pwd)
date=$(date +%d-%m-%Y" "%H:%M:%S)
echo "Script started: $date" > /home/vitaly/kube_setup.log
echo "Current user is $user, working in $folder folder" >> /home/vitaly/kube_setup.log
#prerequisites
apt-get update
apt-get upgrade -y
apt-get install -y apt-transport-https curl ca-certificates gnupg2 software-properties-common

#disabling swap
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

#enable bridge-netfilter
modprobe br_netfilter

#install docker
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
sleep 10s
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
apt-get -y update
apt-cache policy docker-ce
apt-get install -y docker-ce docker-ce-cli containerd.io
dockerver=$(docker --version)
echo "Docker version is $dockerver" >> /home/vitaly/kube_setup.log

#install k8s
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sleep 10s
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubeadm kubelet kubectl kubernetes-cni
apt-mark hold kubelet kubeadm kubectl

kubeadmver=$(kubeadm version)
echo "Kubeadm version is $kubeadmver" >> /home/vitaly/kube_setup.log

bash -c 'cat << EOF > /etc/docker/daemon.json
{
   "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF'

#some variables
POD_NETWORK_CIDR="10.244.0.0/16"
APISERVER_ADVERTISE_ADDRESS="172.16.1.1"
SERVICE_CIDR="10.96.0.0/12"

systemctl restart docker
sudo -u vitaly echo "source <(kubectl completion bash)" >> /home/vitaly/.bashrc
# initialize master node (only for master nodes)
sudo -u vitaly mkdir -p /home/vitaly/.kube
kubeadm init --pod-network-cidr=$POD_NETWORK_CIDR --apiserver-advertise-address=$APISERVER_ADVERTISE_ADDRESS --service-cidr=$SERVICE_CIDR >> /home/vitaly/kube_setup.log 2>&1
cp -i /etc/kubernetes/admin.conf /home/vitaly/.kube/config
chown vitaly:vitaly /home/vitaly/.kube/config

#setup flannel modified for windows nodes
wget https://raw.githubusercontent.com/sibich/publicscripts/master/kube-flannel.yml
sudo -u vitaly kubectl apply -f kube-flannel.yml
sleep 60
sudo -u vitaly curl -L https://github.com/kubernetes-sigs/sig-windows-tools/releases/latest/download/kube-proxy.yml | sed 's/VERSION/v1.18.0/g' | sudo -u vitaly kubectl apply -f -
sleep 40
sudo -u vitaly kubectl apply -f https://github.com/kubernetes-sigs/sig-windows-tools/releases/latest/download/flannel-overlay.yml
sleep 40

#patching
wget https://raw.githubusercontent.com/sibich/publicscripts/master/node-selector-patch.yml
wget https://raw.githubusercontent.com/sibich/publicscripts/master/win-node-selector-patch.yml
sudo -u vitaly kubectl patch ds/kube-proxy --patch "$(cat node-selector-patch.yml)" -n=kube-system
sleep 10
sudo -u vitaly kubectl patch ds/kube-flannel-ds-amd64 --patch "$(cat node-selector-patch.yml)" -n=kube-system
sleep 10
sudo -u vitaly kubectl patch ds/kube-flannel-ds-windows-amd64 --patch "$(cat win-node-selector-patch.yml)" -n=kube-system
sleep 10

sudo -u vitaly kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml
sleep 30
sudo -u vitaly kubectl create serviceaccount dashboard-admin-sa
sudo -u vitaly kubectl create clusterrolebinding dashboard-admin-sa --clusterrole=cluster-admin --serviceaccount=default:dashboard-admin-sa