#!/bin/bash

CURRENT_DIR=$(cd $(dirname $0); pwd)
OPTION=$1

KUBESPRAY_VERSION=${KUBESPRAY_VERSION:-"v2.16.0"}
K8S_VERSION=${K8S_VERSION:-""}

KUBESPRAY_DOWNLOADED_FILE="kubespray-${KUBESPRAY_VERSION}.tar.gz"
PIP_REQIUREMENT_DIR="pip3-downloaded"

IS_UBUNTU=$(grep '^NAME="Ubuntu"' /etc/os-release)

if [ "${OPTION}" == "create-downloaded-files" ]; then
	cd ${CURRENT_DIR}
	if [ ! -d kubespray/ ]; then
		set -e
		git clone https://github.com/kubernetes-sigs/kubespray
		set +e
	fi
	cd kubespray/

	if [ "${KUBESPRAY_VERSION}" != "" ]; then
		set -e
		git checkout ${KUBESPRAY_VERSION}
	fi

	set -e
	mkdir ${PIP_REQIUREMENT_DIR}
	cd ${PIP_REQIUREMENT_DIR}
	pip3 download -r ../requirements.txt
	cd ${CURRENT_DIR}
	tar -zcvf ${CURRENT_DIR}/${KUBESPRAY_DOWNLOADED_FILE} kubespray/

	echo "${KUBESPRAY_DOWNLOADED_FILE} is created, please keep this file as the same as this script directory."
	exit 0
fi

if [ "${K8S_NODES}" = "" ]; then
	echo 'Need to specify IP addresses of target nodes like:'
	echo '$ K8S_NODES="192.168.1.102 192.168.1.135" ./run-kubespray.sh'
	exit 1
fi

declare -a IPS=(${K8S_NODES})

SINGLE_K8S=""
if [ ${#IPS[*]} -eq 1 ]; then
	SINGLE_K8S="True"
fi

if [ -n "${IS_UBUNTU}" ]; then
	set -e
	sudo apt -y install python3-pip
	set +e
else
	# Enable error handling
	set -e
	sudo yum -y install git python3-pip
	# libselinux-python3 is for getting kubeconfig
	sudo yum -y install libselinux-python3
	set +e
fi

cd ~/
if [ -f ${CURRENT_DIR}/${KUBESPRAY_DOWNLOADED_FILE} ]; then
	set -e
	tar -zxvf ${CURRENT_DIR}/${KUBESPRAY_DOWNLOADED_FILE}
	cd kubespray/
	sudo pip3 install -r requirements.txt --find-links ${PIP_REQIUREMENT_DIR}
else
	set -e
	git clone https://github.com/kubernetes-sigs/kubespray
	cd kubespray/
	if [ "${KUBESPRAY_VERSION}" != "" ]; then
		git checkout ${KUBESPRAY_VERSION}
	fi
	sudo pip3 install -r requirements.txt
fi

if [ ! -d ~/.ssh ]; then
	mkdir ~/.ssh
	chmod 700 ~/.ssh
fi
if [ ! -f ~/.ssh/id_rsa ]; then
	ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
	for node in ${K8S_NODES}; do
		ssh-copy-id ${node}
	done
fi

USE_REAL_HOSTNAME=True CONFIG_FILE=inventory/sample/hosts.yaml python3 contrib/inventory_builder/inventory.py ${IPS[@]}

sed -i s/"^metrics_server_enabled: false"/"metrics_server_enabled: true"/ inventory/sample/group_vars/k8s_cluster/addons.yml
sed -i s/"^ingress_nginx_enabled: false"/"ingress_nginx_enabled: true"/   inventory/sample/group_vars/k8s_cluster/addons.yml
sed -i s/"^helm_enabled: false"/"helm_enabled: true"/                     inventory/sample/group_vars/k8s_cluster/addons.yml

if [ "${SINGLE_K8S}" != "" ]; then
	# NOTE: This local_volume_provisioner is only for single-k8s deployment to create persistent voluemes always on the same node.
	echo "local_volume_provisioner_enabled: true"                  >> inventory/sample/group_vars/k8s_cluster/addons.yml
	echo "local_volume_provisioner_storage_classes:"               >> inventory/sample/group_vars/k8s_cluster/addons.yml
	echo "  default:"                                              >> inventory/sample/group_vars/k8s_cluster/addons.yml
	echo "    host_dir: /mnt/disks"                                >> inventory/sample/group_vars/k8s_cluster/addons.yml
	echo "    mount_dir: /mnt/disks"                               >> inventory/sample/group_vars/k8s_cluster/addons.yml
	echo "    volume_mode: Filesystem"                             >> inventory/sample/group_vars/k8s_cluster/addons.yml
	echo "    fs_type: ext4"                                       >> inventory/sample/group_vars/k8s_cluster/addons.yml
fi

if [ -n "${K8S_VERSION}" ]; then
	sed -i s/"^kube_version: v.*"/"kube_version: ${K8S_VERSION}"/     inventory/sample/group_vars/k8s_cluster/k8s-cluster.yml
fi
sed -i s/"^# kubeconfig_localhost: false"/"kubeconfig_localhost: true"/   inventory/sample/group_vars/k8s_cluster/k8s-cluster.yml
sed -i s/"^kube_network_plugin: calico"/"kube_network_plugin: flannel"/   inventory/sample/group_vars/k8s_cluster/k8s-cluster.yml
echo "override_system_hostname: false"                                 >> inventory/sample/group_vars/k8s_cluster/k8s-cluster.yml

if [ "${SINGLE_K8S}" != "" ]; then
	# To avoid pending coredns pod on a single node of k8s, set 1 here.
	echo "dns_min_replicas: 1"                                     >> inventory/sample/group_vars/k8s_cluster/k8s-cluster.yml
fi

if [ "${USE_LOCAL_IMAGE_REGISTRY}" != "" ]; then
	LOCALHOST_NAME=$(hostname)
	echo "kube_image_repo: ${LOCALHOST_NAME}:5000"                 >> inventory/sample/group_vars/k8s_cluster/k8s-cluster.yml
	echo "gcr_image_repo: ${LOCALHOST_NAME}:5000"                  >> inventory/sample/group_vars/k8s_cluster/k8s-cluster.yml
	echo "docker_image_repo: ${LOCALHOST_NAME}:5000"               >> inventory/sample/group_vars/k8s_cluster/k8s-cluster.yml
	echo "quay_image_repo: ${LOCALHOST_NAME}:5000"                 >> inventory/sample/group_vars/k8s_cluster/k8s-cluster.yml
fi
if [ "${CEPH_MON_NODES}" != "" ]; then
	MONITORS=""
	for node in ${CEPH_MON_NODES}; do
		MONITORS="${MONITORS} ${node}:6789"
	done
	sed -i s/"^cephfs_provisioner_enabled: false"/"cephfs_provisioner_enabled: true"/ inventory/sample/group_vars/k8s_cluster/addons.yml
	sed -i s/'^# cephfs_provisioner_monitors: "172.24.0.1:6789,172.24.0.2:6789,172.24.0.3:6789"'/"cephfs_provisioner_monitors: \"${MONITORS}\""/ inventory/sample/group_vars/k8s_cluster/addons.yml
fi

ansible-playbook -e "{disable_service_firewall: true}" -i inventory/sample/hosts.yaml --become --become-user=root os-services/os-services.yml

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

if [ ! -d ~/.kube ]; then
	mkdir ~/.kube
fi
cp ./inventory/sample/artifacts/admin.conf ~/.kube/config
chmod 600 ~/.kube/config

if [ "${SINGLE_K8S}" != "" ]; then
	# Make the storageclass "default" as default storageclass
	kubectl patch storageclass default -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
fi

echo "Succeeded to deploy Kubernetes cluster"
