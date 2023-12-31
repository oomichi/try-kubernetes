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

set -e

ansible-playbook ./eks.yaml --extra-vars "eks_name=${EKS_NAME} region=${EKS_REGION} eks_role_arn=${EKS_ROLE_ARN} eks_worker_arn=${EKS_WORKER_ROLE_ARN}"

echo "Succeeded to create an EKS cluster."
