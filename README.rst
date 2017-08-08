Try local k8s cluster on laptop PC
==================================

https://github.com/kubernetes/community/blob/master/contributors/devel/e2e-tests.md#local-clusters

Prepare
-------

Need to install docker.io::

 $ sudo apt-get install docker.io
 $ sudo gpasswd -a $USER docker

Need to install the latest etcd from a tar file.
(ubuntu etcd package(v2.2.5) is too old, 3.0.17+ is required)::

 $ sudo mkdir /opt/bin
 $ wget https://github.com/coreos/etcd/releases/download/v3.2.4/etcd-v3.2.4-linux-amd64.tar.gz
 $ tar -zxvf etcd-v3.2.4-linux-amd64.tar.gz
 $ cd etcd-v3.2.4-linux-amd64/
 $ sudo mv etcd    /opt/bin
 $ sudo mv etcdctl /opt/bin
 $ sudo ln -s /opt/bin/etcd    /usr/local/bin/etcd
 $ sudo ln -s /opt/bin/etcdctl /usr/local/bin/etcdctl
 $ sudo chmod 755 /opt/bin/etcd
 $ sudo chmod 755 /opt/bin/etcdctl

Need to install golang 1.8 which is not provided from ubuntu 16.04 as the
default. So we need to do the following process for that::

 $ sudo add-apt-repository ppa:longsleep/golang-backports
 $ sudo apt-get update
 $ sudo apt-get install golang-1.8

The binary is installed under /usr/lib/go-1.8/bin/go, so we need to make
a link::

 $ sudo ln -s /usr/lib/go-1.8/bin/go /usr/local/bin/go
 $ sudo ln -s /usr/lib/go-1.8/bin/gofmt /usr/local/bin/gofmt

Set GOPATH as parmanent setting::

 $ mkdir ${HOME}/go
 $ echo "export GOPATH=${HOME}/go" >> ${HOME}/.bashrc

Install some building packages::

 $ sudo apt-get install gcc
 $ sudo apt-get install make

Run k8s cluster
---------------

Download k8s source code::

 $ go get k8s.io/kubernetes
 package k8s.io/kubernetes: no buildable Go source files in /home/oomichi/go/src/k8s.io/kubernetes
 $

The above should install k8s cluster code, but now we face the error.
TODO: This should be fixed later.

Run k8s cluster::

 $ cd $GOPATH/src/k8s.io/kubernetes
 $ sudo PATH=$PATH hack/local-up-cluster.sh
 [..] Take much time..
 Local Kubernetes cluster is running. Press Ctrl-C to shut it down.
 $

Run e2e test
------------

Build e2e test binary::

 $ cd $GOPATH/src/k8s.io/kubernetes
 $ make quick-release
 +++ [0807 21:31:45] Building go targets for linux/amd64:
     cmd/kubemark
         vendor/github.com/onsi/ginkgo/ginkgo
             test/e2e_node/e2e_node.test
             +++ [0807 21:33:27] Syncing out of container
             rsync: chgrp "/home/oomichi/go/src/k8s.io/kubernetes/pkg/generated/openapi/zz_generated.openapi.go" failed: Operation not permitted (1)
             rsync error: some files/attrs were not transferred (see previous errors) (code 23) at main.c(1655) [generator=3.1.1]
             !!! [0807 21:34:04] Call tree:
             !!! [0807 21:34:04]  1: build/../build/common.sh:714 kube::build::rsync(...)
             !!! [0807 21:34:04]  2: build/release.sh:43 kube::build::copy_output(...)
             Makefile:404: recipe for target 'quick-release' failed
             make: *** [quick-release] Error 1
 $ make ginkgo
 $ make generated_files

Run e2e test::

 $ export KUBECONFIG=/var/run/kubernetes/admin.kubeconfig
 $ export KUBE_MASTER_IP="127.0.0.1"
 $ export KUBE_MASTER=local
 $ export KUBERNETES_PROVIDER=local
 $ cd kubernetes/
 $ go run hack/e2e.go -- -v --test --test_args="--ginkgo.dryRun=true --ginkgo.focus=(\[sig\-network\]\sDNS\sshould\sprovide\sDNS\sfor\sservices\s\[Conformance\])|(\[sig\-apps\]\sReplicaSet\sshould\sserve\sa\sbasic\simage\son\seach\sreplica\swith\sa\spublic\simage\s\[Conformance\])|(\[k8s\.io\]\sServiceAccounts\sshould\smount\san\sAPI\stoken\sinto\spods\s\[Conformance\])|(\[k8s\.io\]\sProjected\sshould\sbe\sconsumable\sfrom\spods\sin\svolume\s\[Conformance\]\s\[sig\-storage\])|(\[k8s\.io\]\sNetworking\s\[k8s\.io\]\sGranular\sChecks:\sPods\sshould\sfunction\sfor\sintra\-pod\scommunication)|(\[k8s\.io\]\sEmptyDir\svolumes\sshould\ssupport)"
 [..]

 Failure [902.494 seconds]
 [BeforeSuite] BeforeSuite
 /go/src/k8s.io/kubernetes/_output/dockerized/go/src/k8s.io/kubernetes/test/e2e/e2e.go:215

 Aug  1 14:51:54.082: Error waiting for all pods to be running and ready: 1 / 1 pods in namespace "kube-system" are NOT in RUNNING and READY state in 10m0s
 POD                       NODE PHASE   GRACE CONDITIONS
 kube-dns-4124969034-bbhss      Pending       [{Type:PodScheduled Status:False LastProbeTime:0001-01-01 00:00:00 +0000 UTC LastTransitionTime:2017-08-01 10:11:34 -0700 PDT Reason:Unschedulable Message:no nodes available to schedule pods}]

 /go/src/k8s.io/kubernetes/_output/dockerized/go/src/k8s.io/kubernetes/test/e2e/e2e.go:166
 ------------------------------
 Aug  1 14:51:54.102: INFO: Running AfterSuite actions on all node
 Aug  1 14:51:54.102: INFO: Running AfterSuite actions on node 1

 Ran 453 of 0 Specs in 902.513 seconds
 FAIL! -- 0 Passed | 453 Failed | 0 Pending | 0 Skipped --- FAIL: TestE2E (902.64s)
 FAIL

 Ginkgo ran 1 suite in 15m3.192749543s
 Test Suite Failed
 !!! Error in ./hack/ginkgo-e2e.sh:134
 Error in ./hack/ginkgo-e2e.sh:134. '"${ginkgo}" "${ginkgo_args[@]:+${ginkgo_args[@]}}" "${e2e_test}" -- "${auth_config[@]:+${auth_config[@]}}" --ginkgo.flakeAttempts="${FLAKE_ATTEMPTS}" --host="${KUBE_MASTER_URL}" --provider="${KUBERNETES_PROVIDER}" --gce-project="${PROJECT:-}" --gce-zone="${ZONE:-}" --gce-multizone="${MULTIZONE:-false}" --gke-cluster="${CLUSTER_NAME:-}" --kube-master="${KUBE_MASTER:-}" --cluster-tag="${CLUSTER_ID:-}" --cloud-config-file="${CLOUD_CONFIG:-}" --repo-root="${KUBE_ROOT}" --node-instance-group="${NODE_INSTANCE_GROUP:-}" --prefix="${KUBE_GCE_INSTANCE_PREFIX:-e2e}" --network="${KUBE_GCE_NETWORK:-${KUBE_GKE_NETWORK:-e2e}}" --node-tag="${NODE_TAG:-}" --master-tag="${MASTER_TAG:-}" --federated-kube-context="${FEDERATION_KUBE_CONTEXT:-e2e-federation}" ${KUBE_CONTAINER_RUNTIME:+"--container-runtime=${KUBE_CONTAINER_RUNTIME}"} ${MASTER_OS_DISTRIBUTION:+"--master-os-distro=${MASTER_OS_DISTRIBUTION}"} ${NODE_OS_DISTRIBUTION:+"--node-os-distro=${NODE_OS_DISTRIBUTION}"} ${NUM_NODES:+"--num-nodes=${NUM_NODES}"} ${E2E_REPORT_DIR:+"--report-dir=${E2E_REPORT_DIR}"} ${E2E_REPORT_PREFIX:+"--report-prefix=${E2E_REPORT_PREFIX}"} "${@:-}"' exited with status 1
 Call stack:
   1: ./hack/ginkgo-e2e.sh:134 main(...)
 Exiting with status 1
 2017/08/01 14:51:54 util.go:133: Step './hack/ginkgo-e2e.sh' finished in 15m3.318912872s
 2017/08/01 14:51:54 main.go:233: Something went wrong: encountered 1 errors: [error during ./hack/ginkgo-e2e.sh: exit status 1]
 2017/08/01 14:51:54 e2e.go:78: err: exit status 1
 exit status 1

Try Kubernetes on separated physical machines
=============================================

Install
-------

Based on http://tracpath.com/works/devops/how-to-install-the-kubernetes-kubeadm/

- kube-master: 172.27.138.55, OptiPlex 7040(Core i5, 8GB)
- kube-host01: 172.27.138.90, OptiPlex 7020(Core i5, 16GB)

Operate the following installation on both kube-master and kube-host01::

 $ sudo su -
 # apt-get update && apt-get install -y apt-transport-https
 # curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
 # vi /etc/apt/sources.list.d/kubernetes.list
 # cat /etc/apt/sources.list.d/kubernetes.list
 deb http://apt.kubernetes.io/ kubernetes-xenial main
 # apt-get update
 # apt-get install -y docker-engine
 # apt-get install -y kubelet kubeadm kubectl kubernetes-cni

Initialization of kube-master
-----------------------------

Operate the following commands::

 # kubeadm init
 [..]
 Your Kubernetes master has initialized successfully!
 [..]
 You can now join any number of machines by running the following on each node
 as root:

   kubeadm join --token 22ac74.4d061109507a992b 172.27.138.55:6443
 #

The above output needs to be operated on kube-host01 to join into the cluster.

Operate the following commands::

 $ sudo cp /etc/kubernetes/admin.conf $HOME/
 $ sudo chown $(id -u):$(id -g) $HOME/admin.conf
 $ export KUBECONFIG=$HOME/admin.conf

Check the valid installation::

 $ kubectl get nodes
 NAME           STATUS     AGE       VERSION
 kube-manager   NotReady   1h        v1.6.6
 $
 $ kubectl apply -f https://git.io/weave-kube-1.6
 $
 $ kubectl get pods --all-namespaces
 NAMESPACE     NAME                                   READY     STATUS              RESTARTS   AGE
 kube-system   etcd-kube-manager                      1/1       Running             0          1h
 kube-system   kube-apiserver-kube-manager            1/1       Running             0          1h
 kube-system   kube-controller-manager-kube-manager   1/1       Running             0          1h
 kube-system   kube-dns-692378583-3gbgp               0/3       ContainerCreating   0          1h
 kube-system   kube-proxy-4rbvg                       1/1       Running             0          1h
 kube-system   kube-scheduler-kube-manager            1/1       Running             0          1h
 kube-system   weave-net-cjf25                        2/2       Running             0          51s
 $

Add a node into k8s cluster
---------------------------

Operate the following command on a node (not manager)::

 # kubeadm join --token 22ac74.4d061109507a992b 172.27.138.55:6443

Check the node joins into the cluster with the command on the manager::

 $ kubectl get nodes
 NAME           STATUS    AGE       VERSION
 kube-host01    Ready     51s       v1.6.6
 kube-manager   Ready     1h        v1.6.6
 $

How to see REST API operation on kubectl command
------------------------------------------------

Just specify '--v=8' option on kubectl command like::

 $ kubectl --v=8 get nodes
 [..] GET https://172.27.138.55:6443/api/v1/nodes
 [..] Request Headers:
 [..]     Accept: application/json
 [..]     User-Agent: kubectl/v1.6.6 (linux/amd64) kubernetes/7fa1c17
 [..] Response Status: 200 OK in 21 milliseconds
 [..] Response Headers:
 [..]     Content-Type: application/json
 [..]     Date: Wed, 28 Jun 2017 00:33:39 GMT
 [..] Response Body: {"kind":"NodeList","apiVersion":"v1",
                      "metadata":{"selfLink":"/api/v1/nodes","resourceVersion":"7254"},
                      "items":[{"metadata":{"name":"kube-host01","selfLink":"/api/v1/nodeskube-host01",
                                            "uid":"a354969d-5b98-11e7-9e55-1866da463eb0",
                                            "resourceVersion":"7244","creationTimestamp":"2017-06-28T00:27:59Z",
                                            "labels":{"beta.kubernetes.io/arch":"amd64",
                                                      "beta.kubernetes.io/os":"linux",
                                                      "kubernetes.io/hostname":"kube-host01"} ..


