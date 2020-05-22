Kubespray
=========

Kubespray: Deploy a production ready Kubernetes cluster anywhere (AWS, GCE, Azure, OpenStack, vSphere, Baremetal) with HA

- It consists of Ansible-playbooks.
- Kubespray selects stable Kubernetes version as the default.
  For example, when the community is developing v1.19 on master branch, the default version is v1.17.x, not v1.18.x.(Ref: https://github.com/kubernetes-sigs/kubespray/pull/5967)

How to use Kubespray without IaaS layer feature
-----------------------------------------------

1. Specify IP addresses of nodes which will be consisted for Kubernetes cluster::

   $ export IPS_NODES=(192.168.1.100 192.168.1.101 192.168.1.102)

2. Run the script::

   $ run-kubespray.sh

How to use Kubespray on Azure
-----------------------------

1. Install Azuru-cli (az command) of Python 3.
   This is a workaround to avoid errors when using the one of Python 2 version.
   Please continue all following steps in the same shell console to use Azuru-cli (az command) of Python 3::

   $ sudo pip install virtualenv
   $ mkdir venv-python3
   $ which python3
   $ cd venv-python3
   $ virtualenv -p /usr/bin/python3.6 .
   $ source ./bin/activate
   $ sudo apt install python3-dev
   $ pip install azure-cli
   $ az --version
   (Confirm azure-cli works under Python 3)
   azure-cli                          2.5.1
   ..
   Python (Linux) 3.6.9 (default, Apr 18 2020, 01:56:04)
   ..
   $

2. Install necessary packages::

   $ git clone https://github.com/kubernetes-sigs/kubespray
   $ cd kubespray/
   $ pip install -r requirements.txt

3. Create a resource group on Azure.
   Specify your own values instead of kubespray-rg (resource group name), "Test Subscription" (subscription name)::

   $ az group create -n kubespray-rg -l centralus --subscription "Test Subscription"

4. Configure inventory file.
   Specify your own values on the following changes except "cloud_provider: azure"::

   --- inventory/sample/group_vars/all/all.yml     2020-04-20 18:08:27.902475729 +0000
   +++ inventory/mycluster/group_vars/all/all.yml  2020-04-21 00:50:10.079428761 +0000
   @@ -51,7 +51,7 @@
    ## If set the possible values are either 'gce', 'aws', 'azure', 'openstack', 'vsphere', 'oci', or 'external'
    ## When openstack is used make sure to source in the openstack credentials
    ## like you would do when using openstack-client before starting the playbook.
   -# cloud_provider:
   +cloud_provider: azure

    ## When cloud_provider is set to 'external', you can set the cloud controller to deploy
    ## Supported cloud controllers are: 'openstack' and 'vsphere'
   @@ -96,3 +96,20 @@
    ## Set Pypi repo and cert accordingly
    # pyrepo_index: https://pypi.example.com/simple
    # pyrepo_cert: /etc/ssl/certs/ca-certificates.crt
   +
   +azure_tenant_id: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   +azure_subscription_id: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   +azure_location: centralus
   +azure_resource_group: kubespray-rg
   +azure_vmtype: standard
   +azure_add_client_id: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   +azure_add_client_secret: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   +azure_loadbalancer_sku: basic
   +

5. Specify your ssh public key to access Azure virtual machines::

   --- a/contrib/azurerm/group_vars/all
   +++ b/contrib/azurerm/group_vars/all
   @@ -25,7 +25,7 @@ admin_password: changeme

    # MAKE SURE TO CHANGE THIS TO YOUR PUBLIC KEY to access your azure machines
    ssh_public_keys:
   - - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDLRzcxbsFDdEibiyXCSdIFh7bKbXso1NqlKjEyPTptf3aBXHEhVil0lJRjGpTlpfTy7PHvXFbXIOCdv9tOmeH1uxWDDeZawgPFV6VSZ1QneCL+8bxzhjiCn8133wBSPZkN8rbFKd9eEUUBfx8ipCblYblF9FcidylwtMt5TeEmXk8yRVkPiCuEYuDplhc2H0f4PsK3pFb5aDVdaDT3VeIypnOQZZoUxHWqm6ThyHrzLJd3SrZf+RROFWW1uInIDf/SZlXojczUYoffxgT1lERfOJCHJXsqbZWugbxQBwqsVsX59+KPxFFo6nV88h3UQr63wbFx52/MXkX4WrCkAHzN ablock-vwfs@dell-lappy"
   + - "ssh-rsa YOUR-PUBLIC-KEY"

    # Disable using ssh using password. Change it to false to allow to connect to ssh by password
    disablePasswordAuthentication: true

6. Specify virtual machine type if necessary::

   --- a/contrib/azurerm/group_vars/all
   +++ b/contrib/azurerm/group_vars/all
   @@ -14,10 +14,10 @@ use_bastion: false
    number_of_k8s_masters: 3
    number_of_k8s_nodes: 3

   -masters_vm_size: Standard_A2
   +masters_vm_size: Standard_F8s_v2
    masters_os_disk_size: 1000

   -minions_vm_size: Standard_A2
   +minions_vm_size: Standard_F8s_v2
    minions_os_disk_size: 1000

7. Create necessary resources (VMs, virtual network, etc.) on Azure with Azure Resource Group Templates::

   $ cd contrib/azurerm/
   $ ./apply-rg.sh kubespray-rg


8. Generate inventory of kubespray::

   $ ./generate-inventory.sh kubespray-rg

9. Run the ansible-playbook for deploying Kubernetes cluster on top of VMs which are created by step 7::

   $ cd ../..
   $ ansible-playbook -i contrib/azurerm/inventory -u devops --become -e "@inventory/sample/group_vars/all/all.yml" cluster.yml

10. Get kubeconf
    The kubeconfig is not for accessing to k8s cluster from outside.
    So it is necessary to login to the master node with ssh and run kubectl command::

   $ cat contrib/azurerm/inventory
   master-0 ansible_ssh_host=40.122.109.215 ip=10.0.4.6
   master-1 ansible_ssh_host=104.43.250.214 ip=10.0.4.5
   master-2 ansible_ssh_host=40.122.107.236 ip=10.0.4.4
   ...
   $ ssh devops@104.43.250.214
   $ sudo cp /etc/kubernetes/admin.conf $HOME/admin.conf
   $ sudo chown $(id -u):$(id -g) $HOME/admin.conf
   $ export KUBECONFIG=$HOME/admin.conf
   $ echo "export KUBECONFIG=$HOME/admin.conf" >> $HOME/.bashrc

