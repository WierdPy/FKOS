#!/bin/bash

sudo hostnamectl set-hostname LinOezbekC1

cat <<EOF | sudo tee /etc/netplan/00-installer-config.yaml > /dev/null
network:
  ethernets:
    dmz:
      dhcp4: true
      match:
        macaddress: $1
      set-name: dmz
    outside:
      dhcp4: true
      match:
        macaddress: $2
      set-name: outside
  version: 2
EOF

sudo netplan apply

echo "Konfiguration abgeschlossen."
