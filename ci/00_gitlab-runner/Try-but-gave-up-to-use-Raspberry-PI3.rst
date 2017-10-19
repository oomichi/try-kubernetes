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
 $ sudo reboot

After that, another issue is faced::

 Filename 'boot.src.uimg'.
 Load address :0x20000000
 Loading:
 TFTP error:'illegal (unrecognized) tftp operation' (4)
 Starting again

 U-Boot>

So I gave up to use raspberry pi to avoid wasting time anymore.

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

[1]: https://github.com/raspberrypi/firmware/issues/620
[2]: https://bugs.launchpad.net/ubuntu/+source/linux-firmware-raspi2/+bug/1691729/comments/4
