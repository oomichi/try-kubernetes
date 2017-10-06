Scripts for configuring network
===============================

How to use
----------

1. (If VirtualBox) Create internal network on VirtualBox Console::

   Select virtual machine
   -> Setting
   -> Network
   -> Adaptor 2
   -> Attached to: "Internal Network"
   -> OK

2. Clone this git repo::

   $ git clone ..

3. (If VirtualBox) Set the IP address on the created internal network IF::

   $ sudo 01_VirtualBox_configure_internal_network.sh 192.168.0.1

4. Make it possible to ssh-login to target machines from Ansible host::

   $ 02_install_ssh_key.sh 192.168.0.1

5. Change hostname::

 $ ansible-playbook -i ./hosts --ask-become-pass 03_change_hostname.yaml

References
----------
* http://qiita.com/areaz_/items/c9075f7a0b3e147e92f2

