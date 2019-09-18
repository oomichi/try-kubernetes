Make preseed DVD for avoiding DHCP configuration on company network
===================================================================

How to create the preseed DVD::

 $ sudo apt-get -y install syslinux mtools mbr genisoimage dvd+rw-tools
 $ mkdir mk-preseed
 $ cd mk-preseed/
 $ mkdir dvd
 $ wget http://releases.ubuntu.com/18.04/ubuntu-18.04.3-live-server-amd64.iso
 $ sudo mount -t iso9660 ubuntu-18.04.3-live-server-amd64.iso ./dvd
 $ mkdir tmp
 $ cd dvd
 $ find . ! -type l | cpio -pdum ../tmp/
 $ cd ../tmp/
 $ vi isolinux/isolinux.cfg   <Change like the file which is contained in this repo>
 $ vi preseed/preseed.txt     <Change like the file which is contained in this repo>
 $ sudo genisoimage -N -J -R -D -o ../ubuntu16.04preseed.iso -V "ubuntu16.04preseed" -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table .

