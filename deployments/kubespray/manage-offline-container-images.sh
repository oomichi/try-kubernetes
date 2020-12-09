#!/bin/bash

OPTION=$1
CURRENT_DIR=$(cd $(dirname $0); pwd)

IMAGE_TAR_FILE="${CURRENT_DIR}/container-images.tar.gz"
IMAGE_DIR="${CURRENT_DIR}/container-images"

function create_container_image_tar() {
	set -e

	IMAGES=$(kubectl describe pods --all-namespaces | grep " Image:" | awk '{print $2}' | sort | uniq)

	rm -f  ${IMAGE_TAR_FILE}
	rm -rf ${IMAGE_DIR}
	mkdir  ${IMAGE_DIR}
	cd     ${IMAGE_DIR}

	for image in ${IMAGES}
	do
		FILE_NAME="$(echo ${image} | awk -F"/" '{print $2}' | sed s/":"/"-"/g)".tar
		sudo docker pull ${image}
		sudo docker save -o ${FILE_NAME}  ${image}
		sudo chown ${USER}  ${FILE_NAME}
	done

	cd ..
	tar -zcvf ${IMAGE_TAR_FILE}  ${IMAGE_DIR}
	rm -rf ${IMAGE_DIR}
}

if [ "${OPTION}" == "create" ]; then
	create_container_image_tar
elif [ "${OPTION}" == "upload" ]; then

fi
