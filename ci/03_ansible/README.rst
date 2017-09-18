Ansible
=======

Change hostname with `01_change_hostname.sh <IP address> <hostname>`::

 $ ./01_change_hostname.sh 192.168.0.1 k8s-master

Install basic packages::

 $ ansible-playbook -i ./hosts --ask-become-pass 02_install_packages.yaml

Initialize kube-master node::

 $ ansible-playbook -i ./hosts --ask-become-pass 03_initialize_k8s_master.yaml

