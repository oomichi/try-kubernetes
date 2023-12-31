#!/bin/bash

cd $(dirname $0)

export AKS_RESOURCE_GROUP=${AKS_RESOURCE_GROUP:-"aks_rg"}
export AKS_NAME=${AKS_NAME:-"akstest"}

if [ "${AZURE_SUBSCRIPTION_ID}" == "" ] || [ "${AZURE_CLIENT_ID}" == "" ] || [ "${AZURE_SECRET}" == "" ] || [ "${AZURE_TENANT}" == "" ]; then
	echo "Environment variables AZURE_SUBSCRIPTION_ID, AZURE_CLIENT_ID, AZURE_SECRET and AZURE_TENANT should be specified."
	echo "To create a service principal which contains the variables, run the following steps:"
	echo "  $ curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
	echo "  $ az login"
	echo "  $ az ad sp create-for-rbac --name ansible --role Contributor --scopes /subscriptions/<subscription id>"
	exit 1
fi

if [ ! -d ./venv-ansible ]; then
	set -e
	sudo apt update
	sudo apt -y install python3-pip python3-venv
	python3 -m venv ./venv-ansible
	source ./venv-ansible/bin/activate

	pip install ansible
	ansible --version
	# NOTE: requirements-azure.txt is downloaded by the following command.
	# If necessary, please update it by doing again.
	# curl -O https://raw.githubusercontent.com/ansible-collections/azure/dev/requirements-azure.txt
	pip install -r requirements-azure.txt
	ansible-galaxy collection install azure.azcollection
	set +e
else
	source ./venv-ansible/bin/activate
fi

set -e

curl -LO https://dl.k8s.io/release/v1.27.0/bin/linux/amd64/kubectl
chmod 755 ./kubectl
ansible-playbook ./aks.yaml --extra-vars "aks_resource_group=${AKS_RESOURCE_GROUP} aks_name=${AKS_NAME}"
az aks get-credentials --resource-group ${AKS_RESOURCE_GROUP} --name ${AKS_NAME} --admin
./kubectl get nodes
