Setup CI machine
================

Setup WIFI on PC (Temporary before getting ethernet card)
---------------------------------------------------------

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
