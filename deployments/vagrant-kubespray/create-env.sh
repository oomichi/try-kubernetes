#!/bin/bash

set -e

# Use hashicorp official instead of ubuntu official because of the new version.
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt update
sudo apt -y install vagrant

sudo apt -y install libvirt-daemon virt-manager
sudo systemctl restart libvirtd

sudo adduser ${USER} libvirt
sudo adduser ${USER} kvm

# Install vagrant-libvirt
sudo apt -y install libvirt-dev build-essential python3-venv
vagrant plugin install vagrant-libvirt
