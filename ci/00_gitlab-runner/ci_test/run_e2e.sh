#!/bin/bash

ansible-playbook -vvvv -i ./hosts_vms create_e2e_test_env.yaml
if [ $? -ne 0 ]; then
	echo "Failed to create e2e test env"
	exit 1
fi

ansible-playbook -vvvv -i ./hosts_vms run_e2e_test.yaml
if [ $? -ne 0 ]; then
	echo "Failed to run e2e test"
	exit 1
fi

exit 0
