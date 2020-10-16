#!/bin/bash

PKGS=$(find ./pkg -name "*.go" | grep -v "_test.go")

for pkg in ${PKGS}
do
	UNIT_TEST=$(echo $pkg | sed s@\.go@_test.go@)
	if [ -f ${UNIT_TEST} ]; then
		continue
	fi
	echo "$UNIT_TEST does not exist"
done
