Github history repo for kicking CI locally
==========================================

Setup
-----

If CI operation is longer than 60 mins which is default timeout of gitlab-runner,
we need to change the timeout with::

 Open http://<gitlab>/<user>/<project>/settings/ci_cd
 Open "General pipelines settings"
 Change "Timeout" to 120 from 60

Write the latest github commit on github_history.txt like::

 https://github.com/nec-openstack/remora/commit/fdce194450c07ccc2af3b0a9c1d19f0661b9b533


