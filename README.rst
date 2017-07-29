Try kurbernetes
===============

Prepare
-------

Need to install docker.io::

 $ sudo apt-get install docker.io

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

Run e2e test
------------

Run k8s cluster::

 $ git clone https://github.com/kubernetes/kubernetes
 $ cd kubernetes
 $ sudo PATH=$PATH hack/local-up-cluster.sh
 [..] Take much time..
 Local Kubernetes cluster is running. Press Ctrl-C to shut it down.

 Logs:
  /tmp/kube-apiserver.log
  /tmp/kube-controller-manager.log
  /tmp/kube-proxy.log
  /tmp/kube-scheduler.log
  /tmp/kubelet.log

 To start using your cluster, you can open up another terminal/tab and run:

  export KUBECONFIG=/var/run/kubernetes/admin.kubeconfig
  cluster/kubectl.sh

 Alternatively, you can write to the default kubeconfig:

  export KUBERNETES_PROVIDER=local

  cluster/kubectl.sh config set-cluster local --server=https://localhost:6443 --certificate-authority=/var/run/kubernetes/server-ca.crt
  cluster/kubectl.sh config set-credentials myself --client-key=/var/run/kubernetes/client-admin.key --client-certificate=/var/run/kubernetes/client-admin.crt
  cluster/kubectl.sh config set-context local --cluster=local --user=myself
  cluster/kubectl.sh config use-context local
  cluster/kubectl.sh

Run e2e test::

 $ export KUBECONFIG=/var/run/kubernetes/admin.kubeconfig
 $ export KUBE_MASTER_IP="127.0.0.1"
 $ export KUBE_MASTER=local
 $ cd kubernetes/
 s$ go run hack/e2e.go -- -v --test
 e2e.go:146: Updating kubetest binary...
 e2e.go:76: Calling kubetest -v --test...
 util.go:198: Running: ./cluster/kubectl.sh --match-server-version=false version
 util.go:200: Step './cluster/kubectl.sh --match-server-version=false version' finished in 216.073976ms
 util.go:129: Running: ./hack/e2e-internal/e2e-status.sh
 ./hack/e2e-internal/../../cluster/../cluster/gce/util.sh: line 138: gcloud: command not found
 util.go:131: Step './hack/e2e-internal/e2e-status.sh' finished in 35.952315ms
 main.go:233: Something went wrong: encountered 1 errors: [error during ./hack/e2e-internal/e2e-status.sh: exit status 127]
 e2e.go:78: err: exit status 1
 exit status 1
 $

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


