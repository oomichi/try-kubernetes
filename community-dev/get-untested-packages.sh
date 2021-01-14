#!/bin/bash

SEARCH_PATH=${1:-"./pkg"}
VERBOSITY=${VERBOSITY:-""}

DIRS=$(find ${SEARCH_PATH} -maxdepth 1 -mindepth 1 -type d)
for dir in ${DIRS}
do
	PKGS=$(find ${dir} -name "*.go" | grep -v "_test.go" | grep -v "doc.go" | grep -v "test" | grep -v "fake" | grep -v "sample" | grep -v "stub")
	COUNT=0
	for pkg in ${PKGS}
	do
		UNIT_TEST=$(echo $pkg | sed s@\.go@_test.go@)
		if [ -f ${UNIT_TEST} ]; then
			continue
		fi
		grep "^func " $pkg > /dev/null
		if [ $? -ne 0 ]; then
			continue
		fi
		if [ -n "${VERBOSITY}" ]; then
			echo "$pkg doesn't have unit test file"
		fi
		COUNT=$(expr ${COUNT} + 1)
	done
	echo "${dir}: ${COUNT} files are not tested on unit tests."
done
