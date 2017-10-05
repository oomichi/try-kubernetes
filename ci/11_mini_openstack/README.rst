Minimum OpenStack
=================

Overview
--------

This doc explains how to install minimum OpenStack on ubuntu 16.04.
The release of OpenStack is Pike which is the latest at this time.
The minimum services are Keystone, Glance, Nova and Neutron only.

All nodes
---------

Change hostname by changing /etc/hostname and /etc/hosts on each node::

 $ sudo vi /etc/hostname
 $ sudo vi /etc/hosts
 $ sync
 $ sudo reboot

Operate the following commands on all OpenStack nodes to enable the Pike version::

 $ sudo apt-get -y install software-properties-common
 $ sudo add-apt-repository cloud-archive:pike
 $ sudo apt-get update
 $ sudo apt-get -y dist-upgrade

Keystone installation on controller node
----------------------------------------

Install packages for Keystone::

 $ sudo apt-get -y install mariadb-server python-pymysql
 $ sudo mysql
 > CREATE DATABASE keystone;
 > GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'KEYSTONE_DBPASS';
 > GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'KEYSTONE_DBPASS';
 $ sudo apt-get -y install vim keystone apache2 libapache2-mod-wsgi

Confirm the Pike release of Keystone is installed::

 $ keystone-manage --version
 12.0.0
 $

Edit configuration file::

 $ sudo vi
 - connection = sqlite:////var/lib/keystone/keystone.db
 + connection = mysql+pymysql://keystone:KEYSTONE_DBPASS@localhost/keystone
 [..]
 - #provider = fernet
 + provider = fernet

Initialize Keystone service::

 $ sudo su -
 # su -s /bin/sh -c "keystone-manage db_sync" keystone
 # keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
 # keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
 # keystone-manage bootstrap --bootstrap-password ADMIN_PASS \
 --bootstrap-admin-url http://openstack-controller:35357/v3/ \
 --bootstrap-internal-url http://openstack-controller:5000/v3/ \
 --bootstrap-public-url http://openstack-controller:5000/v3/ \
 --bootstrap-region-id RegionOne
 #
 # vi /etc/apache2/sites-available/000-default.conf
 -         #ServerName www.example.com
 +         #ServerName openstack-controller
 # service apache2 restart

Configure management user and exit for re-login::

 $ echo "export OS_USERNAME=admin"      >> ~/.bashrc
 $ echo "export OS_PASSWORD=ADMIN_PASS" >> ~/.bashrc
 $ echo "export OS_PROJECT_NAME=admin"             >> ~/.bashrc
 $ echo "export OS_USER_DOMAIN_NAME=Default"       >> ~/.bashrc
 $ echo "export OS_PROJECT_DOMAIN_NAME=Default"    >> ~/.bashrc
 $ echo "export OS_AUTH_URL=http://openstack-controller:35357/v3" >> ~/.bashrc
 $ echo "export OS_IDENTITY_API_VERSION=3"                        >> ~/.bashrc
 $ exit

Create some projects, users and roles::

 $ openstack project create --domain default --description "Service Project" service
 $ openstack project create --domain default --description "Kubernetes Project" k8s
 $ openstack user create --domain default --password-prompt k8s
 $ openstack role create user
 $ openstack role add --project k8s --user k8s user

Check the installation::

 $ sudo apt-get -y install python-openstackclient
 $ openstack user list
 +----------------------------------+-------+
 | ID                               | Name  |
 +----------------------------------+-------+
 | 006786b32ecd4a009d1b4de7c636fb39 | admin |
 +----------------------------------+-------+

Glance installation on controller node
--------------------------------------

Configure Keystone for Glance::

 $ openstack user create --domain default --password GLANCE_PASS glance
 $ openstack role add --project service --user glance admin
 $ openstack service create --name glance --description "OpenStack Image" image
 $ openstack endpoint create --region RegionOne image public http://openstack-controller:9292
 $ openstack endpoint create --region RegionOne image internal http://openstack-controller:9292
 $ openstack endpoint create --region RegionOne image admin http://openstack-controller:9292
 
Install and configure Glance::

 $ sudo apt-get -y install glance

Edit /etc/glance/glance-api.conf::

 $ sudo vi /etc/glance/glance-api.conf
 - #connection = <None>
 + connection = mysql+pymysql://glance:GLANCE_DBPASS@openstack-controller/glance

 [..]

 [keystone_authtoken]
 + auth_uri = http://localhost:5000
 + auth_url = http://localhost:35357
 + memcached_servers = localhost:11211
 + auth_type = password
 + project_domain_name = default
 + user_domain_name = default
 + project_name = service
 + username = glance
 + password = GLANCE_PASS

 [..]

 - #flavor = keystone
 + flavor = keystone

 [..]

 - #stores = file,http
 - #default_store = file
 - #filesystem_store_datadir = /var/lib/glance/images
 + stores = file,http
 + default_store = file
 + filesystem_store_datadir = /var/lib/glance/images

Edit /etc/glance/glance-registry.conf::

 $ sudo vi /etc/glance/glance-registry.conf
 - #connection = <None>
 + connection = mysql+pymysql://glance:GLANCE_DBPASS@openstack-controller/glance

 [keystone_authtoken]
 + auth_uri = http://localhost:5000
 + auth_url = http://localhost:35357
 + memcached_servers = localhost:11211
 + auth_type = password
 + project_domain_name = default
 + user_domain_name = default
 + project_name = service
 + username = glance
 + password = GLANCE_PASS

 [..]

 - #flavor = keystone
 + flavor = keystone

DB sync::

 # mysql
 > CREATE DATABASE glance;
 > GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'GLANCE_DBPASS';
 > GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'GLANCE_DBPASS';
 > exit
 # su -s /bin/sh -c "glance-manage db_sync" glance

Nova installation on controller node
------------------------------------

Create database::

 # mysql
 > CREATE DATABASE nova_api;
 > CREATE DATABASE nova;
 > CREATE DATABASE nova_cell0;
 > GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY 'NOVA_DBPASS';
 > GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY 'NOVA_DBPASS';
 > GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'NOVA_DBPASS';
 > GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'NOVA_DBPASS';
 > GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost'IDENTIFIED BY 'NOVA_DBPASS';
 > GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY 'NOVA_DBPASS';
 > exit

Configure Keystone for Nova service::

 $ openstack user create --domain default --password NOVA_PASS nova
 $ openstack role add --project service --user nova admin
 $ openstack service create --name nova --description "OpenStack Compute" compute
 $ openstack endpoint create --region RegionOne compute public http://openstack-controller:8774/v2.1
 $ openstack endpoint create --region RegionOne compute internal http://openstack-controller:8774/v2.1
 $ openstack endpoint create --region RegionOne compute admin http://openstack-controller:8774/v2.1

Configure Keystone for Placement service::

 $ openstack user create --domain default --password PLACEMENT_PASS placement
 $ openstack role add --project service --user placement admin
 $ openstack service create --name placement --description "Placement API" placement
 $ openstack endpoint create --region RegionOne placement public http://openstack-controller:8778 
 $ openstack endpoint create --region RegionOne placement internal http://openstack-controller:8778 
 $ openstack endpoint create --region RegionOne placement admin http://openstack-controller:8778 

Install packages::

 $ sudo apt-get -y install nova-api nova-conductor nova-consoleauth nova-novncproxy nova-scheduler nova-placement-api

Edit /etc/nova/nova.conf::

 $ sudo vi /etc/nova/nova.conf
 [api_database]
 - connection = sqlite:////var/lib/nova/nova_api.sqlite
 + connection = mysql+pymysql://nova:NOVA_DBPASS@openstack-controller/nova_api

 [database]
 - connection = sqlite:////var/lib/nova/nova.sqlite
 + connection = mysql+pymysql://nova:NOVA_DBPASS@openstack-controller/nova

 [DEFAULT]
 - log_dir = /var/log/nova

 - #transport_url = <None>
 + transport_url = rabbit://openstack:RABBIT_PASS@openstack-controller

 - #auth_strategy = keystone
 + auth_strategy = keystone

 - #my_ip = <host_ipv4>
 + my_ip = 192.168.1.1    <<<<<<<<<NEED TO FIX THIS AFTER GETTING NIC>>>>>>>>>>>>>

 - # use_neutron = true
 + use_neutron = true

 - # firewall_driver = nova.virt.firewall.NoopFirewallDriver
 + firewall_driver = nova.virt.firewall.NoopFirewallDriver

 [keystone_authtoken]
 + auth_uri = http://localhost:5000
 + auth_url = http://localhost:35357
 + memcached_servers = localhost:11211
 + auth_type = password
 + project_domain_name = default
 + user_domain_name = default
 + project_name = service
 + username = nova
 + password = NOVA_PASS

 [vnc]
 - #enabled = true
 - #vncserver_listen = 127.0.0.1
 - #vncserver_proxyclient_address = 127.0.0.1
 + enabled = true
 + vncserver_listen = $my_ip
 + vncserver_proxyclient_address = $my_ip

 [glance]
 - #api_servers = <None>
 + api_servers = http://openstack-controller:9292

 [oslo_concurrency]
 - #lock_path = /tmp
 + lock_path = /var/lib/nova/tmp

 [placement]
 - os_region_name = openstack
 + os_region_name = RegionOne
 + project_domain_name = Default
 + project_name = service
 + auth_type = password
 + user_domain_name = Default
 + auth_url = http://openstack-controller:35357/v3
 + username = placement
 + password = PLACEMENT_PASS

Sync database::

 # su -s /bin/sh -c "nova-manage api_db sync" nova
 # su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
 # su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova
 # su -s /bin/sh -c "nova-manage db sync" nova

Configure rabbitmq::

 $ sudo apt-get -y install rabbitmq-server
 $ sudo rabbitmqctl add_user openstack RABBIT_PASS
 $ sudo rabbitmqctl set_permissions openstack ".*" ".*" ".*"

Configure memcached::

 $ sudo apt-get -y install memcached python-memcache
 $ sudo vi /etc/memcached.conf
 - -l 127.0.0.1
 + -l 192.168.1.1        <<<<<<<<<NEED TO FIX THIS AFTER GETTING NIC>>>>>>>>>>>>>

Confirm nova-api works fine::

 $ nova list

Neutron installation on controller node
---------------------------------------

Configure Keystone for Neutron service::

 $ openstack user create --domain default --password NEUTRON_PASS neutron
 $ openstack role add --project service --user neutron admin
 $ openstack service create --name neutron --description "OpenStack Networking" network
 $ openstack endpoint create --region RegionOne network public http://openstack-controller:9696
 $ openstack endpoint create --region RegionOne network internal http://openstack-controller:9696
 $ openstack endpoint create --region RegionOne network admin http://openstack-controller:9696

Install packages::

 $ sudo apt-get -y install neutron-server neutron-plugin-ml2 neutron-linuxbridge-agent neutron-dhcp-agent neutron-metadata-agent

Edit /etc/neutron/neutron.conf::

 $ sudo vi /etc/neutron/neutron.conf
 [database]
 - connection = sqlite:////var/lib/neutron/neutron.sqlite
 + connection = mysql+pymysql://neutron:NEUTRON_DBPASS@openstack-controller/neutron

 [DEFAULT]
 - #transport_url = <None>
 + transport_url = rabbit://openstack:RABBIT_PASS@openstack-controller

 [keystone_authtoken]
 + auth_uri = http://localhost:5000
 + auth_url = http://localhost:35357
 + memcached_servers = localhost:11211
 + auth_type = password
 + project_domain_name = default
 + user_domain_name = default
 + project_name = service
 + username = neutron
 + password = NEUTRON_PASS

 [nova]
 + auth_url = http://openstack-controller:35357
 + auth_type = password
 + project_domain_name = default
 + user_domain_name = default
 + region_name = RegionOne
 + project_name = service
 + username = nova
 + password = NOVA_PASS

Edit /etc/neutron/plugins/ml2/ml2_conf.ini::

 $ sudo vi /etc/neutron/plugins/ml2/ml2_conf.ini
 [ml2]
 + type_drivers = flat,vlan
 + tenant_network_types =
 + mechanism_drivers = linuxbridge
 + extension_drivers = port_security

 [ml2_type_flat]
 + flat_networks = provider

Edit /etc/neutron/plugins/ml2/linuxbridge_agent.ini::

 $ sudo vi /etc/neutron/plugins/ml2/linuxbridge_agent.ini
 [linux_bridge]
 + physical_interface_mappings = provider:PROVIDER_INTERFACE_NAME

 [vxlan]
 + enable_vxlan = false

 [securitygroup]
 + firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

Edit /etc/neutron/dhcp_agent.ini::

 $ sudo vi /etc/neutron/dhcp_agent.ini
 [DEFAULT]
 + interface_driver = linuxbridge
 + enable_isolated_metadata = true

Edit /etc/neutron/metadata_agent.ini::

 $ sudo vi /etc/neutron/metadata_agent.ini
 [DEFAULT]
 + nova_metadata_ip = openstack-controller
 + metadata_proxy_shared_secret = METADATA_SECRET

Edit /etc/nova/nova.conf::

 $ sudo vi /etc/nova/nova.conf
 [neutron]
 + url = http://openstack-controller:9696
 + auth_url = http://openstack-controller:35357
 + auth_type = password
 + project_domain_name = default
 + user_domain_name = default
 + region_name = RegionOne
 + project_name = service
 + username = neutron
 + password = NEUTRON_PASS
 + service_metadata_proxy = true
 + metadata_proxy_shared_secret = METADATA_SECRET

Sync database::

 # mysql
 > CREATE DATABASE neutron;
 > GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'NEUTRON_DBPASS';
 > GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'NEUTRON_DBPASS';
 > exit
 # su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
   --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

Restart and verify installation::

 $ sudo reboot
 [after rebooting..]

Nova installation on compute node
---------------------------------

Install package::

 $ sudo apt-get -y install nova-compute

Edit /etc/hosts::

 $ sudo vi /etc/hosts
 + 192.168.1.1  openstack-controller     <<<Edit here after getting nic>>>


Edit /etc/nova/nova.conf::

 [DEFAULT]
 - log_dir = /var/log/nova

 - #transport_url = <None>
 + transport_url = rabbit://openstack:RABBIT_PASS@openstack-controller

 - #my_ip = <host_ipv4>
 + my_ip = 192.168.1.2  <<Change here after local network>>

 [keystone_authtoken]
 + auth_uri = http://openstack-controller:5000
 + auth_url = http://openstack-controller:35357
 + memcached_servers = openstack-controller:11211
 + auth_type = password
 + project_domain_name = default
 + user_domain_name = default
 + project_name = service
 + username = nova
 + password = NOVA_PASS

 [vnc]
 + vncserver_listen = 0.0.0.0
 + vncserver_proxyclient_address = $my_ip
 + novncproxy_base_url = http://openstack-controller:6080/vnc_auto.html

 [glance]
 + api_servers = http://openstack-controller:9292

 [oslo_concurrency]
 + lock_path = /var/lib/nova/tmp

 [placement]
 + os_region_name = RegionOne
 + project_domain_name = Default
 + project_name = service
 + auth_type = password
 + user_domain_name = Default
 + auth_url = http://openstack-controller:35357/v3
 + username = placement
 + password = PLACEMENT_PASS

 [neutron]
 + url = http://openstack-controller:9696
 + auth_url = http://openstack-controller:35357
 + auth_type = password
 + project_domain_name = default
 + user_domain_name = default
 + region_name = RegionOne
 + project_name = service
 + username = neutron
 + password = NEUTRON_PASS

Some works for finalizing installation
--------------------------------------

Discover compute hosts by operating the following on controller node::

 # su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova

Add compute flavors::

 $ openstack --os-region-name="$REGION_NAME" flavor create --id 1 --ram 512 --disk 1 --vcpus 1 m1.tiny
 $ openstack --os-region-name="$REGION_NAME" flavor create --id 2 --ram 2048 --disk 20 --vcpus 1 m1.small
 $ openstack --os-region-name="$REGION_NAME" flavor create --id 3 --ram 4096 --disk 40 --vcpus 2 m1.medium
 $ openstack --os-region-name="$REGION_NAME" flavor create --id 4 --ram 8192 --disk 80 --vcpus 4 m1.large

Register virtual machine images::

 $ wget http://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img
 $ openstack image create --container-format bare --disk-format qcow2 \
   --file xenial-server-cloudimg-amd64-disk1.img Ubuntu-16.04-x86_64

Prepare to create a virtual machine::

 $ ssh-keygen -q -N ""
 $ openstack keypair create --public-key ~/.ssh/id_rsa.pub mykey
 $ openstack security group rule create --proto icmp default
 $ openstack security group rule create --proto tcp --dst-port 22 default
 $ openstack network create  --share --external --provider-physical-network provider --provider-network-type flat provider
 $ openstack subnet create --network provider \
   --allocation-pool start=192.168.100.100,end=192.168.100.250 \
   --dns-nameserver 8.8.4.4 --gateway 192.168.100.1 \
   --subnet-range 192.168.100.0/24 provider

Create a virtual machine::

 $ PROVIDER_NET_ID=`openstack network list | grep provider | awk '{print $2}'`
 $ openstack server create --flavor m1.tiny --image Ubuntu-16.04-x86_64 \
   --nic net-id=$PROVIDER_NET_ID --security-group default \
   --key-name mykey vm01
