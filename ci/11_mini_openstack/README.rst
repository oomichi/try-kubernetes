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

 # su -s /bin/sh -c "glance-manage db_sync" glance

