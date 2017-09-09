#!/bin/sh

IPADDRESS=$1

if [ -z "${IPADDRESS}" ]; then
	echo "Need to specify IP address of the internal network"
	exit 1
fi
if [ ${USER} != "root" ]; then
	echo "Need to run this script by root user"
	exit 1
fi

echo ""                         >> /etc/network/interfaces
echo "auto enp0s8"              >> /etc/network/interfaces
echo "iface enp0s8 inet static" >> /etc/network/interfaces
echo "address ${IPADDRESS}"     >> /etc/network/interfaces
echo "netmask 255.255.255.0"    >> /etc/network/interfaces

sync
reboot

