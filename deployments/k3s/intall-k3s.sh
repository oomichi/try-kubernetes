#!/bin/bash

k3s --version 2>/dev/null
if [ $? -ne 0 ]; then
	set -e
	curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="666" sh -
	set +e
fi

k3s kubectl get nodes
if [ $? -ne 0 ]; then
	echo "Failed to install k3s."
	exit 1
fi

k3s kubectl -n kube-system get pods | grep local-path-provisioner
if [ $? -ne 0 ]; then
	k3s kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.35/deploy/local-path-storage.yaml
fi

echo "Succeeded to install k3s."
