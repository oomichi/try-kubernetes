#!/bin/bash

PV_NAME="${1}"
PV_SIZE_GB="${2}"

if [ -z "${PV_NAME}" ] || [ -z "${PV_SIZE_GB}" ]; then
	echo "Need to specify PV_NAME and PV_SIZE_GB like:"
	echo "./create-local-pv.sh foo-mount 10"
	exit 1
fi

# Ignore error of mkdir here because of the existing directory case.
sudo mkdir /var/disks

# local-pv-provisoner creates PersistentVolume based on mnt size which is less than the specified size.
# Then here specifies additional 10% for the size.
ACTUAL_SIZE_MB=$(expr ${PV_SIZE_GB} "*" 1150)
sudo truncate /var/disks/${PV_NAME} --size ${ACTUAL_SIZE_MB}M
if [ $? -ne 0 ]; then
	echo "Failed to create a file of /var/disks/${PV_NAME}"
	exit 1
fi

sudo mkfs.ext4 -F /var/disks/${PV_NAME}
if [ $? -ne 0 ]; then
	echo "Failed to create ext4fs of /var/disks/${PV_NAME}"
	exit 1
fi

sudo mkdir /mnt/disks/${PV_NAME}
if [ $? -ne 0 ]; then
	echo "Failed to create directory of /mnt/disks/${PV_NAME}"
	exit 1
fi

sudo mount /var/disks/${PV_NAME} /mnt/disks/${PV_NAME}
if [ $? -ne 0 ]; then
	echo "Failed to mount directory of /mnt/disks/${PV_NAME}"
	exit 1
fi

sudo echo '/var/disks/${PV_NAME}  /mnt/disks/${PV_NAME}  ext4  defaults  0  0' | sudo tee -a /etc/fstab
if [ $? -ne 0 ]; then
	echo "Failed to write /etc/fstab for ${PV_NAME}"
	exit 1
fi
