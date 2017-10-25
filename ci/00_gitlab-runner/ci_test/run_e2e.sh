#!/bin/bash

echo "Start to run e2e test.."
ansible-playbook -vvvv -i ./hosts_e2e run_e2e_test.yaml
if [ $? -ne 0 ]; then
	echo "Failed to run e2e test"
	exit 1
fi

echo "Succeeded to run e2e test."

exit 0
