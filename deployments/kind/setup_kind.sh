#!/bin/bash
set -e

CLUSTER_NAME=$1
if [ "${CLUSTER_NAME}" = "" ]; then
	CLUSTER_NAME="kind"
fi

sudo chmod 666 /var/run/docker.sock

# Get kind command
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.8.1/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/

set +e
kubectl version
if [ $? -eq 127 ]; then
	curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.18.0/bin/linux/amd64/kubectl
	chmod +x kubectl
	sudo mv kubectl /usr/local/bin/
fi

# Cleanup the previous one
kind delete cluster --name ${CLUSTER_NAME}

kind create cluster --name ${CLUSTER_NAME}
