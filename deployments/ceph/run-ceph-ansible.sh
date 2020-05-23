#!/bin/bash

MONITOR_INTERFACE=${MONITOR_INTERFACE:-"eth0"}
PUBLIC_NETWORK=${PUBLIC_NETWORK}

if [ "${PUBLIC_NETWORK}" = "" ]; then
	echo 'Need to specify public network address like:'
	echo ''
	echo '  $ export PUBLIC_NETWORK="10.0.0.0/24"'
	echo '  $ ./run-ceph-ansible.sh'
	exit 1
fi
if [ "${MON_NODES}" = "" ]; then
	echo 'Need to specify monitor nodes like:'
	echo ''
	echo '  $ export MON_NODES="ceph-mon01 ceph-mon02"'
	echo '  $ ./run-ceph-ansible.sh'
	exit 1
fi
if [ "${MGR_NODES}" = "" ]; then
	echo 'Need to specify manage nodes like:'
	echo ''
	echo '  $ export MGR_NODES="ceph-mgr01 ceph-mgr02"'
	echo '  $ ./run-ceph-ansible.sh'
	exit 1
fi
if [ "${OSD_NODES}" = "" ]; then
	echo 'Need to specify osd nodes like:'
	echo ''
	echo '  $ export OSD_NODES="ceph-osd01 ceph-osd02 ceph-osd03"'
	echo '  $ ./run-ceph-ansible.sh'
	exit 1
fi
if [ "${DATA_DEVICE}" = "" ]; then
	echo 'Need to specify storage device on osd nodes.'
	echo 'NOTE: All osd nodes should have the same specified storage devices.'
	echo ''
	echo '  $ export DATA_DEVICE="/dev/sdb"'
	echo '  $ ./run-ceph-ansible.sh'
	exit 1
fi

for mon in ${MON_NODES}; do
	ping -c 1 ${mon}
	if [ $? -ne 0 ]; then
		echo "Node ${mon} in MON_NODES is not reachable"
		exit 1
	fi
done

# Create hosts
rm -f ./hosts
touch ./hosts
echo         "[mons]" >> ./hosts
for node in ${MON_NODES}; do
	echo "${node}" >> ./hosts
done
echo         "[mgrs]" >> ./hosts
for node in ${MGR_NODES}; do
	echo "${node}" >> ./hosts
done
echo         "[osds]" >> ./hosts
for node in ${OSD_NODES}; do
	echo "${node}" >> ./hosts
done

# Enable error handling
set -e

sudo yum -y install git python3-pip

PATH_THIS_SCRIPT=`pwd`
cd ~/
git clone https://github.com/ceph/ceph-ansible.git
cd ceph-ansible/

# ceph-ansible stable-5.0(For ceph version octopus) doesn't support CentOS7.
git checkout remotes/origin/stable-4.0

sudo pip3 install -r requirements.txt

cp ${PATH_THIS_SCRIPT}/files/all.yml                 group_vars/all.yml
sed -i s/"MONITOR_INTERFACE"/"${MONITOR_INTERFACE}"/ group_vars/all.yml
sed -i s@"PUBLIC_NETWORK"@"${PUBLIC_NETWORK}"@       group_vars/all.yml  # PUBLIC_NETWORK contains /, so we need to use another char here.

cp ${PATH_THIS_SCRIPT}/files/osds.yml     group_vars/osds.yml
sed -i s@"DATA_DEVICE"@"${DATA_DEVICE}"@  group_vars/osds.yml  # DATA?DEVICE contains /, so we need to use another char here.

cp site.yml.sample site.yml

# ansible-playbook -i ./hosts ./site.yml
