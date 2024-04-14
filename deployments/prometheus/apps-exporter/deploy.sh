#!/bin/bash

cd $(dirname $0)

kubectl delete ns apps-exporter
kubectl create namespace apps-exporter
kubectl -n apps-exporter create configmap python-main --from-file=main.py
kubectl -n apps-exporter apply -f deployment.yaml

sleep 10

kubectl -n apps-exporter get deployment apps-exporter
kubectl -n apps-exporter get servicemonitor apps-exporter
