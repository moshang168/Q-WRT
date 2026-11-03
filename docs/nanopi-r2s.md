# NanoPi R2S firmware

The Q-WRT NanoPi R2S build is based on OpenWrt 25.12.6 and produces a complete
Rockchip SD-card disk image named `*friendlyarm_nanopi-r2s*sysupgrade.img.gz`.
This is a gzip-compressed disk image with the Rockchip bootloader area, boot
partition, kernel, and root filesystem. Decompress it before writing it to a
microSD card with a disk-image writer. Do not upload the `.img.gz` file to the
LuCI web upgrade page.

After the first boot, connect the management computer to the R2S LAN port
(`eth1`). The WAN port is `eth0`.

- Web management: `http://192.168.2.1` (Chinese LuCI)
- LAN subnet: `192.168.2.0/24`
- DHCP pool: `192.168.2.100`–`192.168.2.249`
- SSH: Dropbear on the LAN interface, user `root`

The image includes the Chinese LuCI interface, HTTPS support, Dropbear, DHCP,
firewall, and the USB Ethernet driver.
