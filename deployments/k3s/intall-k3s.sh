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

echo "Succeeded to install k3s."
