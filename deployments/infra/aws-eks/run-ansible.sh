#!/bin/bash

cd $(dirname $0)

if [ "${EKS_ROLE_ARN}" == "" ] || [ "${EKS_WORKER_ROLE_ARN}" == "" ]; then
	echo "Specify the environment variables EKS_ROLE_ARN and EKS_WORKER_ROLE_ARN."
	echo "Those roles should be created in AWS Dashboard->IAM->Role in advance."
	exit 1
fi

if [ ! -f ~/.aws/credentials ]; then
	echo "Put your AWS credentials on ~/.aws/credentials"
	echo "That is used in boto library which is called from ansible."
	exit 1
fi

EKS_REGION=${EKS_REGION:-"us-west-1"}
EKS_NAME=${EKS_NAME:-"test-cluster"}

PLAYBOOK=./eks.yaml
if [ "$1" == "destroy" ]; then
	PLAYBOOK=./destroy.yaml
fi

if [ ! -d ./venv-ansible ]; then
	set -e
	sudo apt update
	sudo apt -y install python3-pip python3-venv
	python3 -m venv ./venv-ansible
	source ./venv-ansible/bin/activate

	pip install ansible
	ansible --version
	ansible-galaxy collection install community.aws
	pip install botocore boto3
	set +e
else
	source ./venv-ansible/bin/activate
fi

aws --version 2> /dev/null
if [ $? -eq 127 ]; then
	curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
	unzip awscliv2.zip
	sudo ./aws/install
	rm -rf aws/ awscliv2.zip
fi

kubectl version 2> /dev/null
if [ $? -eq 127 ]; then
	curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.28.3/2023-11-14/bin/linux/amd64/kubectl
	chmod 755 ./kubectl
	mkdir -p $HOME/bin
	mv ./kubectl $HOME/bin/
	export PATH=$HOME/bin:$PATH
	echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
fi

set -e
ansible-playbook ${PLAYBOOK} --extra-vars "eks_name=${EKS_NAME} region=${EKS_REGION} eks_role_arn=${EKS_ROLE_ARN} eks_worker_arn=${EKS_WORKER_ROLE_ARN}"
set +e
if [ "${PLAYBOOK}" == "./destroy.yaml" ]; then
	echo "Succeeded to delete EKS cluster and the resources."
	exit 0
fi

set -e
aws eks --region ${EKS_REGION} update-kubeconfig --name ${EKS_NAME}

kubectl get nodes

echo "Succeeded to create an EKS cluster."
