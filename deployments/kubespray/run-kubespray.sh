#!/bin/bash

if [ "${IPS_NODES}" = "" ]; then
	echo 'Need to specify IP addresses of target nodes like:'
	echo '$ IPS_NODES="192.168.1.102 192.168.1.135" ./run-kubespray.sh'
	exit 1
fi

declare -a IPS=(${IPS_NODES})

# Enable error handling
set -e

sudo yum -y install git python3-pip patch
git clone https://github.com/kubernetes-sigs/kubespray
cd kubespray/

# Start - This is a workaround for Docker version issue
# After merging https://github.com/kubernetes-sigs/kubespray/pull/6163
# we can remove this
git fetch origin pull/6163/head:WORKAROUND
git checkout WORKAROUND
git log -p -n1 > foo.patch
git checkout remotes/origin/release-2.13
set +e   # Temporary disable for partitially failed to apply the patch (not critical because of fedora, not redhat/centos)
patch -p1 < foo.patch
set -e
rm foo.patch
# End - This is a workaround for Docker version issue

sudo pip3 install -r requirements.txt
CONFIG_FILE=inventory/sample/hosts.yaml python3 contrib/inventory_builder/inventory.py ${IPS[@]}
sed -i s/"^metrics_server_enabled: false"/"metrics_server_enabled: true"/ inventory/sample/group_vars/k8s-cluster/addons.yml
sed -i s/"^ingress_nginx_enabled: false"/"ingress_nginx_enabled: true"/   inventory/sample/group_vars/k8s-cluster/addons.yml
sed -i s/"^# kubeconfig_localhost: false"/"kubeconfig_localhost: true"/   inventory/sample/group_vars/k8s-cluster/k8s-cluster.yml
sed -i s/"^kube_network_plugin: calico"/"kube_network_plugin: flannel"/   inventory/sample/group_vars/k8s-cluster/k8s-cluster.yml
sed -i s/"^override_system_hostname: true"/"override_system_hostname: false"/ roles/bootstrap-os/defaults/main.yml

ansible-playbook -i inventory/sample/hosts.yaml  --become --become-user=root cluster.yml

echo "Succeeded to deploy Kubernetes cluster"


