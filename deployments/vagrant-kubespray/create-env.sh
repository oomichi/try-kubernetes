#!/bin/bash

set -e

# Use hashicorp official instead of ubuntu official because of the new version.
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt update
sudo apt -y install vagrant

# Install vagrant-libvirt
sudo apt -y install libvirt-dev build-essential python3-venv
vagrant plugin install vagrant-libvirt

cd
python3 -m venv ./venv-kubespray
source venv-kubespray/bin/activate

git clone https://github.com/kubernetes-sigs/kubespray
cd kubespray
pip3 install -r requirements.txt
vagrant up
