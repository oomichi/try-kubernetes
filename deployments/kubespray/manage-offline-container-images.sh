#!/bin/bash

OPTION=$1
CURRENT_DIR=$(cd $(dirname $0); pwd)
TEMP_DIR="${CURRENT_DIR}/temp"

IMAGE_TAR_FILE="${CURRENT_DIR}/container-images.tar.gz"
IMAGE_DIR="${CURRENT_DIR}/container-images"
IMAGE_LIST="${IMAGE_DIR}/container-images.txt"
RETRY_COUNT=5

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
		set +e
		for step in $(seq 1 ${RETRY_COUNT})
		do
			sudo docker pull ${image}
			if [ $? -eq 0 ]; then
				break
			fi
			echo "Failed to pull ${image} at step ${step}"
			if [ ${step} -eq ${RETRY_COUNT} ]; then
				exit 1
			fi
		done
		set -e
		sudo docker save -o ${FILE_NAME}  ${image}
		echo "${FILE_NAME}  ${image}" >> ${IMAGE_LIST}
	done

	cd ..
	sudo chown ${USER} ${IMAGE_DIR}/*
	tar -zcvf ${IMAGE_TAR_FILE}  ./container-images
	rm -rf ${IMAGE_DIR}

	echo ""
	echo "${IMAGE_TAR_FILE} is created to contain your container images."
	echo "Please keep this file and bring it to your offline environment."
}

function register_container_images() {
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
		echo "${LOCALHOST_NAME} should be resolved."
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
		file_name=$(echo ${line} | awk '{print $1}')
		org_image=$(echo ${line} | awk '{print $2}')
		new_image=$(echo ${org_image} | sed s@"[^\/]*\/"@"${LOCALHOST_NAME}:5000\/"@)
		image_id=$(tar -tf ${IMAGE_DIR}/${file_name} | grep "\.json" | grep -v manifest.json)
		sudo docker load -i ${IMAGE_DIR}/${file_name}
		sudo docker tag  ${image_id} ${new_image}
		sudo docker push ${new_image}
	done <<< "$(cat ${IMAGE_LIST})"
}

if [ "${OPTION}" == "create" ]; then
	create_container_image_tar
elif [ "${OPTION}" == "register" ]; then
	register_container_images
else
	echo "This script has two features:"
	echo "(1) Get container images from an environment which is deployed online."
	echo "(2) Deploy local container registry and register the container images to the registry."
	echo ""
	echo "Step(1) should be done online site as a preparation, then we bring"
	echo "the gotten images to the target offline environment."
	echo "Then we will run step(2) for registering the images to local registry."
	echo ""
	echo "${IMAGE_TAR_FILE} is created to contain your container images."
	echo "Please keep this file and bring it to your offline environment."
	echo ""
	echo "Step(1) can be operated with:"
	echo " $ ./manage-offline-container-images.sh   create"
	echo ""
	echo "Step(2) can be operated with:"
	echo " $ ./manage-offline-container-images.sh   register"
	echo ""
	echo "Please specify 'create' or 'register'."
	echo ""
	exit 1
fi
