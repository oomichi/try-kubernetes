#!/bin/bash

KUBE_VERSION=${KUBE_VERSION:-"v1.17.5"}

if [ "${IPS_NODES}" = "" ]; then
	echo 'Need to specify IP addresses of target nodes like:'
	echo '$ IPS_NODES="192.168.1.102 192.168.1.135" ./run-kubespray.sh'
	exit 1
fi

declare -a IPS=(${IPS_NODES})

# Enable error handling
set -e

sudo yum -y install git python3-pip

# libselinux-python3 is for getting kubeconfig
sudo yum -y install libselinux-python3

cd ~/
git clone https://github.com/kubernetes-sigs/kubespray
cd kubespray/
git checkout remotes/origin/release-2.13
sudo pip3 install -r requirements.txt
CONFIG_FILE=inventory/sample/hosts.yaml python3 contrib/inventory_builder/inventory.py ${IPS[@]}

sed -i s/"^metrics_server_enabled: false"/"metrics_server_enabled: true"/ inventory/sample/group_vars/k8s-cluster/addons.yml
sed -i s/"^ingress_nginx_enabled: false"/"ingress_nginx_enabled: true"/   inventory/sample/group_vars/k8s-cluster/addons.yml
sed -i s/"^kube_version: v1.17.5"/"kube_version: ${KUBE_VERSION}"/        inventory/sample/group_vars/k8s-cluster/k8s-cluster.yml
sed -i s/"^# kubeconfig_localhost: false"/"kubeconfig_localhost: true"/   inventory/sample/group_vars/k8s-cluster/k8s-cluster.yml
sed -i s/"^kube_network_plugin: calico"/"kube_network_plugin: flannel"/   inventory/sample/group_vars/k8s-cluster/k8s-cluster.yml
sed -i s/"^override_system_hostname: true"/"override_system_hostname: false"/ roles/bootstrap-os/defaults/main.yml

# The following ansible-playbook is failed sometimes due to some different reasons.
# So here retries multiple times
set +e
# TODO: Increase RETRY number after getting basic stability of this script
RETRY=1
for step in `seq 1 ${RETRY}`; do
	ansible-playbook -i inventory/sample/hosts.yaml  --become --become-user=root cluster.yml
	if [ $? -eq 0 ]; then
		break
	fi
	echo "Failed to do the ansible-playbook in step ${step}"
	if [ ${step} -eq ${RETRY} ]; then
		exit 1
	fi
	sleep 5
done

# Enable error handling
set -e

mkdir ~/.kube
cp `find . -name admin.conf` ~/.kube/config

echo "Succeeded to deploy Kubernetes cluster"
