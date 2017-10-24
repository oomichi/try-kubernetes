#!/bin/bash

# Operate remora!!
echo "Start to pip install.."
pip3 install -r requirements.txt
if [ $? -ne 0 ]; then
	echo "Failed to pip install"
	exit 1
fi

echo "Start to fab cluster render.."
fab cluster render
if [ $? -ne 0 ]; then
	echo "Failed to fab cluster render"
	exit 1
fi

echo "Start to fab cluster install.kubelet.."
fab cluster install.kubelet
if [ $? -ne 0 ]; then
	echo "Failed to fab cluster install.kubelet"
	exit 1
fi

echo "Start to fab cluster install.etcd.."
fab cluster install.etcd
if [ $? -ne 0 ]; then
	echo "Failed to fab cluster install.etcd"
	exit 1
fi

echo "Start to fab cluster install.bootstrap.."
fab cluster install.bootstrap
if [ $? -ne 0 ]; then
	echo "Failed to fab cluster install.bootstrap"
	exit 1
fi

echo "Start to fab cluster install.kubernetes.."
fab cluster install.kubernetes
if [ $? -ne 0 ]; then
	echo "Failed to fab cluster install.kubernetes"
	exit 1
fi

echo "Start to fab cluster config.."
fab cluster config
if [ $? -ne 0 ]; then
	echo "Failed to fab cluster config"
	exit 1
fi

echo "remora is done!!"

exit 0
