#!/bin/bash

K8S_VERSION=${K8S_VERSION:-"v1.17.5"}

if [ "${K8S_NODES}" = "" ]; then
	echo 'Need to specify IP addresses of target nodes like:'
	echo '$ K8S_NODES="192.168.1.102 192.168.1.135" ./run-kubespray.sh'
	exit 1
fi

declare -a IPS=(${K8S_NODES})

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

# Replace node1, node2, ... with actual hostnames for avoiding overwriting the result of "kubectl get nodes"
INDEX_NODE=1
for node in ${K8S_NODES}; do
	nodename=`ssh -oStrictHostKeyChecking=no ${node} 'echo ${HOSTNAME}' | awk -F. '{print $1}'`
	sed -i s/"node${INDEX_NODE}"/"${nodename}"/g inventory/sample/hosts.yaml
	INDEX_NODE=`expr ${INDEX_NODE} + 1`
done

sed -i s/"^metrics_server_enabled: false"/"metrics_server_enabled: true"/ inventory/sample/group_vars/k8s-cluster/addons.yml
sed -i s/"^ingress_nginx_enabled: false"/"ingress_nginx_enabled: true"/   inventory/sample/group_vars/k8s-cluster/addons.yml
sed -i s/"^kube_version: v1.17.5"/"kube_version: ${K8S_VERSION}"/         inventory/sample/group_vars/k8s-cluster/k8s-cluster.yml
sed -i s/"^# kubeconfig_localhost: false"/"kubeconfig_localhost: true"/   inventory/sample/group_vars/k8s-cluster/k8s-cluster.yml
sed -i s/"^kube_network_plugin: calico"/"kube_network_plugin: flannel"/   inventory/sample/group_vars/k8s-cluster/k8s-cluster.yml
sed -i s/"^override_system_hostname: true"/"override_system_hostname: false"/ roles/bootstrap-os/defaults/main.yml

if [ "${CEPH_MON_NODES}" != "" ]; then
	MONITORS=""
	for node in ${CEPH_MON_NODES}; do
		MONITORS="${MONITORS} ${node}:6789"
	done
	sed -i s/"^cephfs_provisioner_enabled: false"/"cephfs_provisioner_enabled: true"/ inventory/sample/group_vars/k8s-cluster/addons.yml
	sed -i s/'^# cephfs_provisioner_monitors: "172.24.0.1:6789,172.24.0.2:6789,172.24.0.3:6789"'/"cephfs_provisioner_monitors: \"${MONITORS}\""/ inventory/sample/group_vars/k8s-cluster/addons.yml
fi

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
cp ./inventory/sample/artifacts/admin.conf ~/.kube/config

echo "Succeeded to deploy Kubernetes cluster"
