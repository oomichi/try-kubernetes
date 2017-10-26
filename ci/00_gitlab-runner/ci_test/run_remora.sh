#!/bin/bash

LAST_LINE=`tail -n1 ./github_history.txt`
LAST_COMMIT=`echo ${LAST_LINE} | awk -F "/" '{print $NF}'`
GIT_URL=`echo ${LAST_LINE} | sed s@"/commit/${LAST_COMMIT}"@@`
GIT_DIRNAME=`echo ${GIT_URL} | awk -F "/" '{print $NF}'`

cd ./${GIT_DIRNAME}

# It is possible that the latest commit of the target repo is different from LAST_COMMIT
# when poll_github.sh detects multiple differences between the target repo and this test
# kicking repo.
git checkout ${LAST_COMMIT}

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

cd ..

echo "remora is done!!"

exit 0
