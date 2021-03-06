#!/bin/bash

TEMPFILE=$1
LAST_LINE=`tail -n1 ./github_history.txt`
LAST_COMMIT=`echo ${LAST_LINE} | awk -F "/" '{print $NF}'`
GIT_URL=`echo ${LAST_LINE} | sed s@"/commit/${LAST_COMMIT}"@@`
GIT_DIRNAME=`echo ${GIT_URL} | awk -F "/" '{print $NF}'`

# The security group needs to allow ssh(22) and k8s port(remora sets 6443 as it)
SECGROUP="cffa06fb-b436-4fa1-be6c-e9d7ffa4d476"
KEYNAME="gitlab-runner-key"

echo "LAST_COMMIT: $LAST_COMMIT"
echo "GIT_URL: $GIT_URL"
echo "GIT_DIRNAME: $GIT_DIRNAME"

if [ -z ${LAST_COMMIT} ]; then
	echo "Failed to get LAST_COMMIT, github_history.txt could be invalid."
	exit 1
fi
if [ -z ${GIT_URL} ]; then
	echo "Failed to get GIT_URL, github_history.txt could be invalid."
	exit 1
fi
if [ -z ${GIT_DIRNAME} ]; then
	echo "Failed to get GIT_DIRNAME, github_history.txt could be invalid."
	exit 1
fi

# Clone remora git ASAP because the following operation takes much time and need to avoid conflict another commits
git clone ${GIT_URL}

# Create virtual machines with OpenStack
echo "Start to create virtual machines.."

source adminrc
if [ $? -ne 0 ]; then
	echo "Failed to source adminrc"
	exit 1
fi

NETID=`openstack network show -c id -f value provider`
MASTER=`openstack server create -c id -f value --flavor m1.medium --image Ubuntu-16.04-x86_64 --nic net-id=${NETID} --security-group ${SECGROUP} --key-name ${KEYNAME} master`
if [ $? -ne 0 ]; then
	echo "Failed to create a virtual machine for master"
	exit 1
fi
WORKER01=`openstack server create -c id -f value --flavor m1.medium --image Ubuntu-16.04-x86_64 --nic net-id=${NETID} --security-group ${SECGROUP} --key-name ${KEYNAME} worker01`
if [ $? -ne 0 ]; then
	echo "Failed to create a virtual machine for worker01"
	exit 1
fi
WORKER02=`openstack server create -c id -f value --flavor m1.medium --image Ubuntu-16.04-x86_64 --nic net-id=${NETID} --security-group ${SECGROUP} --key-name ${KEYNAME} worker02`
if [ $? -ne 0 ]; then
	echo "Failed to create a virtual machine for worker02"
	exit 1
fi

echo "Succeeded to create virtual machines."

# This is for cleaning virtual machines up later. True this is hacky..
echo "${MASTER} ${WORKER01} ${WORKER02}" > ${TEMPFILE}

echo "Waiting for virtual machines are up."

function wait_for_vm_up () {
	VM=$1
	while [ `nova console-log ${VM} | grep "login:" | wc -l` = "0" ]
	do
		sleep 1
	done
	echo "The virtual machine ${VM} is up."
}

wait_for_vm_up ${MASTER}
wait_for_vm_up ${WORKER01}
wait_for_vm_up ${WORKER02}

# Know ip addresses of virtual machines
IP_MASTER=`openstack server show -c addresses -f value ${MASTER} | sed s/'provider='//`
IP_WORKER01=`openstack server show -c addresses -f value ${WORKER01} | sed s/'provider='//`
IP_WORKER02=`openstack server show -c addresses -f value ${WORKER02} | sed s/'provider='//`

ssh-keygen -f "/home/gitlab-runner/.ssh/known_hosts" -R ${IP_MASTER}
ssh-keygen -f "/home/gitlab-runner/.ssh/known_hosts" -R ${IP_WORKER01}
ssh-keygen -f "/home/gitlab-runner/.ssh/known_hosts" -R ${IP_WORKER02}

echo "StrictHostKeyChecking no" > ~/.ssh/config
chmod 600 ~/.ssh/config

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

wait_for_vm_ssh ${IP_MASTER}
wait_for_vm_ssh ${IP_WORKER01}
wait_for_vm_ssh ${IP_WORKER02}

cp -f ./cluster.yaml ./${GIT_DIRNAME}/configs/cluster.yaml
sed -i s/"IP_MASTER"/"${IP_MASTER}"/g     ./${GIT_DIRNAME}/configs/cluster.yaml
sed -i s/"IP_WORKER01"/"${IP_WORKER01}"/g ./${GIT_DIRNAME}/configs/cluster.yaml
sed -i s/"IP_WORKER02"/"${IP_WORKER02}"/g ./${GIT_DIRNAME}/configs/cluster.yaml
cat ./${GIT_DIRNAME}/configs/cluster.yaml

echo "Installing packages on virtual machines.."
cp -f ./hosts_vms.org ./hosts_vms
sed -i s/"IP_MASTER"/"${IP_MASTER}"/g     ./hosts_vms
sed -i s/"IP_WORKER01"/"${IP_WORKER01}"/g ./hosts_vms
sed -i s/"IP_WORKER02"/"${IP_WORKER02}"/g ./hosts_vms
ansible-playbook -vvvv -i ./hosts_vms install_docker.yaml
if [ $? -ne 0 ]; then
	openstack server delete ${MASTER} ${WORKER01} ${WORKER02}
	echo "Failed to install packages."
	exit 1
fi
echo "Succeeded to install packages."

exit 0
