Setup CI machine
================

The PC is Dell Optiplex 7020 in this doc.
That is very common spec and that would be not matter at all.
This means this doc way would work at any machines.

Setup gitlab
------------

Install gitlab::

 $ sudo apt-get -y install curl ca-certificates
 $ curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash
 $ sudo apt-get install gitlab-ce
 $ sudo gitlab-ctl reconfigure

Access to https://<ip-address> with web browser::

 Change the password as the page says.
 Login with root/<changed password>
 Add a user
 Add a project and check the project URL

Move the existing github repo to the above gitlab repo::

 $ git clone https://github.com/nec-openstack/remora
 $ git remote rm origin
 $ git remote add origin <the above project URL>
 $ git push -u origin master

Install gitlab CI runner
------------------------

Install gitlab-runner[1]::

 $ curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash
 $ sudo apt-get install gitlab-runner

Register gitlab-runner::

 $ sudo gitlab-runner register
 Please enter the gitlab-ci coordinator URL (e.g. https://gitlab.com/):
 http://172.27.138.62/ci
 Please enter the gitlab-ci token for this runner:
 <You can see this as "registration token" on http://../admin/runners>
 Please enter the gitlab-ci description for this runner:
 [localhost]: my-runner
 Please enter the gitlab-ci tags for this runner (comma separated):
 my-tag
 Whether to run untagged builds [true/false]:
 [false]: true
 Whether to lock the Runner to current project [true/false]:
 [true]: true
 Registering runner... succeeded                     runner=RW-JvuxG
 Please enter the executor: docker, shell, ssh, docker-ssh, parallels, virtualbox, docker+machine, docker-ssh+machine, kubernetes:
 shell
 Runner registered successfully. Feel free to start it, but if it's running already the config should be automatically reloaded!
 $

Setup gitlab CI runner on each repo
-----------------------------------

Setup DHCP server
-----------------

Operate the following::

 $ sudo apt-get install isc-dhcp-server
 $ sudo vi /etc/dhcp/dhcpd.conf
 Remove both lines of "option donaim-name" and "domain-name-servers"
 Remove # from #authoritative;
 Add the following part
 subnet 192.168.1.0 netmask 255.255.255.0 {
     range 192.168.1.100 192.168.1.200;
     option broadcast-address 192.168.1255;
     option routers 192.168.1.1;
     default-lease-time 600;
     max-lease-time 7200;
     option domain-name "local";
     option domain-name-servers 8.8.8.8, 8.8.4.4;
 }
 Change INTERFACE="" to INTERFACES="eth0"

TODO: Add static address configuration for eth0

Configure SNAT between internet and local network
-------------------------------------------------

[1]: https://docs.gitlab.com/runner/install/linux-repository.html
