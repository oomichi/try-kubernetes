#!/bin/sh

shell: MY_IP=`ifconfig | grep "inet addr:192.168" | awk '{print $2}' | awk -F: '{print $2}'`
sed -i s/"my_ip = 192.168.1.100"/"my_ip = ${MY_IP}"/ /etc/nova/nova.conf
