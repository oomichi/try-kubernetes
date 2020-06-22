#!/bin/bash

VM_IMAGE=${VM_IMAGE:-"CentOS-7-x86_64"}

function create_machine() {
        VM_NAME=$1

        openstack server show ${VM_NAME} > /dev/null
        if [ $? -eq 0 ]; then
                echo "Deleting old server(${VM_NAME}).."
                openstack server delete ${VM_NAME} > /dev/null
                sleep 5
        fi
        echo "Creating server(${VM_NAME}).."
        openstack server create --flavor=m1.medium --image=${VM_IMAGE} --network=provider --key-name=mykey ${VM_NAME} > /dev/null
        if [ $? -ne 0 ]; then
                echo "Failed to create a server"
                exit 1
        fi

        SUCCESS=0
        RETRY_CHECK=15
        for step in `seq 1 ${RETRY_CHECK}`; do
                VM_STATE=`openstack server show ${VM_NAME} -c "OS-EXT-STS:power_state" -f value`
                if [ "${VM_STATE}" != "Running" ]; then
                        echo "Server(${VM_NAME}) state is ${VM_STATE} on step ${step}"
                        sleep 2
                else
                        SUCCESS=1
                        break
                fi
        done
        if [ ${SUCCESS} -eq 0 ]; then
                echo "Failed to check VM(${VM_NAME})"
                exit 1
        fi
}

create_machine master
create_machine worker

IP_MASTER=`openstack server show master -c addresses -f value | awk -F"=" '{print $2}'`
IP_WORKER=`openstack server show worker -c addresses -f value | awk -F"=" '{print $2}'`

sh-keygen -f "/home/ubuntu/.ssh/known_hosts" -R "${IP_MASTER}"

scp -oStrictHostKeyChecking=no ~/.ssh/id_rsa centos@${IP_MASTER}:/home/centos/.ssh/id_rsa
if [ $? -ne 0 ]; then
        echo "Failed to copy ssh key to server(${IP_MASTER})"
        exit 1
fi

scp -oStrictHostKeyChecking=no kubespray/run-kubespray.sh centos@${IP_MASTER}:/home/centos/run-kubespray.sh
if [ $? -ne 0 ]; then
        echo "Failed to copy run-kubespray.sh to server(${IP_MASTER})"
        exit 1
fi

ssh -oStrictHostKeyChecking=no centos@${IP_MASTER} "K8S_NODES=\"${IP_MASTER} ${IP_WORKER}\" /home/centos/run-kubespray.sh"
if [ $? -ne 0 ]; then
        echo "Failed to operate run-kubespray.sh"
        exit 1
fi

echo "Succeeded to deploy Kubernetes cluster ============================================================================="
echo "Running smoke tests.."
ssh -oStrictHostKeyChecking=no centos@${IP_MASTER} "mkdir /home/centos/yaml"
scp -oStrictHostKeyChecking=no kubespray/yaml/test-ingress-nginx.yaml centos@${IP_MASTER}:/home/centos/yaml/test-ingress-nginx.yaml
if [ $? -ne 0 ]; then
	echo "Failed to copy test-ingress-nginx.yaml to server(${IP_MASTER})"
	exit 1
fi
scp -oStrictHostKeyChecking=no kubespray/run-smoketests.sh centos@${IP_MASTER}:/home/centos/run-smoketests.sh
if [ $? -ne 0 ]; then
	echo "Failed to copy run-smoketests.sh to server(${IP_MASTER})"
	exit 1
fi
ssh -oStrictHostKeyChecking=no centos@${IP_MASTER} "K8S_NODES=\"${IP_MASTER} ${IP_WORKER}\" /home/centos/run-smoketests.sh"
if [ $? -ne 0 ]; then
	echo "Failed to operate run-smoketests.sh"
	exit 1
fi
echo "Succeeded to test Kubernetes cluster ============================================================================="
