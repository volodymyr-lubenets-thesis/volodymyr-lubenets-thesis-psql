#!/bin/bash
source ./authdata/.env

GATE=$(hcloud server list -o columns="name,ipv4" | grep "ansible001" | awk '{print $2}')

ip route add 192.168.50.0/24 via 192.168.244.1
ssh root@$GATE -i ssh/test_cluster \
  'sudo iptables -t nat -A POSTROUTING -s 192.168.244.2 -j MASQUERADE'

cat << EOF > /etc/resolv.conf
nameserver 192.168.50.11
nameserver 8.8.8.8
EOF
