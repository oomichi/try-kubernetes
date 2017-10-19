#!/bin/bash

WORKING_PATH=`pwd`
LAST_LINE=`tail -n1 ./github_history.txt`
LAST_COMMIT=`echo ${LAST_LINE} | awk -F "/" '{print $NF}'`
GIT_URL=`echo ${LAST_LINE} | sed s@"/commit/${LAST_COMMIT}"@@`
GIT_DIRNAME=`echo ${GIT_URL} | awk -F "/" '{print $NF}'`

SECGROUP="cffa06fb-b436-4fa1-be6c-e9d7ffa4d476"

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
pwd
source adminrc
if [ $? -ne 0 ]; then
	echo "Failed to source adminrc"
	exit 1
fi

NETID=`openstack network show -c id -f value provider`
MASTER=`openstack server create -c id -f value --flavor m1.medium --image Ubuntu-16.04-x86_64 --nic net-id=${NETID} --security-group ${SECGROUP} --key-name mykey master`
if [ $? -ne 0 ]; then
	echo "Failed to create a virtual machine for master"
	exit 1
fi
WORKER01=`openstack server create -c id -f value --flavor m1.medium --image Ubuntu-16.04-x86_64 --nic net-id=${NETID} --security-group ${SECGROUP} --key-name mykey worker01`
if [ $? -ne 0 ]; then
	echo "Failed to create a virtual machine for worker01"
	exit 1
fi
WORKER02=`openstack server create -c id -f value --flavor m1.medium --image Ubuntu-16.04-x86_64 --nic net-id=${NETID} --security-group ${SECGROUP} --key-name mykey worker02`
if [ $? -ne 0 ]; then
	echo "Failed to create a virtual machine for worker02"
	exit 1
fi

sleep 10

# Know ip addresses of virtual machines
IP_MASTER=`openstack server show -c addresses -f value ${MASTER} | sed s/'provider='//`
IP_WORKER01=`openstack server show -c addresses -f value ${WORKER01} | sed s/'provider='//`
IP_WORKER02=`openstack server show -c addresses -f value ${WORKER02} | sed s/'provider='//`

sed -i s/"IP_MASTER"/"${IP_MASTER}"/g ./cluster.yaml
sed -i s/"IP_WORKER01"/"${IP_WORKER01}"/g ./cluster.yaml
sed -i s/"IP_WORKER02"/"${IP_WORKER02}"/g ./cluster.yaml
cat ./cluster.yaml

cp ./cluster.yaml ./${GIT_DIRNAME}/configs/cluster.yaml
cd ./${GIT_DIRNAME}

# It is possible that the latest commit of the target repo is different from LAST_COMMIT
# when poll_github.sh detects multiple differences between the target repo and this test
# kicking repo.
git checkout ${LAST_COMMIT}


# Operate remora!!
pip3 install -r requirements.txt
if [ $? -ne 0 ]; then
	echo "Failed to pip install"
	exit 1
fi

fab cluster render
if [ $? -ne 0 ]; then
	echo "Failed to fab cluster render"
	exit 1
fi

fab cluster install.kubelet
if [ $? -ne 0 ]; then
	echo "Failed to fab cluster install.kubelet"
	exit 1
fi

fab cluster install.etcd
if [ $? -ne 0 ]; then
	echo "Failed to fab cluster install.etcd"
	exit 1
fi

fab cluster install.bootstrap
if [ $? -ne 0 ]; then
	echo "Failed to fab cluster install.bootstrap"
	exit 1
fi

fab cluster install.kubernetes
if [ $? -ne 0 ]; then
	echo "Failed to fab cluster install.kubernetes"
	exit 1
fi

openstack server delete ${MASTER} ${WORKER01} ${WORKER02}
if [ $? -ne 0 ]; then
	echo "Failed to delete virtual machines"
	exit 1
fi

exit 0
