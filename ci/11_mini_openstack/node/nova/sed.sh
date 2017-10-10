#!/bin/sh

MY_IP=`ifconfig | grep "inet addr:192.168.1." | awk '{print $2}' | awk -F: '{print $2}'`
sed -i s/"my_ip ="/"my_ip = ${MY_IP}"/ /etc/nova/nova.conf
