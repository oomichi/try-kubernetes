#!/bin/sh

cd `dirname $0`

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

LATEST_COMMIT=`git log --no-merges --pretty=format:"%H" -n1`
if [ ${LAST_COMMIT} = ${LATEST_COMMIT} ]; then
	echo "The repo ${GIT_DIRNAME} has not been changed yet since ${LAST_COMMIT}"
	exit 0
fi

DIFF_COMMITS=`git log --no-merges --pretty=format:"%H" ${LAST_COMMIT}..HEAD`

cd ${WORKING_PATH}
rm -rf /tmp/${GIT_DIRNAME}

for each_commit in `echo ${DIFF_COMMITS}`
do
	echo "${GIT_URL}/commit/${each_commit}" >> ./github_history.txt
	git commit -m "Change of ${each_commit}" ./github_history.txt
	git push origin master

	# Wait for kicking CI job for each commit before next commit operation
	sleep 10
done

exit 0
