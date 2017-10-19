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
 $ vi /etc/gitlab/gitlab.rb
 - external_url 'http://gitlab.example.com'
 + external_url 'http://<your url or ip-address:10080>'
 $ sudo gitlab-ctl reconfigure

The above 10080 port is for avoiding conflict with OpenStack port.
Access to http://<ip-address:10080> with web browser::

 Change the password as the page says.
 Login with root/<changed password>
 Add a user
 Add a public SSH key to the created user
 Add a project and check the project URL

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

Admin Area -> Runners -> Edit (my-runner) -> Remove "Lock to current projects"

Setup gitlab CI runner on each repo
-----------------------------------

Add .gitlab-ci.yml file under root path of the repo.
The detail is https://docs.gitlab.com/ce/ci/yaml/README.html
On the following sample file, the runner kicks ./test_script.sh::

 $ cat .gitlab-ci.yml
 stages:
   - test

 test_job:
   stage: test
   script:
     - ./test_script.sh
   tags:
     - my-tag

The runner checks the return code of the script and it considers error if non-zero code.

[1]: https://docs.gitlab.com/runner/install/linux-repository.html
