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

Build a node image from k8s.io/kubernetes repository::

 $ kind build node-image --kube-root ~/go/src/k8s.io/kubernetes --image kindest/node:test

Then deploy kind from the built node image::

 $ kind create cluster --image kindest/node:test --name test
