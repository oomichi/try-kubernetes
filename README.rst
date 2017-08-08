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
 $ # Need to chown due to the above `sudo PATH=$PATH hack/local-up-cluster.sh`
 $ sudo chown -R $USER .
 $ make quick-release
 $ make ginkgo
 $ make generated_files

Run e2e test::

 $ export KUBECONFIG=/var/run/kubernetes/admin.kubeconfig
 $ export KUBE_MASTER_IP="127.0.0.1"
 $ export KUBE_MASTER=local
 $ export KUBERNETES_PROVIDER=local
 $ go run hack/e2e.go -- -v --test --test_args="--ginkgo.focus=(\[sig\-network\]\sDNS\sshould\sprovide\sDNS\sfor\sservices\s\[Conformance\])|(\[sig\-apps\]\sReplicaSet\sshould\sserve\sa\sbasic\simage\son\seach\sreplica\swith\sa\spublic\simage\s\[Conformance\])|(\[k8s\.io\]\sServiceAccounts\sshould\smount\san\sAPI\stoken\sinto\spods\s\[Conformance\])|(\[k8s\.io\]\sProjected\sshould\sbe\sconsumable\sfrom\spods\sin\svolume\s\[Conformance\]\s\[sig\-storage\])|(\[k8s\.io\]\sNetworking\s\[k8s\.io\]\sGranular\sChecks:\sPods\sshould\sfunction\sfor\sintra\-pod\scommunication)|(\[k8s\.io\]\sEmptyDir\svolumes\sshould\ssupport)"
 [..]
 Failure [901.857 seconds]
 [BeforeSuite] BeforeSuite
 /go/src/k8s.io/kubernetes/_output/dockerized/go/src/k8s.io/kubernetes/test/e2e/e2e.go:231

 Aug  7 23:39:08.187: Error waiting for all pods to be running and ready: 1 / 1 pods in namespace "kube-system" are NOT in RUNNING and READY state in 10m0s
 POD                       NODE PHASE   GRACE CONDITIONS
 kube-dns-4124969034-wptwh      Pending       [{Type:PodScheduled Status:False LastProbeTime:0001-01-01 00:00:00 +0000 UTC LastTransitionTime:2017-08-07 21:07:52 -0700 PDT Reason:Unschedulable Message:no nodes available to schedule pods}]

 /go/src/k8s.io/kubernetes/_output/dockerized/go/src/k8s.io/kubernetes/test/e2e/e2e.go:182
 ------------------------------
 Aug  7 23:39:08.190: INFO: Running AfterSuite actions on all node
 Aug  7 23:39:08.190: INFO: Running AfterSuite actions on node 1

 Ran 19 of 0 Specs in 901.859 seconds
 FAIL! -- 0 Passed | 19 Failed | 0 Pending | 0 Skipped --- FAIL: TestE2E (902.09s)
 FAIL

 Ginkgo ran 1 suite in 15m2.670899727s
 Test Suite Failed
 !!! Error in ./hack/ginkgo-e2e.sh:132
   Error in ./hack/ginkgo-e2e.sh:132. '"${ginkgo}" "${ginkgo_args[@]:+${ginkgo_args[@]}}" "${e2e_test}" -- "${auth_config[@]:+${auth_config[@]}}" --ginkgo.flakeAttempts="${FLAKE_ATTEMPTS}" --host="${KUBE_MASTER_URL}" --provider="${KUBERNETES_PROVIDER}" --gce-project="${PROJECT:-}" --gce-zone="${ZONE:-}" --gce-region="${REGION:-}" --gce-multizone="${MULTIZONE:-false}" --gke-cluster="${CLUSTER_NAME:-}" --kube-master="${KUBE_MASTER:-}" --cluster-tag="${CLUSTER_ID:-}" --cloud-config-file="${CLOUD_CONFIG:-}" --repo-root="${KUBE_ROOT}" --node-instance-group="${NODE_INSTANCE_GROUP:-}" --prefix="${KUBE_GCE_INSTANCE_PREFIX:-e2e}" --network="${KUBE_GCE_NETWORK:-${KUBE_GKE_NETWORK:-e2e}}" --node-tag="${NODE_TAG:-}" --master-tag="${MASTER_TAG:-}" --federated-kube-context="${FEDERATION_KUBE_CONTEXT:-e2e-federation}" ${KUBE_CONTAINER_RUNTIME:+"--container-runtime=${KUBE_CONTAINER_RUNTIME}"} ${MASTER_OS_DISTRIBUTION:+"--master-os-distro=${MASTER_OS_DISTRIBUTION}"} ${NODE_OS_DISTRIBUTION:+"--node-os-distro=${NODE_OS_DISTRIBUTION}"} ${NUM_NODES:+"--num-nodes=${NUM_NODES}"} ${E2E_REPORT_DIR:+"--report-dir=${E2E_REPORT_DIR}"} ${E2E_REPORT_PREFIX:+"--report-prefix=${E2E_REPORT_PREFIX}"} "${@:-}"' exited with status 1
 Call stack:
   1: ./hack/ginkgo-e2e.sh:132 main(...)
 Exiting with status 1
 2017/08/07 23:39:08 util.go:133: Step './hack/ginkgo-e2e.sh --ginkgo.focus=(\[sig\-network\]\sDNS\sshould\sprovide\sDNS\sfor\sservices\s\[Conformance\])|(\[sig\-apps\]\sReplicaSet\sshould\sserve\sa\sbasic\simage\son\seach\sreplica\swith\sa\spublic\simage\s\[Conformance\])|(\[k8s\.io\]\sServiceAccounts\sshould\smount\san\sAPI\stoken\sinto\spods\s\[Conformance\])|(\[k8s\.io\]\sProjected\sshould\sbe\sconsumable\sfrom\spods\sin\svolume\s\[Conformance\]\s\[sig\-storage\])|(\[k8s\.io\]\sNetworking\s\[k8s\.io\]\sGranular\sChecks:\sPods\sshould\sfunction\sfor\sintra\-pod\scommunication)|(\[k8s\.io\]\sEmptyDir\svolumes\sshould\ssupport)' finished in 15m2.74495882s
 2017/08/07 23:39:08 main.go:241: Something went wrong: encountered 1 errors: [error during ./hack/ginkgo-e2e.sh --ginkgo.focus=(\[sig\-network\]\sDNS\sshould\sprovide\sDNS\sfor\sservices\s\[Conformance\])|(\[sig\-apps\]\sReplicaSet\sshould\sserve\sa\sbasic\simage\son\seach\sreplica\swith\sa\spublic\simage\s\[Conformance\])|(\[k8s\.io\]\sServiceAccounts\sshould\smount\san\sAPI\stoken\sinto\spods\s\[Conformance\])|(\[k8s\.io\]\sProjected\sshould\sbe\sconsumable\sfrom\spods\sin\svolume\s\[Conformance\]\s\[sig\-storage\])|(\[k8s\.io\]\sNetworking\s\[k8s\.io\]\sGranular\sChecks:\sPods\sshould\sfunction\sfor\sintra\-pod\scommunication)|(\[k8s\.io\]\sEmptyDir\svolumes\sshould\ssupport): exit status 1]
 2017/08/07 23:39:08 e2e.go:78: err: exit status 1
 exit status 1

Try Kubernetes on separated machines
====================================

Install
-------

Based on http://tracpath.com/works/devops/how-to-install-the-kubernetes-kubeadm/

- Distro: ubuntu 16.04 LTS

(VirtualBox) Add an internal network between VMs::

 http://qiita.com/areaz_/items/c9075f7a0b3e147e92f2#%E3%82%B2%E3%82%B9%E3%83%88os%E3%81%AE%E5%8B%95%E4%BD%9C%E7%A2%BA%E8%AA%8D
 Shutdown a VM

 Setting -> Network -> Adapter 2
   Check "Enable Network Adapter"
   Attached to: "Internal Network"

 Reboot the VM

 SSH into the VM (kube-host01 should be 172.168.0.2)
   $ sudo vi /etc/network/interfaces
   + auto enp0s8
   + iface enp0s8 inet static
   + address 172.168.0.1
   + netmask 255.255.255.0

 Reboot the VM

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
 $ echo "export KUBECONFIG=$HOME/admin.conf" >> /home/oomichi/.bashrc

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


