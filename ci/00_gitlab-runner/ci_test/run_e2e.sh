#!/bin/bash

cd `dirname $0`

source adminrc

IP_E2E=`openstack server show e2e -c addresses -f value | sed s/"provider="//`
cp -f ./hosts_e2e.org ./hosts_e2e
sed -i s/"IP_E2E"/"${IP_E2E}"/g  ./hosts_e2e

echo "Start to run e2e test.."
ansible-playbook -vvvv -i ./hosts_e2e run_e2e_test.yaml
if [ $? -ne 0 ]; then
	echo "Failed to run e2e test"
	exit 1
fi

echo "Succeeded to run e2e test."

exit 0
