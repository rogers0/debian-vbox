#!/bin/sh

echo 'sync; sync; sync; sleep 2'
sync; sync; sync; sleep 2
echo mdadm /dev/md0 --fail /dev/sdb1 --remove /dev/sdb1
mdadm /dev/md0 --fail /dev/sdb1 --remove /dev/sdb1
echo mdadm /dev/md1 --fail /dev/sdb2 --remove /dev/sdb2
mdadm /dev/md1 --fail /dev/sdb2 --remove /dev/sdb2
cat /proc/mdstat

reboot
