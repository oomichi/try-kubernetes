#!/bin/bash

set -e

cd
python3 -m venv ./venv-kubespray
source venv-kubespray/bin/activate

git clone https://github.com/kubernetes-sigs/kubespray
cd kubespray
pip3 install -r requirements.txt
vagrant up
