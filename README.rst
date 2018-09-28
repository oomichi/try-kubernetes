.. contents:: Contents
    :depth: 4

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

Operate the following installation on both kube-master and kube-host01 (nfs-common is for Subpath)::

 $ sudo su -
 # apt-get update && apt-get install -y apt-transport-https
 # curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
 # echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
 # apt-get update
 # apt-get install -y docker-engine nfs-common

To install the latest packages of Kubernetes::

 # apt-get install -y kubelet kubeadm kubectl kubernetes-cni

If you want to install previous release of Kubernetes, check avaiable releases with::

 # apt-cache policy kubelet
 kubelet:
   Installed: (none)
   Candidate: 1.10.0-00
   Version table:
      1.10.0-00 500
         500 http://apt.kubernetes.io kubernetes-xenial/main amd64 Packages
      1.9.6-00 500
         500 http://apt.kubernetes.io kubernetes-xenial/main amd64 Packages
      1.9.5-00 500
         [..]
 #

Then you can specify the release like::

 # apt-get install -y kubelet=1.9.6-00 kubeadm=1.9.6-00 kubectl=1.9.6-00 kubernetes-cni

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

Get a kubeadm token on k8s-master::

 $ TOKEN=`sudo kubeadm token list | grep authentication | awk '{print $1}'`
 $ echo $TOKEN
 c3cf19.89e62945a88d7a91

If you cannot get a token, need to recreate with::

 $ sudo kubeadm token create

Get a discovery token on k8s-master::

 $ DISCOVERY_TOKEN=`openssl x509 -pubkey \
 -in /etc/kubernetes/pki/ca.crt | openssl rsa \
 -pubin -outform der 2>/dev/null | openssl dgst \
 -sha256 -hex | sed 's/^.* //'`
 $ echo $DISCOVERY_TOKEN
 b3bb83c24673649bf1909e9144929a64569b1a7988df97323a9a3449c3b4c1e6

Get an endpoint on k8s-master::

 $ ENDPOINT=`cat admin.conf | grep server | sed s@"    server: https://"@@`
 $ echo $ENDPOINT
 192.168.1.105:6443

Use the token and the discovery token on k8s-node to add a new node on the node::

 # TOKEN=c3cf19.89e62945a88d7a91
 # DISCOVERY_TOKEN=b3bb83c24673649bf1909e9144929a64569b1a7988df97323a9a3449c3b4c1e6
 # ENDPOINT=192.168.1.105:6443
 #
 # kubeadm join --token ${TOKEN} ${ENDPOINT} \
 --discovery-token-ca-cert-hash sha256:${DISCOVERY_TOKEN}

Enable metrics-server for HPA
-----------------------------

Install metrics-server on k8s-master::

 $ git clone https://github.com/kubernetes-incubator/metrics-server
 $ cd metrics-server/
 $ vi deploy/1.8+/metrics-server-deployment.yaml
 $ git diff
 diff --git a/deploy/1.8+/metrics-server-deployment.yaml b/deploy/1.8+/metrics-server-deployment.yaml
 index 2196866..8477bce 100644
 --- a/deploy/1.8+/metrics-server-deployment.yaml
 +++ b/deploy/1.8+/metrics-server-deployment.yaml
 @@ -34,4 +34,8 @@ spec:
          volumeMounts:
          - name: tmp-dir
            mountPath: /tmp
 +        command:
 +        - /metrics-server
 +        - --kubelet-insecure-tls
 +        - --kubelet-preferred-address-types=InternalIP

 $ kubectl create -f deploy/1.8+/

Integrate standalone-cinder of the external cloud-provider-openstack for Dynamic Volume Provisioning
----------------------------------------------------------------------------------------------------

NOTE: It is not necessary to add options (--cloud-provider, --cloud-config) to kube-controller-manager and other processes at all.

Use manifests as samples from https://github.com/oomichi/try-kubernetes/tree/master/manifests/standalone-cinder-external

Add RBAC for standalone-cinder deployment::

 $ kubectl create -f rbac.yaml

Change hostAliases, OS_AUTH_URL and other OS_*** env values of deployment.yaml for your environment.

Deploy standalone-cinder::

 $ kubectl create -f deployment.yaml

Add default StorageClass::

 $ kubectl create -f storage-class.yaml

Verify Dynamic Volume Provisioning works fine::

 $ kubectl create -f pvc.yaml
 $ kubectl get pvc
 NAME           STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
 cinder-claim   Bound     pvc-af01ada4-9cf4-11e8-a146-fa163e420595   1Gi        RWO            gold           31s
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

Need to install golang 1.10.2 which is not provided from ubuntu 16.04 as the
default. So we need to do the following process for that::

 $ wget https://dl.google.com/go/go1.10.3.linux-amd64.tar.gz
 $ sudo tar -C /usr/local/ -xzf go1.10.3.linux-amd64.tar.gz
 $ export PATH=$PATH:/usr/local/go/bin
 $ echo "export PATH=$PATH:/usr/local/go/bin" >> $HOME/.bashrc

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

Check out the same version as the target k8s cluster::

 $ cd $GOPATH/src/k8s.io/kubernetes
 $ kubectl version
 Client Version: version.Info{
   Major:"1", Minor:"11", GitVersion:"v1.11.1",
   GitCommit:"b1b29978270dc22fecc592ac55d903350454310a",
   GitTreeState:"clean", BuildDate:"2018-07-17T18:53:20Z", GoVersion:"go1.10.3", Compiler:"gc", Platform:"linux/amd64"}
 Server Version: version.Info{Major:"1", Minor:"11", GitVersion:"v1.11.1",
   GitCommit:"b1b29978270dc22fecc592ac55d903350454310a",
   GitTreeState:"clean", BuildDate:"2018-07-17T18:43:26Z", GoVersion:"go1.10.3", Compiler:"gc", Platform:"linux/amd64"}
 $
 $ git tag -l
 v0.10.0
 ..
 v1.11.1
 ..
 $
 $ git checkout refs/tags/v1.11.1
 $ git checkout -b tag-v1.11.1

Build e2e test binary.
(NOTE: When changing the e2e code, we need to build the binary again to apply the changes)::

 # The docker daemon runs as root user, not docker user. So it is necessary to specify `su`
 $ sudo /usr/local/go/bin/go  run hack/e2e.go -- --build

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

 $ go run hack/e2e.go -- --test --test_args="--ginkgo.dryRun=true --ginkgo.focus=\[Conformance\]"
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

Specify a single test with regex::

 $ go run hack/e2e.go -- --provider=skeleton --test --test_args="--ginkgo.focus=1\spod\sto\s2\spods"

If changing e2e code, we need to specify --check-version-skew=false to skip checking versions of both server and e2e client::

 $ go run hack/e2e.go -- --provider=skeleton --test --test_args="--ginkgo.focus=from\s3\sto\s5$" --check-version-skew=false

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

Helm & Spinnaker
================

Install Helm
------------

As https://github.com/kubernetes/helm#install ::

 $ wget https://storage.googleapis.com/kubernetes-helm/helm-v2.9.1-linux-amd64.tar.gz
 $ tar -zxvf helm-v2.9.1-linux-amd64.tar.gz
 $ sudo mv linux-amd64/helm /usr/local/bin/
 $ helm init

Verify helm::

 $ helm version
 Client: &version.Version{SemVer:"v2.9.1", GitCommit:"20adb27c7c5868466912eebdf6664e7390ebe710", GitTreeState:"clean"}
 Server: &version.Version{SemVer:"v2.9.1", GitCommit:"20adb27c7c5868466912eebdf6664e7390ebe710", GitTreeState:"clean"}
 $

Add permission to deploy tiller::

 $ kubectl create serviceaccount --namespace kube-system tiller
 $ kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
 $ kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'

Install Spinnaker
-----------------

Install Spinnaker::

 $ wget https://raw.githubusercontent.com/kubernetes/charts/master/stable/spinnaker/values.yaml
 $ helm install -n kubelive -f values.yaml stable/spinnaker
 Error: timed out waiting for the condition
 $
 $ helm ls --all kubelive
 NAME            REVISION        UPDATED                         STATUS  CHART           NAMESPACE
 kubelive        1               Tue May 15 21:36:52 2018        FAILED  spinnaker-0.4.1 default
 $
 $ kubectl get pods
 NAME                                              READY     STATUS             RESTARTS   AGE
 kubelive-create-bucket-j97wn                      0/1       CrashLoopBackOff   5          10m
 kubelive-jenkins-86bcb6c4b5-h4bqx                 0/1       Pending            0          10m
 kubelive-minio-5d78b95d9c-pkpss                   0/1       Pending            0          10m
 kubelive-redis-5667b84965-k4nmz                   0/1       Pending            0          10m
 kubelive-spinnaker-clouddriver-85997f4b64-q97qq   0/1       Running            0          10m
 kubelive-spinnaker-deck-86c48f7594-vxmnt          1/1       Running            0          10m
 kubelive-spinnaker-echo-8ccc9956c-prk58           1/1       Running            0          10m
 kubelive-spinnaker-front50-6859bf64bb-cn9bd       0/1       CrashLoopBackOff   6          10m
 kubelive-spinnaker-gate-5468cccbc7-n2ncw          0/1       CrashLoopBackOff   6          10m
 $
 $ kubectl logs kubelive-create-bucket-j97wn
 mc: <ERROR> Unable to initialize new config from the provided credentials.
 Get http://kubelive-minio:9000/probe-bucket-sign/?location=: dial tcp: lookup kubelive-minio on 10.96.0.10:53: no such host
 $

Operate something
=================

Sort instances with --sort-by
-----------------------------

Easy one::

 $ kubectl get pods -n=default
 NAME       READY     STATUS    RESTARTS   AGE
 pod-00     1/1       Running   0          51s
 pod-01     1/1       Running   0          1m
 pod-name   1/1       Running   0          18m
 $
 $ kubectl get pods --sort-by=.status.startTime -n=default
 NAME       READY     STATUS    RESTARTS   AGE
 pod-name   1/1       Running   0          18m
 pod-01     1/1       Running   0          55s
 pod-00     1/1       Running   0          42s
 $
 $ kubectl get pods --sort-by=.metadata.name -n=default
 NAME       READY     STATUS    RESTARTS   AGE
 pod-00     1/1       Running   0          2m
 pod-01     1/1       Running   0          2m
 pod-name   1/1       Running   0          20m
 $

Create a pod
------------

Easy one::

 $ kubectl create -f manifests/pod-01.yaml

Create a pod with some changes by edit without any chages of the original manifest file::

 $ kubectl create -f manifests/pod-01.yaml --edit -o json

Create a deployment
-------------------

Create a deployment with external network access::

 $ kubectl run nginx --image nginx --replicas=3
 $ kubectl expose deployment nginx --port=80 --target-port=80
 $ kubectl create -f manifests/ingress-nginx.yaml
 $ kubectl describe ingress
 Name:             test-ingress
 Namespace:        default
 Address:
 Default backend:  nginx:80 (10.244.0.25:80,10.244.0.26:80,10.244.0.27:80)
 Rules:
   Host  Path  Backends
   ----  ----  --------
   *     *     nginx:80 (10.244.0.25:80,10.244.0.26:80,10.244.0.27:80)
 Annotations:
 Events:
   Type    Reason  Age   From                      Message
   ----    ------  ----  ----                      -------
   Normal  CREATE  17s   nginx-ingress-controller  Ingress default/test-ingress
 $

On this environment, ingress-nginx-controller is used and the setting is::

 $ kubectl get services -n ingress-nginx
 NAME                   TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
 default-http-backend   ClusterIP   10.102.0.178     <none>        80/TCP                       2h
 ingress-nginx          NodePort    10.101.145.191   <none>        80:31454/TCP,443:31839/TCP   2h
 $

So NodePort is configured and the host's 31454/TCP is proxied to 80/TCP of the ingress.
You can get nginx page like::

 $ curl http://localhost:31454
 <!DOCTYPE html>
 <html>
 <head>
 <title>Welcome to nginx!</title>
 ..

Create a snapshot of etcd
-------------------------

On this environment, etcd is running as a pod on kube-system namespace::

 $ kubectl get pods -n kube-system
 NAME                                              READY     STATUS    RESTARTS   AGE
 etcd-k8s-v109-flannel-master                      1/1       Running   0          1d
 ..
 $

The manifest is /etc/kubernetes/manifests/etcd.yaml and we can see the endpoint (http://127.0.0.1:2379) in this case::

 $ sudo cat /etc/kubernetes/manifests/etcd.yaml
 ..
   - command:
     - etcd
     - --data-dir=/var/lib/etcd
     - --listen-client-urls=http://127.0.0.1:2379
     - --advertise-client-urls=http://127.0.0.1:2379
 ..

Install etcdctl command (The ubuntu package is too old and doesn't support the snapshot feature)::

 $ mkdir foo
 $ cd foo
 $ wget https://github.com/coreos/etcd/releases/download/v3.2.18/etcd-v3.2.18-linux-amd64.tar.gz
 $ tar -zxvf etcd-v3.2.18-linux-amd64.tar.gz
 $ cd etcd-v3.2.18-linux-amd64

Create a snapshot::

 $ ETCDCTL_API=3 ./etcdctl --endpoints http://127.0.0.1:2379 snapshot save snapshot.db
 Snapshot saved at snapshot.db
 $

Make a node tainted and pods go away from the node
--------------------------------------------------

Check pods where live and the node::

 $ kubectl get pods -o wide
 NAME                         READY     STATUS    RESTARTS   AGE       IP            NODE
 nginx-foo-74cd78d68f-4jwsq   1/1       Running   0          1m        10.244.0.30   k8s-v109-flannel-master
 nginx-foo-74cd78d68f-5jl55   1/1       Running   0          1m        10.244.1.7    k8s-v109-flannel-worker
 nginx-foo-74cd78d68f-9cts2   1/1       Running   0          1m        10.244.1.5    k8s-v109-flannel-worker
 nginx-foo-74cd78d68f-9gtwx   1/1       Running   0          1m        10.244.1.6    k8s-v109-flannel-worker
 nginx-foo-74cd78d68f-b7zmx   1/1       Running   0          1m        10.244.1.4    k8s-v109-flannel-worker
 nginx-foo-74cd78d68f-d97pw   1/1       Running   0          1m        10.244.0.29   k8s-v109-flannel-master
 nginx-foo-74cd78d68f-j27qf   1/1       Running   0          1m        10.244.0.28   k8s-v109-flannel-master
 nginx-foo-74cd78d68f-j45c8   1/1       Running   0          1m        10.244.1.2    k8s-v109-flannel-worker
 nginx-foo-74cd78d68f-l4mwq   1/1       Running   0          1m        10.244.0.31   k8s-v109-flannel-master
 nginx-foo-74cd78d68f-wnb4c   1/1       Running   0          1m        10.244.1.3    k8s-v109-flannel-worker
 $
 $ kubectl describe node k8s-v109-flannel-worker | grep Taints
 Taints:             <none>
 $

Even if making the node tainted with NoSchedule, the pods still exist in the node::

 $ kubectl taint nodes k8s-v109-flannel-worker key=value:NoSchedule
 node "k8s-v109-flannel-worker" tainted
 $ kubectl describe node k8s-v109-flannel-worker | grep Taints
 Taints:             key=value:NoSchedule
 $
 $ kubectl get pods -o wide
 NAME                         READY     STATUS    RESTARTS   AGE       IP            NODE
 nginx-foo-74cd78d68f-4jwsq   1/1       Running   0          5m        10.244.0.30   k8s-v109-flannel-master
 nginx-foo-74cd78d68f-5jl55   1/1       Running   0          5m        10.244.1.7    k8s-v109-flannel-worker
 nginx-foo-74cd78d68f-9cts2   1/1       Running   0          5m        10.244.1.5    k8s-v109-flannel-worker
 nginx-foo-74cd78d68f-9gtwx   1/1       Running   0          5m        10.244.1.6    k8s-v109-flannel-worker
 nginx-foo-74cd78d68f-b7zmx   1/1       Running   0          5m        10.244.1.4    k8s-v109-flannel-worker
 nginx-foo-74cd78d68f-d97pw   1/1       Running   0          5m        10.244.0.29   k8s-v109-flannel-master
 nginx-foo-74cd78d68f-j27qf   1/1       Running   0          5m        10.244.0.28   k8s-v109-flannel-master
 nginx-foo-74cd78d68f-j45c8   1/1       Running   0          5m        10.244.1.2    k8s-v109-flannel-worker
 nginx-foo-74cd78d68f-l4mwq   1/1       Running   0          5m        10.244.0.31   k8s-v109-flannel-master
 nginx-foo-74cd78d68f-wnb4c   1/1       Running   0          5m        10.244.1.3    k8s-v109-flannel-worker
 $

After making the node tainted with NoExecute, the pods go away from the node::

 $ kubectl taint nodes k8s-v109-flannel-worker key=value:NoExecute
 node "k8s-v109-flannel-worker" tainted
 $ kubectl describe node k8s-v109-flannel-worker | grep Taints
 Taints:             key=value:NoExecute
 $ kubectl get pods -o wide
 NAME                         READY     STATUS    RESTARTS   AGE       IP            NODE
 nginx-foo-74cd78d68f-48q4p   1/1       Running   0          17s       10.244.0.37   k8s-v109-flannel-master
 nginx-foo-74cd78d68f-4jwsq   1/1       Running   0          8m        10.244.0.30   k8s-v109-flannel-master
 nginx-foo-74cd78d68f-9q6f8   1/1       Running   0          17s       10.244.0.34   k8s-v109-flannel-master
 nginx-foo-74cd78d68f-d97pw   1/1       Running   0          8m        10.244.0.29   k8s-v109-flannel-master
 nginx-foo-74cd78d68f-j27qf   1/1       Running   0          8m        10.244.0.28   k8s-v109-flannel-master
 nginx-foo-74cd78d68f-jlxng   1/1       Running   0          17s       10.244.0.36   k8s-v109-flannel-master
 nginx-foo-74cd78d68f-k5rl9   1/1       Running   0          17s       10.244.0.32   k8s-v109-flannel-master
 nginx-foo-74cd78d68f-l4mwq   1/1       Running   0          8m        10.244.0.31   k8s-v109-flannel-master
 nginx-foo-74cd78d68f-sg52l   1/1       Running   0          17s       10.244.0.33   k8s-v109-flannel-master
 nginx-foo-74cd78d68f-vzspf   1/1       Running   0          17s       10.244.0.35   k8s-v109-flannel-master
 $

Remove the taint after this try::

 $ kubectl taint nodes k8s-v109-flannel-worker key-

Create a secret and use it from a pod
-------------------------------------

Encode a plain password with base64::

 $ echo -n "mypassword" | base64
 bXlwYXNzd29yZA==
 $

Create a secret::

 $ cat manifests/secret-01.yaml
 apiVersion: v1
 kind: Secret
 metadata:
   name: secret-01
 type: Opaque
 data:
   password: bXlwYXNzd29yZA==
 $
 $ kubectl create -f manifests/secret-01.yaml

Create a pod with the secret as a file::

 $ kubectl create -f manifests/pod-using-secret-as-file.yaml

Confirm the password in the pod::

 $ kubectl exec -it pod-using-secret-as-file /bin/bash
 (login the pod)
 #
 # ls /etc/foo/
 password
 # cat /etc/foo/password
 mypassword

Create a pod with the secret as a variable::

 $ kubectl create -f manifests/pod-using-secret-as-variable.yaml

Confirm the password in the pod::

 $ kubectl exec -it pod-using-secret-as-variable /bin/bash
 (login the pod)
 #
 # echo $SECRET_PASSWORD
 mypassword

Rolling-upgrade for a deployment
--------------------------------

Create a deployment with a little old nginx (v1.7.9)::

 $ kubectl create -f manifests/nginx-deployment.yaml
 $ kubectl describe deployment/nginx-deployment | grep Image
     Image:        nginx:1.7.9
 $

Check the strategy (in this case (the default), that is RollingUpdate and the upgrade happens immediately just after setting the image)::

 $ kubectl describe deployment/nginx-deployment | grep StrategyType
 StrategyType:           RollingUpdate
 $

Check the ReplicaSet name and the pod names::

 $ kubectl get rs
 NAME                          DESIRED   CURRENT   READY     AGE
 nginx-deployment-75675f5897   3         3         3         6s
 $
 $ kubectl get pods
 NAME                                READY     STATUS    RESTARTS   AGE
 nginx-deployment-75675f5897-9mhmv   1/1       Running   0          36s
 nginx-deployment-75675f5897-kpgtr   1/1       Running   0          36s
 nginx-deployment-75675f5897-plq92   1/1       Running   0          36s
 $

Set a newer nginx image (v1.9.1)::

 $ kubectl set image deployment/nginx-deployment nginx=nginx:1.9.1
 $ kubectl describe deployment/nginx-deployment | grep Image
     Image:        nginx:1.9.1
 $

Then check the status of the upgrade::

 $ kubectl rollout status deployment/nginx-deployment
 Waiting for rollout to finish: 1 out of 3 new replicas have been updated...
 Waiting for rollout to finish: 1 out of 3 new replicas have been updated...
 Waiting for rollout to finish: 1 out of 3 new replicas have been updated...
 Waiting for rollout to finish: 2 out of 3 new replicas have been updated...
 Waiting for rollout to finish: 2 out of 3 new replicas have been updated...
 Waiting for rollout to finish: 2 old replicas are pending termination...
 Waiting for rollout to finish: 1 old replicas are pending termination...
 Waiting for rollout to finish: 1 old replicas are pending termination...
 deployment "nginx-deployment" successfully rolled out
 $

Conform new created ReplicaSet and pods. The old ReplicaSet doesn't have
any pods now and new pods only exist::

 $ kubectl get rs
 NAME                          DESIRED   CURRENT   READY     AGE
 nginx-deployment-75675f5897   0         0         0         3m
 nginx-deployment-c4747d96c    3         3         3         1m
 $
 $ kubectl get pods
 NAME                               READY     STATUS    RESTARTS   AGE
 nginx-deployment-c4747d96c-fbsw6   1/1       Running   0          2m
 nginx-deployment-c4747d96c-gvqg2   1/1       Running   0          1m
 nginx-deployment-c4747d96c-jfvvl   1/1       Running   0          1m
 $


Rolling-back of a deployment
----------------------------

Check the history of a deployment::

 $ kubectl rollout history deployment/nginx-deployment
 deployments "nginx-deployment"
 REVISION  CHANGE-CAUSE
 1         <none>
 2         <none>
 $

Show the detail of each revision::

 $ kubectl rollout history deployment/nginx-deployment --revision=2
 deployments "nginx-deployment" with revision #2
 Pod Template:
  Labels:       app=nginx
        pod-template-hash=1520898311
  Containers:
   nginx:
    Image:      nginx:1.9.1
    Port:       80/TCP
    Environment:        <none>
    Mounts:     <none>
  Volumes:      <none>

 $
 $ kubectl rollout history deployment/nginx-deployment --revision=1
 deployments "nginx-deployment" with revision #1
 Pod Template:
  Labels:       app=nginx
        pod-template-hash=2710681425
  Containers:
   nginx:
    Image:      nginx:1.7.9
    Port:       80/TCP
    Environment:        <none>
    Mounts:     <none>
  Volumes:      <none>

 $

Rolling-back the deployment::

 $ kubectl rollout undo deployment/nginx-deployment

Confirm the rolling-back succeeded::

 $ kubectl rollout history deployment/nginx-deployment
 deployments "nginx-deployment"
 REVISION  CHANGE-CAUSE
 2         <none>
 3         <none>
 $ kubectl rollout history deployment/nginx-deployment --revision=3
 deployments "nginx-deployment" with revision #3
 Pod Template:
   Labels:       app=nginx
         pod-template-hash=2710681425
   Containers:
    nginx:
     Image:      nginx:1.7.9
     Port:       80/TCP
     Environment:        <none>
     Mounts:     <none>
   Volumes:      <none>

 $
 $ kubectl describe deployment/nginx-deployment | grep Image
     Image:        nginx:1.7.9
 $

Verify DNS works for Services and Pods
--------------------------------------

https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/

Check what service works on the cluster::

 $ kubectl get services
 NAME               TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
 kubernetes         ClusterIP   10.96.0.1     <none>        443/TCP   2d
 nginx-deployment   ClusterIP   10.99.52.90   <none>        80/TCP    24s
 $

Create a pod for verifying DNS works::

 $ kubectl create -f manifests/pod-busybox.yaml
 $ kubectl exec -it pod-busybox sh
 (login the pod)
 wget http://nginx-deployment
 Connecting to nginx-deployment (10.99.52.90:80)
 index.html           100% |********************************************************************************************************************************************|   612   0:00:00 ETA
 / # cat index.html
 <!DOCTYPE html>
 <html>
 <head>
 <title>Welcome to nginx!</title>
 ..
 #

As the above, DNS works fine and the service nginx-deployment can be looked up from a pod as the same name.

A pod also can be looked up by "pod-ip-address.my-namespace.pod.cluster.local" like::

 $ kubectl get pods -o wide
 NAME                                READY     STATUS    RESTARTS   AGE       IP            NODE
 pod-01                              1/1       Running   0          19m       10.244.0.48   k8s-v109-flannel-master
 $ kubectl exec -it pod-busybox sh
 / #
 / # ping 10-244-0-48.default.pod.cluster.local
 PING 10-244-0-48.default.pod.cluster.local (10.244.0.48): 56 data bytes
 64 bytes from 10.244.0.48: seq=0 ttl=64 time=0.033 ms
 64 bytes from 10.244.0.48: seq=1 ttl=64 time=0.064 ms

Use init-containers
-------------------

https://kubernetes.io/docs/concepts/workloads/pods/init-containers/

Create a pod with init-containers::

 $ kubectl create -f manifests/pod-init-container.yaml

Check the pod status, it waits for end of init process::

 $ kubectl get pods
 NAME                                READY     STATUS     RESTARTS   AGE
 pod-init-container                  0/1       Init:0/2   0          30s
 $

Check logs of each containers, init-containers start on the order of the manifest. That means 2nd init-container also wait for 1st one's finishes::

 $ kubectl logs pod-init-container -c myapp-container
 Error from server (BadRequest): container "myapp-container" in pod "pod-init-container" is waiting to start: PodInitializing
 $
 $ kubectl logs pod-init-container -c init-myservice
 waiting for myservice
 nslookup: can't resolve 'myservice'
 Server:    10.96.0.10
 Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

 waiting for myservice
 nslookup: can't resolve 'myservice'
 Server:    10.96.0.10
 Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

 waiting for myservice
 $
 $ kubectl logs pod-init-container -c init-mydb
 Error from server (BadRequest): container "init-mydb" in pod "pod-init-container" is waiting to start: PodInitializing
 $

Create services for making end of init process::

 $ kubectl create -f manifests/services-for-init-containers.yaml
 service "myservice" created
 service "mydb" created
 $
 $ kubectl get pods
 NAME                                READY     STATUS            RESTARTS   AGE
 pod-init-container                  0/1       PodInitializing   0          4m
 $
 $ kubectl get pods
 NAME                                READY     STATUS    RESTARTS   AGE
 pod-init-container                  1/1       Running   0          5m
 $

Then the pod outputs the message to show the end as its command in the manifest::

 $ kubectl logs pod-init-container
 The app is running!
 $

Create a DaemonSet
------------------

Create a daemonset::

 $ kubectl create -f manifests/daemonset.yaml

Check the existence::

 $ kubectl get ds -n kube-system
 NAME                    DESIRED   CURRENT   READY     UP-TO-DATE   AVAILABLE   NODE SELECTOR                   AGE
 fluentd-elasticsearch   1         1         1         1            1           <none>                          1m
 ..
 $

Troubleshooting
===============

(Non-recommended way) Enforce kubelet boot on an environment with swap::

 $ sudo diff -u /etc/systemd/system/kubelet.service.d/10-kubeadm.conf.orig /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
 sudo: unable to resolve host k8s-v109-flannel-worker
 --- /etc/systemd/system/kubelet.service.d/10-kubeadm.conf.orig  2018-04-05 21:28:10.278748887 +0000
 +++ /etc/systemd/system/kubelet.service.d/10-kubeadm.conf       2018-04-05 21:32:14.191449307 +0000
 @@ -6,5 +6,6 @@
  Environment="KUBELET_AUTHZ_ARGS=--authorization-mode=Webhook --client-ca-file=/etc/kubernetes/pki/ca.crt"
  Environment="KUBELET_CADVISOR_ARGS=--cadvisor-port=0"
  Environment="KUBELET_CERTIFICATE_ARGS=--rotate-certificates=true --cert-dir=/var/lib/kubelet/pki"
 +Environment="KUBELET_SWAP_ARGS=--fail-swap-on=false"
  ExecStart=
 -ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_SYSTEM_PODS_ARGS $KUBELET_NETWORK_ARGS $KUBELET_DNS_ARGS $KUBELET_AUTHZ_ARGS $KUBELET_CADVISOR_ARGS $KUBELET_CERTIFICATE_ARGS $KUBELET_EXTRA_ARGS
 +ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_SYSTEM_PODS_ARGS $KUBELET_NETWORK_ARGS $KUBELET_DNS_ARGS $KUBELET_AUTHZ_ARGS $KUBELET_CADVISOR_ARGS $KUBELET_CERTIFICATE_ARGS $KUBELET_EXTRA_ARGS $KUBELET_SWAP_ARGS
 $
 $ sudo reboot

Swapoff on lxcfs (lxcfs is a simple file system to implement nest-cgroup
for systemd environments which are defact init of Linux kernel today)::

 $ diff -u /usr/share/lxcfs/lxc.mount.hook.orig /usr/share/lxcfs/lxc.mount.hook
 --- /usr/share/lxcfs/lxc.mount.hook.orig        2018-04-05 21:55:21.626302043 +0000
 +++ /usr/share/lxcfs/lxc.mount.hook     2018-04-05 21:57:05.956673664 +0000
 @@ -7,6 +7,7 @@
  if [ -d /var/lib/lxcfs/proc/ ]; then
      for entry in /var/lib/lxcfs/proc/*; do
          [ -e "${LXC_ROOTFS_MOUNT}/proc/$(basename $entry)" ] || continue
 +        [ $entry != "swap" ] || continue
          mount -n --bind $entry ${LXC_ROOTFS_MOUNT}/proc/$(basename $entry)
      done
  fi
