#!/bin/bash

function check_pod_status() {
	pod_name="${1}"
	namespace="${2}"

	if [ -z "${namespace}" ]; then
		namespace="default"
	fi

	RETRY_CHECK=60

	# Multiple sequential successes are necessary to verify the status
	SEQUENTIAL_SUCCESSES=3

	SUCCESSES=0
	echo "Start checking ${pod_name} pod status.."
	for step in `seq 1 ${RETRY_CHECK}`; do
		FLAG_FAILURE=0
		PODS_STATUS=`kubectl -n ${namespace} get pod ${pod_name} --template={{.status.phase}}`
		for status in ${PODS_STATUS}; do
			if [ "${status}" != "Running" ]; then
				FLAG_FAILURE=1
				SUCCESSES=0
				echo "Some pod status is ${status} on step ${step}"
			fi
		done

		if [ -z "${PODS_STATUS}" ]; then
			echo "Pod(${pod_name}) doesn't appear yet"
		elif [ ${FLAG_FAILURE} -eq 0 ]; then
			SUCCESSES=`expr ${SUCCESSES} + 1`
			if [ ${SUCCESSES} -eq ${SEQUENTIAL_SUCCESSES} ]; then
				echo "Pod(${pod_name}) status is Running"
				return 0
			fi
			echo "Pod(${pod_name})'s status is Running, and need to verify the status `expr ${SEQUENTIAL_SUCCESSES} - ${SUCCESSES}` more time(s)"
		fi
		sleep 2
	done

	echo "Failed to check pod status which all be Running"
	return 1
}

function check_all_pods_status_in_ns() {
	namespace="${1}"

	POD_NAMES=`kubectl get pods -n ${namespace} | awk '{print $1}' | grep -v NAME`
	for name in ${POD_NAMES}; do
		check_pod_status $name ${namespace}
		if [ $? -ne 0 ]; then
			return 1
		fi
	done
}

echo "Check kubectl works"
kubectl version
if [ $? -ne 0 ]; then
	exit 1
fi

echo "Check pods in kube-system ns"
check_all_pods_status_in_ns kube-system
if [ $? -ne 0 ]; then
	exit 1
fi

echo "Check pods in ingress-nginx ns"
check_all_pods_status_in_ns ingress-nginx
if [ $? -ne 0 ]; then
	exit 1
fi

echo "Test ingress-nginx feature"
kubectl create -f yaml/test-ingress-nginx.yaml
if [ $? -ne 0 ]; then
	exit 1
fi
