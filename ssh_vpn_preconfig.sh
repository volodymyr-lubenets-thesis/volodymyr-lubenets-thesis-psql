#!/bin/bash
source ./authdata/.env

GATE=$(hcloud server list -o columns="name,ipv4" | grep "ansible001" | awk '{print $2}')

ssh root@$GATE -i ssh/test_cluster 'echo PermitTunnel point-to-point >> /etc/ssh/sshd_config && systemctl restart sshd && sysctl -w net.ipv4.ip_forward=1'
