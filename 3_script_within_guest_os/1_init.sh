#!/bin/bash

mdadm -G /dev/md0 -b internal --bitmap-chunk=4096
mdadm -G /dev/md1 -b internal --bitmap-chunk=4096
#if ! grep ^DEVICE /etc/mdadm/mdadm.conf &> /dev/null; then
#	echo 'DEVICE /dev/sda[12]' >> /etc/mdadm/mdadm.conf
#fi

if grep MODULES=most /etc/initramfs-tools/initramfs.conf &> /dev/null; then
	sed -i /MODULES=/s/most/list/ /etc/initramfs-tools/initramfs.conf
	cat << EOL >> /etc/initramfs-tools/modules
sd_mod
ahci
raid1
#ata_piix
EOL
FS=$(grep " / " /proc/mounts |grep -v rootfs|awk '{print $3}')
echo $FS >> /etc/initramfs-tools/modules
[ "$FS" = "btrfs" ] && echo crc32c_generic >> /etc/initramfs-tools/modules
fi
update-initramfs -u

if ! grep wheezy-backports /etc/apt/sources.list &> /dev/null; then
	echo 'deb http://httpredir.debian.org/debian wheezy-backports main' >>  /etc/apt/sources.list
	apt-get update
fi
apt-get install --no-install-recommends -y rsync vim-nox vim-tiny-
apt-get install -t wheezy-backports --no-install-recommends -y linux-image-686-pae
apt-get autoremove -y
sed -i 's:exit 0:#mdadm /dev/md0 --re-add /dev/sdb1\n#mdadm /dev/md1 --re-add /dev/sdb2\n\n&:' /etc/rc.local

if ! grep 3_script_within_guest_os ~/.bashrc &> /dev/null; then
	echo 'export PATH=$PATH:~/3_script_within_guest_os' >> ~/.bashrc
fi

sync; sync; sync
