#!/bin/bash

SLACK_API_TOKEN=`cat ./slack_api_token`
RETURN_CODE=0
LAST_LINE=`tail -n1 ./github_history.txt`
MESSAGE="Succeeded to test the remora commit ${LAST_LINE}"
TEMPFILE=`mktemp remora.log-XXXX`

./run_test.sh | tee ${TEMPFILE}
if [ $? -ne 0 ]; then
	RETURN_CODE=1
	DETAIL=`cat ${TEMPFILE}`
	MESSAGE="Failed to test the commit ${LAST_LINE}. ${DETAIL}"
fi
curl -XPOST -d "token=${SLACK_API_TOKEN}" -d "channel=#general" -d "text=${MESSAGE}" -d "username=remora-bot" "https://slack.com/api/chat.postMessage"

rm ${TEMPFILE}
exit ${RETURN_CODE}
