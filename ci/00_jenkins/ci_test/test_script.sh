#!/bin/sh

cd dirname $0

WORKING_PATH=`pwd`
LAST_LINE=`tail -n1 ./github_history.txt`
LAST_COMMIT=`echo ${LAST_LINE} | awk -F "/" '{print $NF}'`
GIT_URL=`echo ${LAST_LINE} | sed s@"/commit/${LAST_COMMIT}"@@`
GIT_DIRNAME=`echo ${GIT_URL} | awk -F "/" '{print $NF}'`

echo "LAST_COMMIT: $LAST_COMMIT"
echo "GIT_URL: $GIT_URL"
echo "GIT_DIRNAME: $GIT_DIRNAME"

if [ -z ${LAST_COMMIT} ]; then
	echo "Failed to get LAST_COMMIT, github_history.txt could be invalid."
	exit 1
fi
if [ -z ${GIT_URL} ]; then
	echo "Failed to get GIT_URL, github_history.txt could be invalid."
	exit 1
fi
if [ -z ${GIT_DIRNAME} ]; then
	echo "Failed to get GIT_DIRNAME, github_history.txt could be invalid."
	exit 1
fi

cd /tmp
rm -rf /tmp/${GIT_DIRNAME}
git clone ${GIT_URL}
cd ./${GIT_DIRNAME}

# It is possible that the latest commit of the target repo is different from LAST_COMMIT
# when poll_github.sh detects multiple differences between the target repo and this test
# kicking repo.
git checkout ${LAST_COMMIT}

if ! [ -e ./start_ci_test.sh ]; then
	echo "start_ci_test.sh doesn't exist under ${GIT_DIRNAME}"
	exit 1
fi

./start_ci_test.sh
if [ $? -ne 0 ]; then
	echo "Failed to operate start_ci_test.sh."
	exit 1
fi

rm -rf /tmp/${GIT_DIRNAME}
exit 0
