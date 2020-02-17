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

systemctl restart docker
sudo -u vitaly echo "source <(kubectl completion bash)" >> /home/vitaly/.bashrc
# initialize master node (only for master nodes)
sudo -u vitaly mkdir -p /home/vitaly/.kube
kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=172.16.1.1 >> /home/vitaly/kube_setup.log 2>&1
cp -i /etc/kubernetes/admin.conf /home/vitaly/.kube/config
chown vitaly:vitaly /home/vitaly/.kube/config
sudo -u vitaly kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
sleep 30
sudo -u vitaly kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml
sleep 30
sudo -u vitaly kubectl create serviceaccount dashboard-admin-sa
sudo -u vitaly kubectl create clusterrolebinding dashboard-admin-sa --clusterrole=cluster-admin --serviceaccount=default:dashboard-admin-sa