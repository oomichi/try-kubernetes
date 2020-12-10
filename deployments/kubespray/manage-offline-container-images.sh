#!/bin/bash

OPTION=$1
CURRENT_DIR=$(cd $(dirname $0); pwd)
TEMP_DIR="${CURRENT_DIR}/temp"

IMAGE_TAR_FILE="${CURRENT_DIR}/container-images.tar.gz"
IMAGE_DIR="${CURRENT_DIR}/container-images"
IMAGE_LIST="${IMAGE_DIR}/container-images.txt"

function create_container_image_tar() {
	set -e

	IMAGES=$(kubectl describe pods --all-namespaces | grep " Image:" | awk '{print $2}' | sort | uniq)

	rm -f  ${IMAGE_TAR_FILE}
	rm -rf ${IMAGE_DIR}
	mkdir  ${IMAGE_DIR}
	cd     ${IMAGE_DIR}

	sudo docker pull registry:latest
	sudo docker save -o registry-latest.tar registry:latest

	for image in ${IMAGES}
	do
		FILE_NAME="$(echo ${image} | sed s@"/"@"-"@g | sed s/":"/"-"/g)".tar
		sudo docker pull ${image}
		sudo docker save -o ${FILE_NAME}  ${image}
		sudo chown ${USER}  ${FILE_NAME}
		echo "${FILE_NAME}  ${image}" >> ${IMAGE_LIST}
	done

	cd ..
	tar -zcvf ${IMAGE_TAR_FILE}  ${IMAGE_DIR}
	rm -rf ${IMAGE_DIR}
}

function upload_container_images() {
	if [ ! -f ${IMAGE_TAR_FILE} ]; then
		echo "${IMAGE_TAR_FILE} should exist."
		exit 1
	fi
	tar -zxvf ${IMAGE_TAR_FILE}

	set -e
	sudo docker load -i ${IMAGE_DIR}/registry-latest.tar
	sudo docker run -d -p 5000:5000 --name registry registry:latest
	set +e

	LOCALHOST_NAME=$(hostname)
	ping -c 1 ${LOCALHOST_NAME}
	if [ $? -ne 0 ]; then
		echo "${LOCALHOST_NAME} should be resolve."
		exit 1
	fi

	if [ !-d ${TEMP_DIR} ]; then
		mkdir ${TEMP_DIR}
	fi
	# To avoid "http: server gave http response to https client" error.
	if [ -d /etc/containers/ ]; then
		# RHEL8/CentOS8
		cp ${CURRENT_DIR}/registries.conf         ${TEMP_DIR}/registries.conf
		sed -i s@"HOSTNAME"@"${LOCALHOST_NAME}"@  ${TEMP_DIR}/registries.conf
		sudo cp ${TEMP_DIR}/registries.conf   /etc/containers/registries.conf
	elif [ -d /etc/docker/ ]; then
		# Ubuntu18.04, RHEL7/CentOS7
		cp ${CURRENT_DIR}/docker-daemon.json      ${TEMP_DIR}/docker-daemon.json
		sed -i s@"HOSTNAME"@"${LOCALHOST_NAME}"@  ${TEMP_DIR}/docker-daemon.json
		sudo cp ${TEMP_DIR}/docker-daemon.json           /etc/docker/daemon.json
	else
		echo "docker package should be installed"
		exit 1
	fi

	set -e
	while read -r line; do
		file_name=$(echo $line | awk '{print $1}')
		org_image=$(echo $line | awk '{print $2}')
		new_image=$(echo $org_image | sed s@"[^\/]*\/"@"${LOCALHOST_NAME}:5000\/"@)
		sudo docker load -i ${file_name}
		sudo docker tag  ${org_image} ${new_image}
		sudo docker push ${new_image}
	done <<< "$(cat ${IMAGE_LIST})"
}

cd ${CURRENT_DIR}
if [ "${OPTION}" == "create" ]; then
	create_container_image_tar
elif [ "${OPTION}" == "upload" ]; then
	upload_container_images
fi
