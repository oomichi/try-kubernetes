#!/bin/bash

CURRENT_DIR=$(
    cd $(dirname $0) 
    pwd
)

if [ "${K8S_NODES}" = "" ]; then
    echo 'Need to specify IP addresses of target nodes like:'
    echo '$ export K8S_NODES="192.168.1.100"'
    echo '$ ./destroy-k8s-cluster.sh'
    exit 1
fi

OS_NAME=$(grep PRETTY_NAME /etc/os-release)
if [ "$(echo ${OS_NAME} | grep 'Ubuntu')" ]; then
    sudo apt update
    sudo apt install -y python3-pip python3-selinux
else
    # for Red Hat/CentOS
    sudo yum -y install git python3-pip httpd-tools libselinux-python3
fi

cd ~
set -e
if [ ! -d ./kubespray ]; then
	git clone https://github.com/kubernetes-sigs/kubespray
fi
cd kubespray/
sudo pip3 install -r requirements.txt

echo "Creating an inventory file.."
declare -a IPS=(${K8S_NODES})
USE_REAL_HOSTNAME=True CONFIG_FILE=inventory/sample/hosts.yaml python3 contrib/inventory_builder/inventory.py ${IPS[@]}
ansible-playbook -e reset_confirmation=yes -i inventory/sample/hosts.yaml --become --become-user=root -b -v reset.yml
