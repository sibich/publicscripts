#!/bin/bash
#Initial master configuration: network configuration, dhcp server, iptables
#modified 30.04
user=$(whoami)
folder=$(pwd)
date=$(date +%d-%m-%Y" "%H:%M:%S)
echo "Script started: $date" > /home/vitaly/router_setup.log
echo "Current user is $user, working in $folder folder" >> /home/vitaly/router_setup.log
#prerequisites
apt-get update
apt-get upgrade -y
apt-get install -y curl sudo hyperv-daemons

curlver=$(curl --version)
echo "Curl version is $curlver" >> /home/vitaly/router_setup.log
sudover=$(sudo --version)
echo "Sudo version is $sudover" >> /home/vitaly/router_setup.log

#add eth1 parameters to interfaces config
bash -c 'cat << EOF >> /etc/network/interfaces
#The internal network interface (lan)
allow-hotplug eth1
iface eth1 inet static
        address 172.16.2.1
        mask 255.255.255.0
        network 172.16.2.0
        broadcast 172.16.2.255
        gateway 172.16.2.1
EOF'

#add me as sudo user and sudo comands without password
usermod -aG sudo vitaly
echo '%sudo   ALL=(ALL:ALL) NOPASSWD:ALL' | EDITOR='tee -a' visudo

#install dhcp-server:
apt-get install -y isc-dhcp-server

#configure dhcp server
sed -i -e 's/INTERFACESv4=""/INTERFACESv4="eth1"/g' /etc/default/isc-dhcp-server
sed -i -e 's/INTERFACESv6=""/#####/g' /etc/default/isc-dhcp-server

sed -i -e 's/option domain-name "example.org";/option domain-name "cluster.home";/g' /etc/dhcp/dhcpd.conf
sed -i -e 's/option domain-name-servers ns1.example.org, ns2.example.org;/option domain-name-servers 193.41.60.1, 193.41.60.2;/g' /etc/dhcp/dhcpd.conf
sed -i -e 's/default-lease-time 600;/default-lease-time 3600;/g' /etc/dhcp/dhcpd.conf
sed -i -e 's/#authoritative;/authoritative;/g' /etc/dhcp/dhcpd.conf
sed -i -e 's/#log-facility local7;/log-facility local7;/g' /etc/dhcp/dhcpd.conf

bash -c 'cat << EOF >> /etc/dhcp/dhcpd.conf
subnet 172.16.2.0 netmask 255.255.255.0 {
	range 172.16.2.20 172.16.2.30;
	option domain-name "cluster.home";
	option domain-name-servers 193.41.60.1, 193.41.60.2, 8.8.8.8;
	option routers 172.16.2.1;
	option broadcast-address 172.16.2.255;
	default-lease-time 3600;
	max-lease-time 7200;
}
EOF'

#enable forwarding
sed -i -e 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf

#configure iptables
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o eth1 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT

# set iptables for Flannel
modprobe br_netfilter
sysctl net.bridge.bridge-nf-call-iptables=1
echo "net.bridge.bridge-nf-call-iptables=1" >> /etc/sysctl.conf
sysctl net.bridge.bridge-nf-call-iptables >> /home/vitaly/router_setup.log

echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections

apt-get -y install iptables-persistent

cat /etc/iptables/rules.v4 >> /home/vitaly/router_setup.log

#configure /etc/hosts
echo "172.16.2.20	node21-vm.cluster.home	node21-vm" >> /etc/hosts
echo "172.16.2.21   node22-vm.cluster.home  node22-vm" >> /etc/hosts
