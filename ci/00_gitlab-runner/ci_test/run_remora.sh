#!/bin/bash

# Operate remora!!
pip3 install -r requirements.txt
if [ $? -ne 0 ]; then
	echo "Failed to pip install"
	exit 1
fi

fab cluster render
if [ $? -ne 0 ]; then
	echo "Failed to fab cluster render"
	exit 1
fi

fab cluster install.kubelet
if [ $? -ne 0 ]; then
	echo "Failed to fab cluster install.kubelet"
	exit 1
fi

fab cluster install.etcd
if [ $? -ne 0 ]; then
	echo "Failed to fab cluster install.etcd"
	exit 1
fi

fab cluster install.bootstrap
if [ $? -ne 0 ]; then
	echo "Failed to fab cluster install.bootstrap"
	exit 1
fi

fab cluster install.kubernetes
if [ $? -ne 0 ]; then
	echo "Failed to fab cluster install.kubernetes"
	exit 1
fi

exit 0
