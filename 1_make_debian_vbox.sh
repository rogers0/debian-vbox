#!/bin/bash

DISTRO=jessie

case "$DISTRO" in
"wheezy")
	ISOIMG=~/debian-7.9.0-i386-netinst.iso
	ISOURL=http://cdimage.debian.org/cdimage/archive/7.9.0/i386/iso-cd/debian-7.9.0-i386-netinst.iso
	;;
"jessie")
	ISOIMG=~/debian-8.2.0-i386-netinst.iso
	ISOURL=http://cdimage.debian.org/cdimage/release/8.2.0/i386/iso-cd/debian-8.2.0-i386-netinst.iso
	;;
"stretch"|"sid")
	ISOIMG=~/debian-stretch-DI-alpha2-i386-netinst.iso
	ISOURL=http://cdimage.debian.org/mirror/cdimage/stretch_di_alpha2/i386/iso-cd/debian-stretch-DI-alpha2-i386-netinst.iso
	;;
*)
	DISTRO=sid
	ISOIMG=~/debian-stretch-DI-alpha2-i386-netinst.iso
	ISOURL=http://cdimage.debian.org/mirror/cdimage/stretch_di_alpha2/i386/iso-cd/debian-stretch-DI-alpha2-i386-netinst.iso
	;;
esac

[ ! -f "$ISOIMG" ] && wget -O "$ISOIMG" "$ISOURL"

VM=vbox_$DISTRO
[ -d "$VM" ] && echo VM "$VM" exists already && exit 1

VBoxManage createvm --name $VM --ostype Debian --basefolder $(pwd) --register
#BRIDGE=$(/sbin/ifconfig|grep HWaddr|grep -v vboxnet|head -n1|awk '{print $1}')
#echo Bridge device: $BRIDGE
#VBoxManage modifyvm $VM --memory=256 --nic1=bridged --bridgeadapter1=$BRIDGE
VBoxManage modifyvm $VM --memory=256 --nic1=nat

VBoxManage storagectl $VM --add sata --portcount 2 --bootable on --name SATA
VBoxManage storagectl $VM --add ide --bootable on --name IDE
VBoxManage createhd --filename $VM/sata_dev --size 4096
VBoxManage createhd --filename $VM/pata_dev --size 4096
VBoxManage storageattach $VM --storagectl SATA --port 0 --type hdd --medium $VM/sata_dev.vdi
VBoxManage storageattach $VM --storagectl IDE --port 0 --device 0 --type hdd --medium $VM/pata_dev.vdi
VBoxManage storageattach $VM --storagectl IDE --port 1 --device 0 --type dvddrive --medium $ISOIMG

echo now start the VM: $VM
echo VBoxManage startvm $VM
VBoxManage startvm $VM
