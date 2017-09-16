#!/bin/sh

IPADDRESS=$1
if [ -z "${IPADDRESS}" ]; then
	echo "Need to specify IP address of the target machine"
	exit 1
fi
NEW_HOSTNAME=$2
if [ -z "${NEW_HOSTNAME}" ]; then
	echo "Need to specify new hostname of the target machine"
	exit 1
fi



rm -f hosts
echo "[targets]"  >  ./inventory/hosts
echo ${IPADDRESS} >> ./inventory/hosts

rm -f ./hostname.yaml
echo "- hosts: targets"                           >  ./hostname.yaml
echo "  sudo: yes"                                >> ./hostname.yaml
echo "  user: ubuntu"                             >> ./hostname.yaml
echo "  tasks:"                                   >> ./hostname.yaml
echo "  - name: change hostname to ${NEW_HOSTNAME}" >> ./hostname.yaml
echo "    hostname:"                                >> ./hostname.yaml
echo "      name: ${NEW_HOSTNAME}"                  >> ./hostname.yaml
echo "  - name: add myself to /etc/hosts"           >> ./hostname.yaml
echo "    lineinfile:"                              >> ./hostname.yaml
echo "      dest: /etc/hosts"                       >> ./hostname.yaml

# To keep backslash in hostname.yaml, here uses /bin/echo instead of build-in
/bin/echo -E "      regexp: '^127\.0\.0\.1[ \t]+localhost'" >> ./hostname.yaml

echo "      line: '127.0.0.1 localhost ${NEW_HOSTNAME}'"    >> ./hostname.yaml
echo "      state: present"                                 >> ./hostname.yaml

