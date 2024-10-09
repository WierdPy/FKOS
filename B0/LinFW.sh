sed -i '/ip_forward/s/#//g' /etc/sysctl.conf
sysctl -p

# Firewall
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
$IPT -N ext

# LAN <-> DMZ
$IPT -A FORWARD -i LAN -o DMZ -j lan_dmz
$IPT -A FORWARD -i DMZ -o LAN -j lan_dmz

$IPT -A lan_dmz -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# ICMP
$IPT -A lan_dmz -p icmp -j ACCEPT

# DNS
$IPT -A lan_dmz -p tcp --dport domain -j ACCEPT
$IPT -A lan_dmz -p udp --dport domain -j ACCEPT

# HTTP
$IPT -A lan_dmz -p tcp --dport http -j ACCEPT
$IPT -A lan_dmz -p udp --dport http -j ACCEPT

# NTP
$IPT -A lan_dmz -p tcp --dport 123 -j ACCEPT
$IPT -A lan_dmz -p udp --dport 123 -j ACCEPT

# SSH
$IPT -A lan_dmz -p tcp --dport ssh -j ACCEPT

# catch
$IPT -A lan_dmz -j REJECT

# LAN/DMZ <-> INTERNET
$IPT -A FORWARD -i LAN -o OUT -j ext
$IPT -A FORWARD -i OUT -o LAN -j ext
$IPT -A FORWARD -i DMZ -o OUT -j ext
$IPT -A FORWARD -i OUT -o DMZ -j ext

$IPT -A ext -j ACCEPT


# MASQUERADING
$IPT -t nat -A POSTROUTING -o OUT -j MASQUERADE

iptables-save -f /etc/iptables/rules.v4
