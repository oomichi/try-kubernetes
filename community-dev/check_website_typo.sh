#!/bin/bash

WEBSITE_DIR="$1"

if [ "${WEBSITE_DIR}" == "" ]; then
	WEBSITE_DIR=$(dirname $0)/../../website/
elif [ ! -d ${WEBSITE_DIR} ]; then
	echo "${WEBSITE_DIR} doesn't exist."
	exit 1
fi

# cd to the root directory of website
cd ${WEBSITE_DIR}

rm ./misspell*

set -e
wget https://github.com/client9/misspell/releases/download/v0.3.4/misspell_0.3.4_linux_64bit.tar.gz
tar -zxvf ./misspell_0.3.4_linux_64bit.tar.gz
chmod 755 ./misspell
git ls-files | grep "content/en/" | xargs ./misspell -error
