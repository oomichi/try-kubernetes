#!/bin/bash

cd $(dirname $0) 

K8S_NAMESPACE=default

set -e
echo "Deploying keycloak.."
kubectl -n ${K8S_NAMESPACE} apply -f ./keycloak.yaml

echo "Waiting for keycloak.."
sleep 10
kubectl -n ${K8S_NAMESPACE} wait --timeout=10m --for=condition=ready pod -l app=keycloak

echo "Succeeded to deploy keycloak."
