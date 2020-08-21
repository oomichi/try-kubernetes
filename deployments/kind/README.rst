kind (Kubernetes in Docker)
===========================

Installation
------------

Just run::
 $ GO111MODULE="on" go get sigs.k8s.io/kind@v0.8.1
 $ kind create cluster

If you don't have kubectl, install it::
 $ curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.18.0/bin/linux/amd64/kubectl
 $ chmod +x kubectl 
 $ sudo mv kubectl /usr/local/bin/

Then you can get .kube/config as your kind kubeconfig and you can run kubectl::
 $ kubectl get nodes
 NAME                 STATUS   ROLES    AGE   VERSION
 kind-control-plane   Ready    master   34m   v1.18.2

Use kind for Kubernetes Development
-----------------------------------

The main purpose of kind is for testing Kubernetes in the community for CI system, but we can use it for Kubernetes development also.
Here tries to use kind for Falco as an example.

If you don't have helm, install it::
 $ curl -LO https://get.helm.sh/helm-v3.3.0-linux-amd64.tar.gz
 $ tar -zxvf helm-v3.3.0-linux-amd64.tar.gz 
 $ chmod +x linux-amd64/helm 
 $ sudo mv linux-amd64/helm /usr/local/bin/

Install Falco::
 $ helm repo add falcosecurity https://falcosecurity.github.io/charts
 $ helm repo update
 $ helm install falco falcosecurity/falco

Facing an issue::
 $ kubectl get pods
 NAME          READY   STATUS             RESTARTS   AGE
 falco-6hhnd   0/1     CrashLoopBackOff   13         56m
 $
 $ kubectl logs pod/falco-6hhnd 
 [..]
 Thu Aug 20 23:46:18 2020: Loading rules from file /etc/falco/falco_rules.yaml:
 Thu Aug 20 23:46:20 2020: Loading rules from file /etc/falco/falco_rules.local.yaml:
 Thu Aug 20 23:46:21 2020: Unable to load the driver. Exiting.
 Thu Aug 20 23:46:21 2020: Runtime error: error opening device /host/dev/falco0. Make sure you have root credentials and that the falco module is loaded.. Exiting.
 $
