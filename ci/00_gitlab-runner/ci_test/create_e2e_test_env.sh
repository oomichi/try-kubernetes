#!/bin/bash

cd dirname $0

SECGROUP="cffa06fb-b436-4fa1-be6c-e9d7ffa4d476"
KEYNAME="gitlab-runner-key"

# Create virtual machines with OpenStack
echo "Start to create virtual machines.."

source adminrc
if [ $? -ne 0 ]; then
	echo "Failed to source adminrc"
	exit 1
fi

NETID=`openstack network show -c id -f value provider`
E2E=`openstack server create -c id -f value --flavor m1.medium --image Ubuntu-16.04-x86_64 --nic net-id=${NETID} --security-group ${SECGROUP} --key-name ${KEYNAME} e2e`
if [ $? -ne 0 ]; then
	echo "Failed to create a virtual machine for e2e"
	exit 1
fi

function wait_for_vm_up () {
	VM=$1
	while [ `nova console-log ${VM} | grep "login:" | wc -l` = "0" ]
	do
		sleep 1
	done
	echo "The virtual machine ${VM} is up."
}
echo "Waiting for virtual machine up.."
wait_for_vm_up ${E2E}

# Know ip addresse of virtual machine
IP_E2E=`openstack server show -c addresses -f value ${E2E} | sed s/'provider='//`
ssh-keygen -f "/home/gitlab-runner/.ssh/known_hosts" -R ${IP_E2E}

function wait_for_vm_ssh () {
	IP_VM=$1
	rm -f empty.txt
	touch empty.txt
	while [ `scp empty.txt ubuntu@${IP_VM}:empty.txt > /dev/null; echo $?` != "0" ]
	do
		sleep 1
	done
	echo "The virtual machine ${IP_VM}'s ssh is enabled."
}
echo "Waiting for virtual machine ssh up.."
wait_for_vm_ssh ${IP_E2E}

cp -f ./hosts_e2e.org ./hosts_e2e
sed -i s/"IP_E2E"/"${IP_E2E}"/g  ./hosts_e2e
ansible-playbook -vvvv -i ./hosts_e2e create_e2e_test_env.yaml
if [ $? -ne 0 ]; then
	echo "Failed to create e2e test env."
	exit 1
fi

exit 0
