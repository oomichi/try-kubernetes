#!/bin/bash

MOUNT_NAME="${1}"
PV_SIZE_GB="${2}"

if [ -z "${MOUNT_NAME}" ] || [ -z "${PV_SIZE_GB}" ]; then
	echo "Need to specify MOUNT_NAME and PV_SIZE_GB like:"
	echo "./create-local-pv.sh foo-mount 10"
	exit 1
fi

# Ignore error of mkdir here because of the existing directory case.
sudo mkdir /var/disks
sudo truncate /var/disks/${MOUNT_NAME} --size ${PV_SIZE_GB}G
if [ $? -ne 0 ]; then
	echo "Failed to create a file of /var/disks/${MOUNT_NAME}"
	exit 1
fi

sudo mkfs.ext4 -F /var/disks/${MOUNT_NAME}
if [ $? -ne 0 ]; then
	echo "Failed to create ext4fs of /var/disks/${MOUNT_NAME}"
	exit 1
fi

sudo mkdir /mnt/disks/${MOUNT_NAME}
if [ $? -ne 0 ]; then
	echo "Failed to create directory of /mnt/disks/${MOUNT_NAME}"
	exit 1
fi

sudo mount /var/disks/${MOUNT_NAME} /mnt/disks/${MOUNT_NAME}
if [ $? -ne 0 ]; then
	echo "Failed to mount directory of /mnt/disks/${MOUNT_NAME}"
	exit 1
fi

sudo echo '/var/disks/${MOUNT_NAME}  /mnt/disks/${MOUNT_NAME}  ext4  defaults  0  0' | sudo tee -a /etc/fstab
if [ $? -ne 0 ]; then
	echo "Failed to write /etc/fstab for ${MOUNT_NAME}"
	exit 1
fi
