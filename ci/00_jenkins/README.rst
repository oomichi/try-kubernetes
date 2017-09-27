TODO
====

Install ubuntu 16.04LTS for Raspberry PI 3(ARM)
-----------------------------------------------

* Download ubuntu-16.04-preinstalled-server-armhf+raspi3.img.xz
* $ xz -dv ubuntu-16.04-preinstalled-server-armhf+raspi3.img.xz
* Copy ubuntu-16.04-preinstalled-server-armhf to Windows PC
* Copy ubuntu-16.04-preinstalled-server-armhf+raspi3.img to a micro SD card with Win32DiskImager on Windows PC
* Insert the micro SD card into the raspberry pi
* Boot the raspberry pi
NOTE: The initial login username/password = ubuntu/ubuntu

Connect the pi to internet via WIFI
-----------------------------------

Upgrade to the latest ubuntu for avoiding kernel issues like [1].
Necessary to rename the existing brcm binary for raspi2 package for passing upgrade[2]::

 $ sudo apt-get update
 $ sudo dpkg-divert --divert /lib/firmware/brcm/brcmfmac43430-sdio-2.bin --package linux-firmware-raspi2 --rename --add /lib/firmware/brcm/brcmfmac43430-sdio.bin
 Adding diversion of /lib/firmware/brcm/brcmfmac4340-sdio.bin to /lib/firmware/brcm/brcmfmac4340-sdio-2.bin by linux-firmware-raspi2
 $ sudo apt-get upgrade

For example, the sample kernel version at this time is::

 $ uname -a

Install necessary network tools and setup::

 $ sudo apt-get install -y openssh-server wireless-tools wpasupplicant
 $ sudo reboot
 $ iwconfig
 wlan0     IEEE 802.11bgn  ESSID:off/any
           Mode:Managed  Access Point: Not-Associated
           Retry short limit:7   RTS thr:off   Fragment thr:off
           Power Management:on
 $
 $ sudo vi /etc/network/interfaces
 + allow-hotplug wlan0
 + iface wlan0 inet dhcp
 + wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
 $
 $ sudo vi /etc/wpa_supplicant/wpa_supplicant.conf
 + network={
 +     ssid="your-network-ssid-name"
 +     psk="your-network-password"
 + }
 $

Remove an ethernet cable and reboot the machine.
(TODO) The following error happens::
 brcmf_add_if: ERROR: netdev:wlan0 already exists
 brcmf_add_if: ignore IF event

Setup DHCP server on etherport side of Raspberry PI 3
-----------------------------------------------------

Operate the following::

 $ sudo apt-get install isc-dhcp-server
 $ sudo vi /etc/dhcp/dhcpd.conf
 Remove both lines of "option donaim-name" and "domain-name-servers"
 Remove # from #authoritative;
 Add the following part
 subnet 192.168.1.0 netmask 255.255.255.0 {
     range 192.168.1.100 192.168.1.200;
     option broadcast-address 192.168.1255;
     option routers 192.168.1.1;
     default-lease-time 600;
     max-lease-time 7200;
     option domain-name "local";
     option domain-name-servers 8.8.8.8, 8.8.4.4;
 }
 Change INTERFACE="" to INTERFACES="eth0"

TODO: Add static address configuration for eth0

Configure SNAT between internet and local network
-------------------------------------------------

[1]: https://github.com/raspberrypi/firmware/issues/620
[2]: https://bugs.launchpad.net/ubuntu/+source/linux-firmware-raspi2/+bug/1691729/comments/4
