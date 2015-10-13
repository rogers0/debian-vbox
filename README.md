# debian-vbox: verification environment for [Debian Bug #624343](https://bugs.debian.org/624343)

I met this "bio too big device mdX (Y > Z)" issue on my system, too. So I spend some time on investigation, and here comes a workaround.

If you want to skip the long analysis part and just need the workaround/conclusion, here it is:
add an udev rule to the system, but the exact device name and value varies, which you have to figure out by yourself.
simply start from the command below to create a local file:

  echo 'ACTION=="add|change", KERNEL=="dm-[0-9]", ATTR{queue/max_sectors_kb}="128"' > /etc/udev/rules.d/80-fix-for-dm-queue-size.rules

If your setup is dm-crypt over raid like me, the "KERNEL" part can be kept as is. If LVM is involved, it's assumed to change the "dm-[0-9]" to something start from vg, I guess (I'm not sure because I don't use LVM)
And the number 128 in "ATTR" part is a proofed value that can fix the SATA/PATA virtual disk described afterwards. It's necessary to find the smallest "max_sectors_kb" of the related disks of that dm-crypt/RAID.

Simple workaround finishes here.

The root cause of this issue is the combination of the following case:
- stacked block devices, such as dm-crypt over RAID
- RAID on disks which has different queue size (e.g. HDD + USB HDD, or HDD + SSD, or PATA HDD + SATA HDD)
- RAID device with smaller queue size is inactive when dm-crypt is created
- when RAID device with smaller queue size is re-added to the RAID, dm-crypt device cannot get notified the change of queue size of lower device(the RAID), so dm-crypt will keep sending data exceeded the queue size of RAID device => ISSUE OCCURRED

So the possible fix may be one of them:
- let the RAID device be able to split the large data, and feed to the sub-device by their own queue size. But unfortunately, the patch by Kent Overstreet is not accepted by mainline yet [0] [1]. (But maybe soon [2], in Linux 4.3?)
- let dm-crypt or other block device get notified when queue size of lower layer get changed. By polling? It's not effective at all. By callback? There's no existing API for the time being.
- Limit the queue size of dm-crypt by the end-user. Thanks to the sysfs, this can be done in userland => This is my so-called "workaround".

So, let me introduce my reproducing/verification environment under virtualbox.
Scripts are on github: https://github.com/rogers0/debian-vbox
Please run script by the number in filename.

0. install virtualbox
1. install a guest os for reproduce the issue.
        ````1_make_debian_vbox.sh````
2. some "webm" videos explain how to setup the RAID/DM and install grub for boot.
    It need to consist a "dm-crypt" device on top of a RAID-1 over one SATA HDD, which queue size is 512kb, and one PATA HDD, which queue size is 128kb. (queue size is from wheezy rootfs + wheezy-backports 3.16 kernel)
    And please install grub to both /dev/sda and /dev/sdb, if not, it may need to press F12 and press "2" to boot the OS
3. scripts to run within guest os
    run "1_init.sh" after first boot. You need full path of script only here because 1_init.sh will add the path to ~/.bashrc
        `apt-get install -y git
        git clone https://github.com/rogers0/debian-vbox
        debian-vbox/3_script_within_guest_os/1_init.sh`
    I intentionally modified /etc/initramfs-tools/modules and /dev/mdadm/mdadm.conf, in order not to load the PATA kernel driver in initramfs booting stage, so let the RAID-1 only has one SATA drive after every boot.
    In this way the queue size of dm-crypt will be the same as SATA HDD, 512kb.
    After 2nd boot, "3_script_within_guest_os" is already in PATH, so simply run:
        `show-sectors_kb.sh
        raid1_resync.sh
        show-sectors_kb.sh`
   "show-sectors_kb.sh" is to check the queue size of each block device, while "raid1_resync.sh" is to add PATA HDD back to the RAID-1.
   So comparing result of "show-sectors_kb.sh" before/after "raid1_resync.sh", the queue size of RAID-1 is changed correctly, but not for dm-crypt's.
   Then time to run the test script to reproduce:
        `dmesg  
        test_block_device.sh  
        dmesg`
    Now you can see the "bio too big device mdX (Y > Z)" kernel error.
    So you can try the workaround after a reboot.
        `fix_udev.sh  
        reboot.sh`
        [wait for reboot and login again]
        `show-sectors_kb.sh  
        raid1_resync.sh  
        show-sectors_kb.sh  
        dmesg  
        test_block_device.sh  
        dmesg`
    I think you don't see the kernel error now.

For other system, the actual queue size can be found by running script "test_block_device.sh" or the one line command:
    `for i in $(find /sys |grep sectors_kb); do echo -e $(cat $i) \\t $i; done`

Reference:
[0] https://www.redhat.com/archives/dm-devel/2012-May/msg00159.html  
[1] http://thread.gmane.org/gmane.linux.kernel/1656433  
[2] https://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/commit/?id=54efd50bfd873e2dbf784e0b21a8027ba4299a3e
