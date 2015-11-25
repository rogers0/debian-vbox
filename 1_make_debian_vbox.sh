#!/bin/bash

DISTRO=jessie
#ARCH=amd64
RAID=1
BRIDGE=1
MEMORY=256
STORAGE=4096

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
	ISOIMG=~/debian-stretch-DI-alpha3-i386-netinst.iso
	ISOURL=http://cdimage.debian.org/cdimage/stretch_di_alpha4/i386/iso-cd/debian-stretch-DI-alpha4-i386-netinst.iso
	;;
"kfreebsd")
	ISOIMG=~/mini.iso
	ISOURL=http://d-i.debian.org/daily-images/kfreebsd-i386/daily/netboot-10/mini.iso
	;;
*)
	DISTRO=sid
	ISOIMG=~/debian-stretch-DI-alpha3-i386-netinst.iso
	ISOURL=http://cdimage.debian.org/cdimage/stretch_di_alpha4/i386/iso-cd/debian-stretch-DI-alpha4-i386-netinst.iso
	;;
esac

OSTYPE=Debian
if [ $ARCH != "i386" ]; then
	ISOIMG=${ISOIMG/i386/$ARCH}
	ISOURL=${ISOURL/i386/$ARCH}; ISOURL=${ISOURL/i386/$ARCH}
	[ $ARCH = "amd64" ] &&
		OSTYPE=Debian_64
fi

[ ! -f "$ISOIMG" ] && wget -O "$ISOIMG" "$ISOURL"

VM=vbox_${DISTRO}
[ -d "$VM" ] && echo VM "$VM" exists already && exit 1

VBoxManage createvm --name $VM --ostype $OSTYPE --basefolder $(pwd) --register
if [ $BRIDGE -eq 1 ]; then
	BRIDGE=$(/sbin/ifconfig|grep HWaddr|grep -v vboxnet|head -n1|awk '{print $1}')
	echo Bridge device: $BRIDGE
	VBoxManage modifyvm $VM --memory=$MEMORY --nic1=bridged --bridgeadapter1=$BRIDGE
else
	VBoxManage modifyvm $VM --memory=$MEMORY --nic1=nat
fi

VBoxManage storagectl $VM --add sata --portcount 2 --bootable on --name SATA
VBoxManage storagectl $VM --add ide --bootable on --name IDE
VBoxManage createhd --filename $VM/sata_dev --size $STORAGE
VBoxManage storageattach $VM --storagectl SATA --port 0 --type hdd --medium $VM/sata_dev.vdi
if [ $RAID -eq 1 ]; then
	VBoxManage createhd --filename $VM/pata_dev --size $STORAGE
	VBoxManage storageattach $VM --storagectl IDE --port 0 --device 0 --type hdd --medium $VM/pata_dev.vdi
fi
VBoxManage storageattach $VM --storagectl IDE --port 1 --device 0 --type dvddrive --medium $ISOIMG

echo now start the VM: $VM
echo VBoxManage startvm $VM
VBoxManage startvm $VM
