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

 $ sudo apt-get -y install mysql-server
 $ sudo mysql
 mysql> CREATE DATABASE keystone;
 mysql> GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'KEYSTONE_DBPASS';
 mysql> GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'KEYSTONE_DBPASS';
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
