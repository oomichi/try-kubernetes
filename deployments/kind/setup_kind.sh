#!/bin/bash

set -e

go version
if [ $? -ne 0 ]; then
	echo "Installing golang.."
	wget https://golang.org/dl/go1.14.7.linux-amd64.tar.gz
	sudo tar -C /usr/local/ -xzf go1.14.7.linux-amd64.tar.gz
	rm go1.14.7.linux-amd64.tar.gz
	export PATH=$PATH:/usr/local/go/bin
	echo "export PATH=$PATH:/usr/local/go/bin" >> ${HOME}/.bashrc
	sudo ln -s /usr/local/go/bin/go /usr/local/bin/go

	mkdir ${HOME}/go
	export GOPATH=${HOME}/go
	echo "export GOPATH=${HOME}/go" >> ${HOME}/.bashrc

	sudo apt-get install -y docker.io gcc make
fi

GO111MODULE="on" go get sigs.k8s.io/kind@v0.8.1

#kind create cluster