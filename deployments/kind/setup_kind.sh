#!/bin/bash


egrep "CentOS|RHEL" /etc/os-release
if [ $? -eq 0 ]; then
	CENTOS=TRUE
else
	CENTOS=""
fi

go version
if [ $? -ne 0 ]; then
	set -e
	echo "Installing golang.."
	wget https://golang.org/dl/go1.14.7.linux-amd64.tar.gz
	sudo tar -C /usr/local/ -xzf go1.14.7.linux-amd64.tar.gz
	rm go1.14.7.linux-amd64.tar.gz
	export PATH=$PATH:/usr/local/go/bin:${HOME}/go/bin
	echo "export PATH=$PATH:/usr/local/go/bin:${HOME}/go/bin" >> ${HOME}/.bashrc
	sudo ln -s /usr/local/go/bin/go /usr/local/bin/go
	mkdir ${HOME}/go
	export GOPATH=${HOME}/go
	echo "export GOPATH=${HOME}/go" >> ${HOME}/.bashrc

	if [ -z "${CENTOS}" ]; then
		sudo apt-get install -y docker.io gcc make
	else
		sudo yum install -y docker docker-client gcc make
		sudo systemctl start docker
	fi
fi

set -e
GO111MODULE="on" go get sigs.k8s.io/kind@v0.8.1

# sudo ${HOME}/go/bin/kind create cluster
