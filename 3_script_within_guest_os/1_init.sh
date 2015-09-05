#!/bin/bash

SCRIPT_ROOT=$(readlink -f $(dirname $0))

touch /opt; sync # to let /dev/md1 get out of read-only status
mdadm -G /dev/md0 -b internal --bitmap-chunk=4096
mdadm -G /dev/md1 -b internal --bitmap-chunk=4096
if ! grep ^DEVICE /etc/mdadm/mdadm.conf &> /dev/null; then
	echo 'DEVICE /dev/sda[12]' >> /etc/mdadm/mdadm.conf
fi

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

if grep wheezy /etc/apt/sources.list &> /dev/null; then
	if ! grep wheezy-backports /etc/apt/sources.list &> /dev/null; then
		echo 'deb http://httpredir.debian.org/debian wheezy-backports main' >>  /etc/apt/sources.list
		echo 'APT::Default-Release "wheezy";' > /etc/apt/apt.conf.d/80-local.conf
		apt-get update
	fi
	apt-get install -t wheezy-backports --no-install-recommends -y linux-image-686-pae
elif grep jessie /etc/apt/sources.list &> /dev/null; then
	if ! grep sid /etc/apt/sources.list &> /dev/null; then
		echo 'deb http://httpredir.debian.org/debian sid main' >>  /etc/apt/sources.list
		echo 'APT::Default-Release "jessie";' > /etc/apt/apt.conf.d/80-local.conf
		apt-get update
	fi
	apt-get install -t sid --no-install-recommends -y linux-image-686-pae
fi
apt-get install --no-install-recommends -y rsync git vim-nox vim-tiny-
apt-get autoremove -y
if ! grep mdadm /etc/rc.local &> /dev/null; then
	sed -i 's:exit 0:#mdadm /dev/md0 --re-add /dev/sdb1\n#mdadm /dev/md1 --re-add /dev/sdb2\n\n&:' /etc/rc.local
fi

if ! grep 3_script_within_guest_os ~/.bashrc &> /dev/null; then
	echo export PATH=$SCRIPT_ROOT:'$PATH' >> ~/.bashrc
fi

$SCRIPT_ROOT/break_raid1.sh
echo
echo Now it\'s now to reboot: reboot
echo But from next time, it\'s better to reboot by: reboot.sh
