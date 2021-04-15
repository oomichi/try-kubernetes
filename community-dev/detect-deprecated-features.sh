#!/bin/bash

DEPRECATED_FEATURES="""
pvc,failure-domain.beta.kubernetes.io/zone,deleted-since-v1.21,use-topology.kubernetes.io/zone
pvc,failure-domain.beta.kubernetes.io/region,deleted-since-v1.21,use-topology.kubernetes.io/region
"""

NAMESPACES=$(kubectl get ns | grep -v NAME | awk '{print $1}')
for namespace in ${NAMESPACES}
do
	for deprecated in ${DEPRECATED_FEATURES}
	do
		resource=$(echo ${deprecated} | awk -F, '{print $1}')
		feature=$(echo ${deprecated} | awk -F, '{print $2}')
		reason=$(echo ${deprecated} | awk -F, '{print $3}')
		advice=$(echo ${deprecated} | awk -F, '{print $4}')
		resource_names=$(kubectl -n ${namespace} get ${resource} | grep -v NAME | awk '{print $1}')
		for resource_name in ${resource_names}
		do
			deprecated=$(kubectl -n ${namespace} get ${resource}/${resource_name} -o yaml | grep ${feature})
			if [ -z "${deprecated}" ]; then
				continue
			fi
			echo "${resource}/${resource_name} of the namespace ${namespace} contains the deprecated ${deprecated} due to ${reason}"
		done
	done
done
