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
 # echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
 # apt-get update
 # apt-get install -y docker-engine kubelet kubeadm kubectl kubernetes-cni

Initialization of kube-master
-----------------------------

(Flannel) Operate the following commands::

 # kubeadm init --pod-network-cidr=10.244.0.0/16
 [..]
 Your Kubernetes master has initialized successfully!
 [..]
 You can now join any number of machines by running the following on each node
 as root:

   kubeadm join --token 22ac74.4d061109507a992b 172.27.138.55:6443

10.244.0.0/16 comes from kube-flannel.yml which contains::

 "Network": "10.244.0.0/16",

(Other) Operate the following commands::

 # kubeadm init
 [..]
 Your Kubernetes master has initialized successfully!
 [..]
 You can now join any number of machines by running the following on each node
 as root:

   kubeadm join --token 22ac74.4d061109507a992b 172.27.138.55:6443
 #

The above output needs to be operated on kube-host01 to join into the cluster.

If using VirtualBox, need to specify the internal ip address like::

 # kubeadm init --apiserver-advertise-address 172.168.0.1

Operate the following commands::

 $ sudo cp /etc/kubernetes/admin.conf $HOME/
 $ sudo chown $(id -u):$(id -g) $HOME/admin.conf
 $ export KUBECONFIG=$HOME/admin.conf
 $ echo "export KUBECONFIG=$HOME/admin.conf" >> $HOME/.bashrc

(Flannel) Configure network setting for pod2pod communication::

 $ kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml

(Weave) Configure network setting for pod2pod communication::

 $ kubectl apply -f https://git.io/weave-kube-1.6

Check the valid installation::

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

Confirm the STATUS becomes Ready::

 $ kubectl get nodes
 NAME         STATUS    AGE       VERSION
 k8s-master   Ready     1m        v1.7.3

Make the manager schedulable::

 $ kubectl describe nodes | grep Tain
 Taints:                 node-role.kubernetes.io/master:NoSchedule
 $ kubectl taint nodes <master nodename: k8s-master> node-role.kubernetes.io/master:NoSchedule-
 node "k8s-master" untainted
 $ kubectl describe nodes | grep Tain
 Taints:                 <none>
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

Retrive the way to add a node
-----------------------------

Get a kubeadm token::

 $ TOKEN=`sudo kubeadm token list | grep authentication | awk '{print $1}'`
 $ echo $TOKEN
 c3cf19.89e62945a88d7a91

If you cannot get a token, need to recreate with::

 $ sudo kubeadm token create

Get a discovery token::

 $ DISCOVERY_TOKEN=`openssl x509 -pubkey \
 -in /etc/kubernetes/pki/ca.crt | openssl rsa \
 -pubin -outform der 2>/dev/null | openssl dgst \
 -sha256 -hex | sed 's/^.* //'`
 $ echo $DISCOVERY_TOKEN
 b3bb83c24673649bf1909e9144929a64569b1a7988df97323a9a3449c3b4c1e6

Use the token and the discovery token to add a new node on the node::

 $ kubeadm join --token ${TOKEN} 10.128.0.3:6443
 --discovery-token-ca-cert-hash sha256:${DISCOVERY_TOKEN}

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

Run e2e test
============

Prepare
-------

Need to install golang 1.9 which is not provided from ubuntu 16.04 as the
default. So we need to do the following process for that::

 $ sudo add-apt-repository ppa:longsleep/golang-backports
 $ sudo apt-get update
 $ sudo apt-get install -y golang-1.9

The binary is installed under /usr/lib/go-1.9/bin/go, so we need to make
a link::

 $ sudo ln -s /usr/lib/go-1.9/bin/go /usr/local/bin/go
 $ sudo ln -s /usr/lib/go-1.9/bin/gofmt /usr/local/bin/gofmt

Set GOPATH as parmanent setting::

 $ mkdir ${HOME}/go
 $ echo "export GOPATH=${HOME}/go" >> ${HOME}/.bashrc

Install some building packages::

 $ sudo apt-get install -y docker.io gcc make

Build e2e test binary
---------------------

Download k8s source code::

 $ go get k8s.io/kubernetes
 package k8s.io/kubernetes: no buildable Go source files in /home/oomichi/go/src/k8s.io/kubernetes
 $

The above should install k8s cluster code, but now we face the error.
TODO: This should be fixed later.

Build e2e test binary::

 $ cd $GOPATH/src/k8s.io/kubernetes
 # The docker daemon runs as root user, not docker user. So it is necessary to specify `su`
 $ sudo make quick-release
 $ sudo chown $USER -R .
 $ make ginkgo
 $ make generated_files

Run e2e test
------------

Run e2e test::

 $ export KUBECONFIG=$HOME/admin.conf
 $ export KUBERNETES_CONFORMANCE_TEST=true
 $ go run hack/e2e.go -- --provider=skeleton --test --test_args="--ginkgo.focus=\[Conformance\]"
 [..]
 Ran 147 of 652 Specs in 6832.526 seconds
 FAIL! -- 132 Passed | 15 Failed | 0 Pending | 505 Skipped --- FAIL: TestE2E (6832.59s)
 FAIL

 Ginkgo ran 1 suite in 1h53m52.981857781s
 Test Suite Failed
 !!! Error in ./hack/ginkgo-e2e.sh:132
   Error in ./hack/ginkgo-e2e.sh:132. '"${ginkgo}" "${ginkgo_args[@]:+${ginkgo_args[@]}}" "${e2e_test}" -- "${auth_config[@]:+${auth_config[@]}}" --ginkgo.flakeAttempts="${FLAKE_ATTEMPTS}" --host="${KUBE_MASTER_URL}" --provider="${KUBERNETES_PROVIDER}" --gce-project="${PROJECT:-}" --gce-zone="${ZONE:-}" --gce-region="${REGION:-}" --gce-multizone="${MULTIZONE:-false}" --gke-cluster="${CLUSTER_NAME:-}" --kube-master="${KUBE_MASTER:-}" --cluster-tag="${CLUSTER_ID:-}" --cloud-config-file="${CLOUD_CONFIG:-}" --repo-root="${KUBE_ROOT}" --node-instance-group="${NODE_INSTANCE_GROUP:-}" --prefix="${KUBE_GCE_INSTANCE_PREFIX:-e2e}" --network="${KUBE_GCE_NETWORK:-${KUBE_GKE_NETWORK:-e2e}}" --node-tag="${NODE_TAG:-}" --master-tag="${MASTER_TAG:-}" --federated-kube-context="${FEDERATION_KUBE_CONTEXT:-e2e-federation}" ${KUBE_CONTAINER_RUNTIME:+"--container-runtime=${KUBE_CONTAINER_RUNTIME}"} ${MASTER_OS_DISTRIBUTION:+"--master-os-distro=${MASTER_OS_DISTRIBUTION}"} ${NODE_OS_DISTRIBUTION:+"--node-os-distro=${NODE_OS_DISTRIBUTION}"} ${NUM_NODES:+"--num-nodes=${NUM_NODES}"} ${E2E_REPORT_DIR:+"--report-dir=${E2E_REPORT_DIR}"} ${E2E_REPORT_PREFIX:+"--report-prefix=${E2E_REPORT_PREFIX}"} "${@:-}"' exited with status 1
   Call stack:
     1: ./hack/ginkgo-e2e.sh:132 main(...)
 Exiting with status 1
 2017/08/09 13:41:10 util.go:133: Step './hack/ginkgo-e2e.sh --ginkgo.focus=\[Conformance\]' finished in 1h53m53.425307436s
 2017/08/09 13:41:10 main.go:245: Something went wrong: encountered 1 errors: [error during ./hack/ginkgo-e2e.sh --ginkgo.focus=\[Conformance\]: exit status 1]
 2017/08/09 13:41:10 e2e.go:78: err: exit status 1
 exit status 1

Confirm which tests will run without actual tests::

 $ go run hack/e2e.go -- -v --test --test_args="--ginkgo.dryRun=true --ginkgo.focus=\[Conformance\]"
 [..]
 [k8s.io] Docker Containers
   should use the image defaults if command and args are blank [Conformance]
   /go/src/k8s.io/kubernetes/_output/dockerized/go/src/k8s.io/kubernetes/test/e2e/common/docker_containers.go:35
 ~SS
 ------------------------------
 [k8s.io] EmptyDir volumes
   should support (non-root,0644,tmpfs) [Conformance] [sig-storage]
   /go/src/k8s.io/kubernetes/_output/dockerized/go/src/k8s.io/kubernetes/test/e2e/common/empty_dir.go:85
 ~SS
 ------------------------------
 [sig-apps] ReplicaSet
   should serve a basic image on each replica with a public image [Conformance]
   /go/src/k8s.io/kubernetes/_output/dockerized/go/src/k8s.io/kubernetes/test/e2e/apps/replica_set.go:82
 ~S
 ------------------------------
 [sig-network] Services
   should provide secure master service [Conformance]
   /go/src/k8s.io/kubernetes/_output/dockerized/go/src/k8s.io/kubernetes/test/e2e/network/service.go:71
 ~
 Ran 149 of 652 Specs in 0.072 seconds
 SUCCESS! -- 0 Passed | 0 Failed | 0 Pending | 503 Skipped PASS

 Ginkgo ran 1 suite in 519.123083ms
 Test Suite Passed
 2017/08/09 15:38:12 util.go:133: Step './hack/ginkgo-e2e.sh --ginkgo.dryRun=true --ginkgo.focus=\[Conformance\]' finished in 937.615925ms
 2017/08/09 15:38:12 e2e.go:80: Done
 $

Setup dev env
-------------

Install bazel::

 $ sudo apt-get install openjdk-8-jdk    (Don't install openjdk-9-jdk which is not supported on bazel now)
 $ sudo vi /etc/apt/sources.list.d/bazel.list
 $ cat /etc/apt/sources.list.d/bazel.list
 deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8
 $ sudo apt-get install bazel

Run unit tests on kubernetes/test-infra::

 $ bazel test //..

* https://github.com/kubernetes/test-infra#building-and-testing-the-test-infra
* http://qiita.com/lucy/items/e4f21c507d3fd2c0ffe9

Run unit test
-------------

with make::

 $ make test

with bazel::

 $ bazel test //...

