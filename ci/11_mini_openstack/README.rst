.. contents:: Contents
    :depth: 4

Minimum OpenStack
=================

Overview
--------

This doc explains how to install minimum OpenStack on Ubuntu 20.04LTS.
The release of OpenStack is Victoria which is the latest at this time.
The minimum services are Keystone, Glance, Nova, Cinder and Neutron only.

All nodes
---------

Change hostname by changing /etc/hostname and /etc/hosts on each node::

 $ sudo vi /etc/hostname
 $ sudo vi /etc/hosts
 $ sync
 $ sudo reboot

NOTE: Necessary to change /etc/hosts of iaas-ctrl like the following because mysql server listens 127.0.0.1:3306::

 $ sudo vi /etc/hosts
 - 127.0.0.1 localhost
 - 127.0.1.1 iaas-ctrl
 + 127.0.0.1 localhost iaas-ctrl

Operate the following commands on all OpenStack nodes to enable the Victoria version::

 $ sudo add-apt-repository cloud-archive:victoria
 $ sudo apt-get update
 $ sudo apt-get -y dist-upgrade

Controller node
---------------

We can use ansible playbooks for the following operations::

 $ cd controller
 $ ansible-playbook 01_ctrl_network_config.yaml -i ../hosts --ask-become-pass
 $ ansible-playbook 02_dns_and_ntp.yaml -i ../hosts --ask-become-pass
 $ ansible-playbook 03_SNAT.yaml -i ../hosts --ask-become-pass
 $ ansible-playbook 04_dhcp.yaml -i ../hosts --ask-become-pass
 $ ansible-playbook 05_keystone.yaml -i ../hosts --ask-become-pass
 $ ansible-playbook 06_service_catalog.yaml -i ../hosts --ask-become-pass
 $ ansible-playbook 07_glance.yaml -i ../hosts --ask-become-pass
 $ ansible-playbook 08_nova.yaml -i ../hosts --ask-become-pass
 $ ansible-playbook 09_neutron.yaml -i ../hosts --ask-become-pass
 $ ansible-playbook 10_flavor_and_image.yaml -i ../hosts --ask-become-pass
 $ ansible-playbook 11_cinder.yaml -i ../hosts --ask-become-pass

Configure local (= OpenStack side) network interface, enp2s0 depends on envs(need to check unconfigured nic with `ifconfig -a`)::

 $ sudo vi /etc/netplan/60-localnet-init.yaml
 + network:
 +  version: 2
 +  ethernets:
 +    enp2s0:
 +     dhcp4: no
 +     addresses: [192.168.1.1/24]

Install and configure name server for local network::

 $ sudo apt-get -y install bind9
 $ sudo vi /etc/bind/named.conf.options
 options {
        directory "/var/cache/bind";

 +      listen-on port 53 { localhost; 192.168.1.0/24; };
 +      allow-query { localhost; 192.168.1.0/24; };
 +      recursion yes;

 $ sudo vi /etc/bind/named.conf

 - include "/etc/bind/named.conf.default-zones";
 + include "/etc/bind/named.conf.iaas-zones";

 $ sudo vi /etc/bind/named.conf.iaas-zones
 + zone "iaas.net" IN {
 +   type master;
 +   file "iaas.net.zone";
 + };

 $ sudo vi /var/cache/bind/iaas.net.zone
 + $TTL 86400
 + 
 + @ IN SOA iaas.net root.iaas.net (
 +   2016043008
 +   3600
 +   900
 +   604800
 +   86400
 + )
 +
 + @            IN NS iaas-ctrl
 + iaas-ctrl    IN A  192.168.1.1

 $ sudo systemctl enable bind9

Install and configure NTP server::

 $ sudo apt-get -y install chrony
 $ sudo vi /etc/chrony/chrony.conf
 + allow 192.168.1.0/24

Enable SNAT for connecting to the internet from local network machines::

 $ sudo apt-get install ufw
 $ sudo vi /etc/sysctl.conf
 # Uncomment the next line to enable packet forwarding for IPv4
 - #net.ipv4.ip_forward=1
 + net.ipv4.ip_forward=1

 $ sudo vi /etc/default/ufw
 - DEFAULT_INPUT_POLICY="DROP"
 + DEFAULT_INPUT_POLICY="ACCEPT"

 - DEFAULT_FORWARD_POLICY="DROP"
 + DEFAULT_FORWARD_POLICY="ACCEPT"

 $ sudo vi /etc/ufw/before.rules
 + # NAT table rules
 + *nat
 + :POSTROUTING ACCEPT [0:0]
 + :PREROUTING ACCEPT [0:0]
 +
 + -A POSTROUTING -s 192.168.1.0/24 -o enp0s31f6 -j MASQUERADE
 +
 + COMMIT

 # Don't delete these required lines, otherwise there will be errors
 *filter

 $ sudo ufw enable

Install and configure dhcp server for local network::

 $ sudo apt-get -y install isc-dhcp-server
 $ sudo vi /etc/dhcp/dhcpd.conf

 - #authoritative;
 + authoritative;

 + subnet 192.168.1.0 netmask 255.255.255.0 {
 +   option routers              192.168.1.1;
 +   option subnet-mask          255.255.255.0;
 +   option broadcast-address    192.168.1.255;
 +   option domain-name-servers  192.168.1.1;
 +   option domain-name          "iaas.net";
 +   range 192.168.1.50 192.168.1.99;
 + }

Select the network interface which dhcp server works.
This is SUPER important setting to avoid breaking down your (company) network. Local (OpenStack side) interface should be specified::

 $ sudo vi /etc/default/isc-dhcp-server
 - INTERFACES=""
 + INTERFACES="enp2s0"                <<<Change enp2s0 for your env>>>

Keystone installation on controller node
----------------------------------------

Install packages for Keystone::

 $ sudo apt-get -y install mariadb-server python-pymysql
 $ sudo mysql
 > CREATE DATABASE keystone CHARACTER SET utf8;
 > GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'KEYSTONE_DBPASS';
 > GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'KEYSTONE_DBPASS';
 $ sudo apt-get -y install vim keystone apache2 libapache2-mod-wsgi

Confirm the Stein release of Keystone is installed::

 $ keystone-manage --version
 15.0.0
 $

Edit configuration file::

 $ sudo vi /etc/keystone/keystone.conf
 - connection = sqlite:////var/lib/keystone/keystone.db
 + connection = mysql+pymysql://keystone:KEYSTONE_DBPASS@localhost/keystone

Initialize Keystone service::

 $ sudo su -
 # su -s /bin/sh -c "keystone-manage db_sync" keystone
 # keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
 # keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
 # keystone-manage bootstrap --bootstrap-password ADMIN_PASS \
 --bootstrap-admin-url http://iaas-ctrl:5000/v3/ \
 --bootstrap-internal-url http://iaas-ctrl:5000/v3/ \
 --bootstrap-public-url http://iaas-ctrl:5000/v3/ \
 --bootstrap-region-id RegionOne
 #
 # vi /etc/apache2/sites-available/000-default.conf
 -         #ServerName www.example.com
 +         #ServerName iaas-ctrl
 # service apache2 restart

Configure management user and exit for re-login::

 $ echo "export OS_USERNAME=admin"      >> ~/.bashrc
 $ echo "export OS_PASSWORD=ADMIN_PASS" >> ~/.bashrc
 $ echo "export OS_PROJECT_NAME=admin"             >> ~/.bashrc
 $ echo "export OS_USER_DOMAIN_NAME=Default"       >> ~/.bashrc
 $ echo "export OS_PROJECT_DOMAIN_NAME=Default"    >> ~/.bashrc
 $ echo "export OS_AUTH_URL=http://iaas-ctrl:5000/v3" >> ~/.bashrc
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
 $ openstack endpoint create --region RegionOne image public http://iaas-ctrl:9292
 $ openstack endpoint create --region RegionOne image internal http://iaas-ctrl:9292
 $ openstack endpoint create --region RegionOne image admin http://iaas-ctrl:9292
 
Install and configure Glance::

 $ sudo apt-get -y install glance

Edit /etc/glance/glance-api.conf::

 $ sudo vi /etc/glance/glance-api.conf
 - #connection = <None>
 + connection = mysql+pymysql://glance:GLANCE_DBPASS@iaas-ctrl/glance

 [..]

 [keystone_authtoken]
 + auth_uri = http://iaas-ctrl:5000
 + auth_url = http://iaas-ctrl:5000
 + memcached_servers = iaas-ctrl:11211
 + auth_type = password
 + project_domain_name = default
 + user_domain_name = default
 + project_name = service
 + username = glance
 + password = GLANCE_PASS

DB sync::

 # mysql
 > CREATE DATABASE glance CHARACTER SET utf8;
 > GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'GLANCE_DBPASS';
 > GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'GLANCE_DBPASS';
 > exit
 # su -s /bin/sh -c "glance-manage db_sync" glance

Nova installation on controller node
------------------------------------

Create database::

 # mysql
 > CREATE DATABASE nova_api CHARACTER SET utf8;
 > CREATE DATABASE nova CHARACTER SET utf8;
 > CREATE DATABASE nova_cell0 CHARACTER SET utf8;
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
 $ openstack endpoint create --region RegionOne compute public http://iaas-ctrl:8774/v2.1
 $ openstack endpoint create --region RegionOne compute internal http://iaas-ctrl:8774/v2.1
 $ openstack endpoint create --region RegionOne compute admin http://iaas-ctrl:8774/v2.1

Configure Keystone for Placement service::

 $ openstack user create --domain default --password PLACEMENT_PASS placement
 $ openstack role add --project service --user placement admin
 $ openstack service create --name placement --description "Placement API" placement
 $ openstack endpoint create --region RegionOne placement public http://iaas-ctrl:8778 
 $ openstack endpoint create --region RegionOne placement internal http://iaas-ctrl:8778 
 $ openstack endpoint create --region RegionOne placement admin http://iaas-ctrl:8778 

Install packages::

 $ sudo apt-get -y install nova-api nova-conductor nova-consoleauth nova-novncproxy nova-scheduler nova-placement-api

Edit /etc/nova/nova.conf::

 $ sudo vi /etc/nova/nova.conf
 [api_database]
 - connection = sqlite:////var/lib/nova/nova_api.sqlite
 + connection = mysql+pymysql://nova:NOVA_DBPASS@iaas-ctrl/nova_api

 [database]
 - connection = sqlite:////var/lib/nova/nova.sqlite
 + connection = mysql+pymysql://nova:NOVA_DBPASS@iaas-ctrl/nova

 [DEFAULT]
 - log_dir = /var/log/nova

 - #transport_url = <None>
 + transport_url = rabbit://openstack:RABBIT_PASS@iaas-ctrl

 - #auth_strategy = keystone
 + auth_strategy = keystone

 - #my_ip = <host_ipv4>
 + my_ip = 192.168.1.1

 - # use_neutron = true
 + use_neutron = true

 - # firewall_driver = nova.virt.firewall.NoopFirewallDriver
 + firewall_driver = nova.virt.firewall.NoopFirewallDriver

 [keystone_authtoken]
 + auth_uri = http://iaas-ctrl:5000
 + auth_url = http://iaas-ctrl:5000
 + memcached_servers = iaas-ctrl:11211
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
 + api_servers = http://iaas-ctrl:9292

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
 + auth_url = http://iaas-ctrl:5000/v3
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
 + -l 192.168.1.1

Confirm nova-api works fine::

 $ nova list

Neutron installation on controller node
---------------------------------------

Configure Keystone for Neutron service::

 $ openstack user create --domain default --password NEUTRON_PASS neutron
 $ openstack role add --project service --user neutron admin
 $ openstack service create --name neutron --description "OpenStack Networking" network
 $ openstack endpoint create --region RegionOne network public http://iaas-ctrl:9696
 $ openstack endpoint create --region RegionOne network internal http://iaas-ctrl:9696
 $ openstack endpoint create --region RegionOne network admin http://iaas-ctrl:9696

Install packages::

 $ sudo apt-get -y install neutron-server neutron-plugin-ml2 neutron-linuxbridge-agent neutron-dhcp-agent neutron-metadata-agent

Edit /etc/neutron/neutron.conf::

 $ sudo vi /etc/neutron/neutron.conf
 [database]
 - connection = sqlite:////var/lib/neutron/neutron.sqlite
 + connection = mysql+pymysql://neutron:NEUTRON_DBPASS@iaas-ctrl/neutron

 [DEFAULT]
 - #transport_url = <None>
 + transport_url = rabbit://openstack:RABBIT_PASS@iaas-ctrl

 [keystone_authtoken]
 + auth_uri = http://iaas-ctrl:5000
 + auth_url = http://iaas-ctrl:5000
 + memcached_servers = iaas-ctrl:11211
 + auth_type = password
 + project_domain_name = default
 + user_domain_name = default
 + project_name = service
 + username = neutron
 + password = NEUTRON_PASS

 [nova]
 + auth_url = http://iaas-ctrl:5000
 + auth_type = password
 + project_domain_name = default
 + user_domain_name = default
 + region_name = RegionOne
 + project_name = service
 + username = nova
 + password = NOVA_PASS

 [agent]
 +root_helper = sudo /usr/bin/neutron-rootwrap /etc/neutron/rootwrap.conf

Edit /etc/neutron/plugins/ml2/ml2_conf.ini::

 $ sudo vi /etc/neutron/plugins/ml2/ml2_conf.ini
 [ml2]
 type_drivers = flat,vxlan
 tenant_network_types = vxlan
 mechanism_drivers = linuxbridge,l2population
 extension_drivers = port_security

 [ml2_type_flat]
 flat_networks = provider

 [ml2_type_vxlan]
 vni_ranges = 1:1000

Edit /etc/neutron/plugins/ml2/linuxbridge_agent.ini::

 $ sudo vi /etc/neutron/plugins/ml2/linuxbridge_agent.ini
 [linux_bridge]
 + physical_interface_mappings = provider:enp2s0   <<<Change enp2s0 for your env>>>

 [vxlan]
 [vxlan]
 enable_vxlan = true
 local_ip = 192.168.1.1  <<<Change 192.168.1.1 for your env>>>
 l2_population = true
 vxlan_group =

 [agent]
 prevent_arp_spoofing = true

 [securitygroup]
 firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

Edit /etc/neutron/dhcp_agent.ini::

 $ sudo vi /etc/neutron/dhcp_agent.ini
 [DEFAULT]
 + interface_driver = linuxbridge
 + enable_isolated_metadata = true

Edit /etc/neutron/metadata_agent.ini::

 $ sudo vi /etc/neutron/metadata_agent.ini
 [DEFAULT]
 + nova_metadata_host = iaas-ctrl
 + metadata_proxy_shared_secret = METADATA_SECRET

Edit /etc/nova/nova.conf::

 $ sudo vi /etc/nova/nova.conf
 [neutron]
 + url = http://iaas-ctrl:9696
 + auth_url = http://iaas-ctrl:5000
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
 > CREATE DATABASE neutron CHARACTER SET utf8;
 > GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'NEUTRON_DBPASS';
 > GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'NEUTRON_DBPASS';
 > exit
 # su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
   --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

Restart and verify installation::

 $ sudo reboot
 [after rebooting..]

Nova and Neutron installation on compute node
---------------------------------------------

We can use ansible playbook for the following operations::

 $ cd cpu
 $ ansible-playbook 01_node.yaml -i ../hosts --ask-become-pass

Install package::

 $ sudo apt-get -y install nova-compute neutron-linuxbridge-agent

Edit /etc/nova/nova.conf::

 [DEFAULT]
 - log_dir = /var/log/nova

 - #transport_url = <None>
 + transport_url = rabbit://openstack:RABBIT_PASS@iaas-ctrl

 - #my_ip = <host_ipv4>
 + my_ip = 192.168.1.2  <<Change here after local network>>

 [keystone_authtoken]
 + auth_uri = http://iaas-ctrl:5000
 + auth_url = http://iaas-ctrl:5000
 + memcached_servers = iaas-ctrl:11211
 + auth_type = password
 + project_domain_name = default
 + user_domain_name = default
 + project_name = service
 + username = nova
 + password = NOVA_PASS

 [vnc]
 + vncserver_listen = 0.0.0.0
 + vncserver_proxyclient_address = $my_ip
 + novncproxy_base_url = http://iaas-ctrl:6080/vnc_auto.html

 [glance]
 + api_servers = http://iaas-ctrl:9292

 [oslo_concurrency]
 + lock_path = /var/lib/nova/tmp

 [placement]
 + os_region_name = RegionOne
 + project_domain_name = Default
 + project_name = service
 + auth_type = password
 + user_domain_name = Default
 + auth_url = http://iaas-ctrl:5000/v3
 + username = placement
 + password = PLACEMENT_PASS

 [neutron]
 + url = http://iaas-ctrl:9696
 + auth_url = http://iaas-ctrl:5000
 + auth_type = password
 + project_domain_name = default
 + user_domain_name = default
 + region_name = RegionOne
 + project_name = service
 + username = neutron
 + password = NEUTRON_PASS

Edit /etc/neutron/neutron.conf::

 [DEFAULT]
 + transport_url = rabbit://openstack:RABBIT_PASS@iaas-ctrl
 + service_plugins = neutron.services.l3_router.l3_router_plugin.L3RouterPlugin

 [keystone_authtoken]
 + auth_uri = http://iaas-ctrl:5000
 + auth_url = http://iaas-ctrl:5000
 + memcached_servers = iaas-ctrl:11211
 + auth_type = password
 + project_domain_name = default
 + user_domain_name = default
 + project_name = service
 + username = neutron
 + password = NEUTRON_PASS

 [agent]
 +root_helper = sudo /usr/bin/neutron-rootwrap /etc/neutron/rootwrap.conf

Edit /etc/neutron/plugins/ml2/linuxbridge_agent.ini::

 [linux_bridge]
 + physical_interface_mappings = provider:eno1

 [vxlan]
 + enable_vxlan = true
 + local_ip = 192.168.1.59    <<Change 192.168.1.59 for your env>>
 + l2_population = true
 + vxlan_group =

 [agent]
 + prevent_arp_spoofing = true

 [securitygroup]
 - #firewall_driver = <None>
 + firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

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

 $ wget https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img
 $ openstack image create --container-format bare --disk-format qcow2 \
   --file bionic-server-cloudimg-amd64.img Ubuntu-18.04-x86_64

Prepare to create a virtual machine::

 $ ssh-keygen -q -N ""
 $ openstack keypair create --public-key ~/.ssh/id_rsa.pub mykey
 $ openstack security group rule create --proto icmp default
 $ openstack security group rule create --proto tcp --dst-port 22 default
 $ openstack network create  --share --external --provider-physical-network provider --provider-network-type flat provider
 $ openstack subnet create --network provider \
   --allocation-pool start=192.168.1.100,end=192.168.1.200 \
   --dns-nameserver 8.8.4.4 --gateway 192.168.1.1 \
   --subnet-range 192.168.1.0/24 provider

Create a virtual machine::

 $ PROVIDER_NET_ID=`openstack network list | grep provider | awk '{print $2}'`
 $ openstack server create --flavor m1.medium --image Ubuntu-18.04-x86_64 \
   --nic net-id=$PROVIDER_NET_ID --security-group default \
   --key-name mykey vm01

Enable Octavia
==============


