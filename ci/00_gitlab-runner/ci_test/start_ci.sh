#!/bin/bash

SLACK_API_TOKEN=`cat ./slack_api_token`
LAST_LINE=`tail -n1 ./github_history.txt`
MESSAGE="Succeeded to test the remora commit ${LAST_LINE}"
TEMPFILE=`mktemp /tmp/remora-vms-XXXX`

./create_vms.sh ${TEMPFILE}
if [ $? -ne 0 ]; then
	MESSAGE="Failed to test the commit ${LAST_LINE}. (Failed to create vms)"
	openstack server delete `cat ${TEMPFILE}`
	curl -XPOST -d "token=${SLACK_API_TOKEN}" -d "channel=#containers" -d "text=${MESSAGE}" -d "username=remora-bot" "https://slack.com/api/chat.postMessage"
	rm ${TEMPFILE}
	exit 1
fi
echo "Succeeded to create virtual machines."

# Operate remora!!
echo "Start to operate remora.."
./run_remora.sh
if [ $? -ne 0 ]; then
	MESSAGE="Failed to test the commit ${LAST_LINE}. (Failed to operate remora)"
	openstack server delete `cat ${TEMPFILE}`
	curl -XPOST -d "token=${SLACK_API_TOKEN}" -d "channel=#containers" -d "text=${MESSAGE}" -d "username=remora-bot" "https://slack.com/api/chat.postMessage"
	rm ${TEMPFILE}
	exit 1
fi
echo "Succeeded to operate remora."

./run_e2e.sh
if [ $? -ne 0 ]; then
	MESSAGE="Failed to test the commit ${LAST_LINE}. (Failed to run e2e tests)"
	openstack server delete `cat ${TEMPFILE}`
	curl -XPOST -d "token=${SLACK_API_TOKEN}" -d "channel=#containers" -d "text=${MESSAGE}" -d "username=remora-bot" "https://slack.com/api/chat.postMessage"
	rm ${TEMPFILE}
	exit 1
fi
echo "Succeeded to run e2e tests."

MESSAGE="Succeeded to test the commit ${LAST_LINE}"
openstack server delete `cat ${TEMPFILE}`
curl -XPOST -d "token=${SLACK_API_TOKEN}" -d "channel=#containers" -d "text=${MESSAGE}" -d "username=remora-bot" "https://slack.com/api/chat.postMessage"
rm ${TEMPFILE}

exit 0
