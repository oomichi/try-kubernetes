#!/bin/bash
set -e

CLUSTER_NAME=$1
if [ "${CLUSTER_NAME}" = "" ]; then
	CLUSTER_NAME="kind"
fi

sudo chmod 666 /var/run/docker.sock
set +e

# Get kind command
kind version
if [ $? -eq 127 ]; then
	curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.17.0/kind-linux-amd64
	chmod +x ./kind
	sudo mv ./kind /usr/local/bin/
fi

kubectl version
if [ $? -eq 127 ]; then
	curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.26.0/bin/linux/amd64/kubectl
	chmod +x kubectl
	sudo mv kubectl /usr/local/bin/
fi

# Cleanup the previous one
kind delete cluster --name ${CLUSTER_NAME}

kind create cluster --name ${CLUSTER_NAME}

for step in `seq 1 24`; do
	STATUS=$(kubectl get nodes | grep control-plane | awk '{print $2}')
	echo "control-plane node is ${STATUS}"
	if [ "${STATUS}" = "Ready" ]; then
		break
	fi
	sleep 10
done
