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



rm -f ./hosts
echo "[targets]"  >  ./hosts
echo ${IPADDRESS} >> ./hosts

rm -f ./hostname.yaml
echo "- hosts: targets"                           >  ./hostname.yaml
echo "  become: true"                             >> ./hostname.yaml
echo "  become_user: root"                        >> ./hostname.yaml
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
echo "  - name: reboot"                      >> ./hostname.yaml
echo "    shell: sleep 2 && shutdown -r now" >> ./hostname.yaml
echo "    async: 1"                          >> ./hostname.yaml
echo "    poll: 0"                           >> ./hostname.yaml
echo "    ignore_errors: true"               >> ./hostname.yaml

ansible-playbook -i ./hosts --ask-become-pass hostname.yaml

rm -f ./hosts ./hostname.yaml

