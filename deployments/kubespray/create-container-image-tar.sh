#!/bin/bash

set -e

IMAGES=$(kubectl describe pods --all-namespaces | grep " Image:" | awk '{print $2}' | sort | uniq)

rm -f  container-images.tar.gz
rm -rf container-images/
mkdir  container-images/
cd     container-images/

for image in ${IMAGES}
do
	FILE_NAME="$(echo ${image} | awk -F"/" '{print $2}' | sed s/":"/"-"/g)".tar
	sudo docker pull ${image}
	sudo docker save -o ${FILE_NAME}  ${image}
	sudo chown ${USER}  ${FILE_NAME}
done

cd ..
tar -zcvf container-images.tar.gz container-images/
rm -rf container-images/
