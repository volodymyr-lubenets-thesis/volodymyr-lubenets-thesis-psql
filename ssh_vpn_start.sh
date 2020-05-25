#!/bin/bash
source ./authdata/.env

GATE=$(hcloud server list -o columns="name,ipv4" | grep "ansible001" | awk '{print $2}')

ssh \
  -o PermitLocalCommand=yes \
  -o LocalCommand="sudo ifconfig tun5 192.168.244.2 pointopoint 192.168.244.1 netmask 255.255.255.0" \
  -o ServerAliveInterval=60 \
  -i ssh/test_cluster \
  -w 5:5 root@$GATE \
  'sudo ifconfig tun5 192.168.244.1 pointopoint 192.168.244.2 netmask 255.255.255.0; echo tun0 ready'