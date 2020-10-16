#!/bin/bash

SEARCH_PATH=${1:-"./pkg"}

PKGS=$(find ${SEARCH_PATH} -name "*.go" | grep -v "_test.go" | grep -v "doc.go" | grep -v "testing" | grep -v "fake")

for pkg in ${PKGS}
do
	UNIT_TEST=$(echo $pkg | sed s@\.go@_test.go@)
	if [ -f ${UNIT_TEST} ]; then
		continue
	fi
	echo "$UNIT_TEST does not exist"
done
