How to CI for nec-openstack/remora
==================================

The remora is maintained on github, and we continue it in the future.
However we want to CI it locally to know the integration test result on each commit.
In addition, we cannot deploy web service due to the company restriction, so github's
webhook is not an option for us today.

Then we need to implement CI by polling github changes from the company internal.
The following is an idea for doing that.

* Polling daemon
  Fetch remora repo from github.
  If detecting any changes from previous polling, the daemon commits each change into a history repo which contains .gitlab-ci.yml.

* History repo
  This repo maintains all changes of remora to kick CI for new changes.
  github_history.txt::
    https://github.com/nec-openstack/remora/commit/fdce194450c07ccc2af3b0a9c1d19f0661b9b533
    https://github.com/nec-openstack/remora/commit/dff158b4dc8c7a0a1eeb4da5d817947e95543172
    ...
  Commit msg: Change of fdce194450c07ccc2af3b0a9c1d19f0661b9b533

* .gitlab-ci.yml


How to
------

Register ci_test/ as a new project repo at gitlab.
Write the latest single commit of the target repo at ci_test/github_history.txt file. For example::

 https://github.com/nec-openstack/remora/commit/fdce194450c07ccc2af3b0a9c1d19f0661b9b533

Register ci_test/poll_github.sh as a cron job for each hour as you like.


