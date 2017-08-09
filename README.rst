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

If using VirtualBox, need to specify the internal ip address like::

 # kubeadm init --apiserver-advertise-address 172.168.0.1

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
 $ sudo chown oomichi -R .
 $ make ginkgo
 $ make generated_files

Run e2e test
------------

Run e2e test::

 $ export KUBECONFIG=$HOME/admin.conf
 $ export KUBE_MASTER_IP="127.0.0.1"
 $ export KUBE_MASTER=local
 $ export KUBERNETES_PROVIDER=local
 $ go run hack/e2e.go -- -v --test --test_args="--ginkgo.focus=(\[sig\-network\]\sDNS\sshould\sprovide\sDNS\sfor\sservices\s\[Conformance\])|(\[sig\-apps\]\sReplicaSet\sshould\sserve\sa\sbasic\simage\son\seach\sreplica\swith\sa\spublic\simage\s\[Conformance\])|(\[k8s\.io\]\sServiceAccounts\sshould\smount\san\sAPI\stoken\sinto\spods\s\[Conformance\])|(\[k8s\.io\]\sProjected\sshould\sbe\sconsumable\sfrom\spods\sin\svolume\s\[Conformance\]\s\[sig\-storage\])|(\[k8s\.io\]\sNetworking\s\[k8s\.io\]\sGranular\sChecks:\sPods\sshould\sfunction\sfor\sintra\-pod\scommunication)|(\[k8s\.io\]\sEmptyDir\svolumes\sshould\ssupport)"
 2017/08/08 18:32:34 e2e.go:76: Calling kubetest -v --test --test_args=--ginkgo.focus=(\[sig\-network\]\sDNS\sshould\sprovide\sDNS\sfor\sservices\s\[Conformance\])|(\[sig\-apps\]\sReplicaSet\sshould\sserve\sa\sbasic\simage\son\seach\sreplica\swith\sa\spublic\simage\s\[Conformance\])|(\[k8s\.io\]\sServiceAccounts\sshould\smount\san\sAPI\stoken\sinto\spods\s\[Conformance\])|(\[k8s\.io\]\sProjected\sshould\sbe\sconsumable\sfrom\spods\sin\svolume\s\[Conformance\]\s\[sig\-storage\])|(\[k8s\.io\]\sNetworking\s\[k8s\.io\]\sGranular\sChecks:\sPods\sshould\sfunction\sfor\sintra\-pod\scommunication)|(\[k8s\.io\]\sEmptyDir\svolumes\sshould\ssupport)...
 2017/08/08 18:32:34 util.go:262: Please use kubetest --provider=local (instead of deprecated KUBERNETES_PROVIDER=local)
 2017/08/08 18:32:34 util.go:131: Running: ./cluster/kubectl.sh --match-server-version=false version
 2017/08/08 18:32:35 util.go:133: Step './cluster/kubectl.sh --match-server-version=false version' finished in 165.455139ms
 2017/08/08 18:32:35 util.go:131: Running: ./hack/e2e-internal/e2e-status.sh
 Local doesn't need special preparations for e2e tests
 Client Version: version.Info{Major:"1", Minor:"8+", GitVersion:"v1.8.0-alpha.2.1535+5793be779be25d", GitCommit:"5793be779be25d43a397acc164b326977cd0129f", GitTreeState:"clean", BuildDate:"2017-08-09T01:03:05Z", GoVersion:"go1.8.3", Compiler:"gc", Platform:"linux/amd64"}
 Server Version: version.Info{Major:"1", Minor:"7", GitVersion:"v1.7.3", GitCommit:"2c2fe6e8278a5db2d15a013987b53968c743f2a1", GitTreeState:"clean", BuildDate:"2017-08-03T06:43:48Z", GoVersion:"go1.8.3", Compiler:"gc", Platform:"linux/amd64"}
 2017/08/08 18:32:35 util.go:133: Step './hack/e2e-internal/e2e-status.sh' finished in 194.908616ms
 2017/08/08 18:32:35 util.go:131: Running: ./hack/ginkgo-e2e.sh --ginkgo.focus=(\[sig\-network\]\sDNS\sshould\sprovide\sDNS\sfor\sservices\s\[Conformance\])|(\[sig\-apps\]\sReplicaSet\sshould\sserve\sa\sbasic\simage\son\seach\sreplica\swith\sa\spublic\simage\s\[Conformance\])|(\[k8s\.io\]\sServiceAccounts\sshould\smount\san\sAPI\stoken\sinto\spods\s\[Conformance\])|(\[k8s\.io\]\sProjected\sshould\sbe\sconsumable\sfrom\spods\sin\svolume\s\[Conformance\]\s\[sig\-storage\])|(\[k8s\.io\]\sNetworking\s\[k8s\.io\]\sGranular\sChecks:\sPods\sshould\sfunction\sfor\sintra\-pod\scommunication)|(\[k8s\.io\]\sEmptyDir\svolumes\sshould\ssupport)
 Setting up for KUBERNETES_PROVIDER="local".
 Local doesn't need special preparations for e2e tests
 2017/08/08 18:32:35 proto: duplicate proto type registered: google.protobuf.Any
 2017/08/08 18:32:35 proto: duplicate proto type registered: google.protobuf.Duration
 2017/08/08 18:32:35 proto: duplicate proto type registered: google.protobuf.Timestamp
 Aug  8 18:32:35.700: INFO: Overriding default scale value of zero to 1
 Aug  8 18:32:35.701: INFO: Overriding default milliseconds value of zero to 5000
 I0808 18:32:35.843815   17035 e2e.go:354] Starting e2e run "9f37be89-7ca2-11e7-9031-080027b1b50a" on Ginkgo node 1
 Running Suite: Kubernetes e2e suite
 ===================================
 Random Seed: 1502242355 - Will randomize all specs
 Will run 19 of 652 specs

 Aug  8 18:32:36.056: INFO: >>> kubeConfig: /home/oomichi/admin.conf
 Aug  8 18:32:36.059: INFO: Waiting up to 4h0m0s for all (but 0) nodes to be schedulable
 Aug  8 18:32:36.061: INFO: Unexpected error listing nodes: Get http://127.0.0.1:8080/api/v1/nodes?fieldSelector=spec.unschedulable%3Dfalse&resourceVersion=0: dial tcp 127.0.0.1:8080: getsockopt: connection refused
 Aug  8 18:32:36.061: INFO: Unexpected error occurred: Get http://127.0.0.1:8080/api/v1/nodes?fieldSelector=spec.unschedulable%3Dfalse&resourceVersion=0: dial tcp 127.0.0.1:8080: getsockopt: connection refused
 Failure [0.008 seconds]
 [BeforeSuite] BeforeSuite
 /go/src/k8s.io/kubernetes/_output/dockerized/go/src/k8s.io/kubernetes/test/e2e/e2e.go:231

