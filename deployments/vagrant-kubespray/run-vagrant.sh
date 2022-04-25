#!/bin/bash

set -e

vagrant plugin install vagrant-libvirt

cd
rm -rf ./venv-kubespray
python3 -m venv ./venv-kubespray
source venv-kubespray/bin/activate

if [ ! -d ./kubespray ]; then
    git clone https://github.com/kubernetes-sigs/kubespray
fi
cd kubespray
pip3 install -r requirements.txt
vagrant up
