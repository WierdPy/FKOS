#!/bin/bash

sudo hostnamectl set-hostname LinOezbekS2

sudo cat <<EOT > /etc/netplan/00-installer-config.yaml
network:
  ethernets:
    lan:
      addresses:
        - 10.0.0.254/24
      match:
        macaddress: $2
      set-name: lan
    dmz:
      addresses:
        - 192.168.30.254/24
      match:
        macaddress: $1
      set-name: dmz
    outside:
      dhcp4: true
      match:
        macaddress: $3
      set-name: outside
  version: 2
EOT

sudo netplan apply
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv6.conf.all.forwarding=1
sudo sysctl -p

IPT="/sbin/iptables"

# Flush und Löschen der Custom-Chains
$IPT -F
$IPT -X

# Policy setzen
$IPT -P INPUT ACCEPT
$IPT -P OUTPUT ACCEPT
$IPT -P FORWARD DROP

# Eigene Chains anlegen
$IPT -N lan_dmz
$IPT -N lan_ext
$IPT -N dmz_ext

# LAN <-> DMZ
$IPT -A FORWARD -i lan -o dmz -j lan_dmz
$IPT -A FORWARD -i dmz -o lan -j lan_dmz

$IPT -A lan_dmz -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
$IPT -A lan_dmz -p icmp -j ACCEPT
$IPT -A lan_dmz -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
$IPT -A lan_dmz -p icmp -j ACCEPT
$IPT -A lan_dmz -p udp -m multiport --dports 53 -j ACCEPT  # DNS
$IPT -A lan_dmz -p tcp -m multiport --dports 53 -j ACCEPT  # DNS
$IPT -A lan_dmz -j REJECT


# LAN <-> INTERNET
$IPT -A FORWARD -i lan -o outside -j lan_ext
$IPT -A FORWARD -i outside -o lan -j lan_ext

$IPT -A lan_ext -j ACCEPT

# DMZ <-> INTERNET
$IPT -A FORWARD -i dmz -o outside -j dmz_ext
$IPT -A FORWARD -i outside -o dmz -j dmz_ext

$IPT -A dmz_ext -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
$IPT -A dmz_ext -p udp -m multiport --dports 123,2049,2050,88,749,53 -j ACCEPT  # NTP, NFS, Kerberos, DNS
$IPT -A dmz_ext -p tcp -m multiport --dports 22,80,3000,9090,9100,88,749,2049,2050,53 -j ACCEPT  # SSH, HTTP, NFS, Kerberos, DNS
$IPT -A dmz_ext -p icmp -j ACCEPT
$IPT -A dmz_ext -j REJECT

# MASQUERADING
$IPT -t nat -A POSTROUTING -o outside -j MASQUERADE

echo "Konfiguration abgeschlossen."
