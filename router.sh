#!/bin/bash
#Initial master configuration: dhcp server, iptables

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
iptables -P FORWARD ACCEPT

# set iptables for Flannel
modprobe br_netfilter
sysctl net.bridge.bridge-nf-call-iptables=1

echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections

apt-get -y install iptables-persistent

