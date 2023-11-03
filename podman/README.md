Try podman
==========

Deploy pods
-----------

Deploy pods with podman command:
```
$ podman play kube ./test-svc.yaml
```
NOTE: Necessary to specify dockerhub registry cleary with `registry.hub.docker.com/library/` for nginx image.

Know avaiable options
---------------------

`podman pod` seems like `kubectl` for pod operation and the avaiable options are:

```
$ podman pod --help
Manage pods

Description:
  Pods are a group of one or more containers sharing the same network, pid and ipc namespaces.

Usage:
  podman pod [command]

Available Commands:
  create      Create a new empty pod
  exists      Check if a pod exists in local storage
  inspect     Displays a pod configuration
  kill        Send the specified signal or SIGKILL to containers in pod
  logs        Fetch logs for pod with one or more containers
  pause       Pause one or more pods
  prune       Remove all stopped pods and their containers
  ps          List pods
  restart     Restart one or more pods
  rm          Remove one or more pods
  start       Start one or more pods
  stats       Display a live stream of resource usage statistics for the containers in one or more pods
  stop        Stop one or more pods
  top         Display the running processes of containers in a pod
  unpause     Unpause one or more pods
```

Execute command in a container
------------------------------

Know the target container id:
```
$ podman ps
CONTAINER ID  IMAGE                                         COMMAND               CREATED        STATUS            PORTS       NAMES
738dc293a002  k8s.gcr.io/pause:3.5                                                8 minutes ago  Up 8 minutes ago              c4c9452b5920-infra
1878ba250072  docker.io/library/ubuntu:22.04                                      8 minutes ago  Up 8 minutes ago              test-svc-ubuntu-bash
9c86b26f0439  k8s.gcr.io/pause:3.5                                                8 minutes ago  Up 8 minutes ago              1572443da830-infra
5176dfe514f0  registry.hub.docker.com/library/nginx:latest  nginx -g daemon o...  8 minutes ago  Up 8 minutes ago
       test-svc-nginx-nginx
```

Specify the id with `podman exec` command:
```
$ podman exec -it 1878ba250072 ls
bin  boot  dev  etc  home  lib  lib32  lib64  libx32  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var
```

We can use bash like:
```
$ podman exec -it 1878ba250072 bash
root@test-svc-ubuntu:/# ls
bin  boot  dev  etc  home  lib  lib32  lib64  libx32  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var
root@test-svc-ubuntu:/# exit
exit
```

Cannot use Services of Kubernetes
---------------------------------

Necessary to put all containers in a single pod if they need to communicate each other.
Services of Kubernetes are not there.
```
$ podman play kube ./pods-and-svc.yaml
$ podman ps
CONTAINER ID  IMAGE                                         COMMAND               CREATED         STATUS             PORTS       NAMES
f38591a63947  k8s.gcr.io/pause:3.5                                                15 seconds ago  Up 15 seconds ago              5bfc6fbdfe2a-infra
539de6a73ba1  docker.io/library/ubuntu:22.04                                      15 seconds ago  Up 15 seconds ago              test-svc-bash
a38d558ca5ba  registry.hub.docker.com/library/nginx:latest  nginx -g daemon o...  15 seconds ago  Up 15 seconds ago              test-svc-nginx
$ podman exec -it 539de6a73ba1 bash
root@test-svc:/# apt update
root@test-svc:/# apt install curl
root@test-svc:/# curl localhost
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
root@test-svc:/#
```

Network communication between pods
----------------------------------

Need to specify the same network when deploying pods:
```
$ podman play kube --network podman ./shell.yaml
$ podman play kube --network podman ./pods-and-svc.yaml
```
Check IP address of nginx pod:
```
$ podman ps | grep nginx
4675e132974a  registry.hub.docker.com/library/nginx:latest  nginx -g daemon o...  39 minutes ago  Up 39 minutes ago              test-svc-nginx
$ podman inspect test-svc-nginx | jq -r ".[0].NetworkSettings.Networks.podman.IPAddress"
10.88.0.3
$
```
Access to nginx from a different container:
```
$ podman ps | grep bash
3c1758a60d3b  docker.io/library/ubuntu:22.04                                      41 minutes ago  Up 41 minutes ago              test-shell-bash
$
$ podman exec -it 3c1758a60d3b curl 10.88.0.3
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```
