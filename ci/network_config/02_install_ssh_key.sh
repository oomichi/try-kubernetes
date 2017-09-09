#!/bin/sh

IPADDRESS=$1
if [ -z "${IPADDRESS}" ]; then
	echo "Need to specify IP address of the target machine"
	exit 1
fi

ssh-keygen -f "${HOME}/.ssh/known_hosts" -R ${IPADDRESS}
ssh-copy-id -f ubuntu@${IPADDRESS}

