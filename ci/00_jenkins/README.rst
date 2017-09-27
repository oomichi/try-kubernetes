TODO
====

Configure a gate machine (raspberry pi)
---------------------------------------

1. Install ubuntu 16.04LTS for ARM[1].

* Download ubuntu-16.04-preinstalled-server-armhf+raspi3.img.xz
* $ xz -dv ubuntu-16.04-preinstalled-server-armhf+raspi3.img.xz
* Copy ubuntu-16.04-preinstalled-server-armhf to Windows PC
* Copy ubuntu-16.04-preinstalled-server-armhf+raspi3.img to a micro SD card with Win32DiskImager on Windows PC
* Insert the micro SD card into the raspberry pi
* Boot the raspberry pi

2. Connect the pi to internet via WIFI[2]

Install necessary network tools and setup::

 $ sudo apt-get update
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

3. Connect the pi ethernet port to a network switch which manages clusters.
4. Configure DHCP on the ethernet side.
5. Configure SNAT between internet and local network.


[1]: http://gihyo.jp/admin/serial/01/ubuntu-recipe/0450
[2]: https://medium.com/a-swift-misadventure/how-to-setup-your-raspberry-pi-2-3-with-ubuntu-16-04-without-cables-headlessly-9e3eaad32c01

