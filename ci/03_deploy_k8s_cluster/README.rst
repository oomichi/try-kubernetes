Ansible
=======

Create hosts file::

 $ cat hosts
 [master]
 192.168.0.1
 [node]
 192.168.0.2

Install basic packages::

 $ ansible-playbook -i ./hosts --ask-become-pass 01_install_packages.yaml

Initialize kube-master node::

 $ ansible-playbook -i ./hosts --ask-become-pass 02_initialize_k8s_master.yaml

Initialize kube-node node::

 $ ansible-playbook -i ./hosts --ask-become-pass 03_initialize_k8s_node.yaml

