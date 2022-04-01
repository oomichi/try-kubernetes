#!/bin/bash

set -e

# Use hashicorp official instead of ubuntu official because of the new version.
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt update
sudo apt install vagrant

# Install vagrant-libvirt
sudo apt install libvirt-dev build-essential
vagrant plugin install vagrant-libvirt

