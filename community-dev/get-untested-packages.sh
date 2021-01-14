#!/bin/bash

SEARCH_PATH=${1:-"./pkg"}
VERBOSITY=${VERBOSITY:-""}
EASY_MODE=${EASY_MODE:-""}

DIRS=$(find ${SEARCH_PATH} -maxdepth 1 -mindepth 1 -type d)
for dir in ${DIRS}
do
	PKGS=$(find ${dir} -name "*.go" | grep -v "_test.go" | grep -v "doc.go" | grep -v "test" | grep -v "fake" | grep -v "sample" | grep -v "stub")
	COUNT=0
	if [ -n "${VERBOSITY}" ]; then
		echo "The following files don't have unit test files under ${dir}"
	fi
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
		SKIP=0
		if [ -n "${EASY_MODE}" ]; then
			FUNCS=$(grep "^func " $pkg | wc -l)
			for index in $(seq ${FUNCS})
			do
				FUNC_WORDS=$(grep "^func " $pkg | head -n ${index} | tail -n 1 | wc -w)
				if [ ${FUNC_WORDS} -gt 6 ]; then
					# Functions which contain many arguments tend to be complex
					SKIP=1
					break
				fi
			done
		fi
		if [ ${SKIP} -eq 1 ]; then
			continue
		fi
		if [ -n "${VERBOSITY}" ]; then
			echo "$pkg"
		fi
		COUNT=$(expr ${COUNT} + 1)
	done
	echo "${dir}: ${COUNT} files are not tested on unit tests."
done
