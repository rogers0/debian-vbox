#!/bin/sh

echo mdadm /dev/md0 --re-add /dev/sdb1
mdadm /dev/md0 --re-add /dev/sdb1
echo mdadm /dev/md1 --re-add /dev/sdb2
mdadm /dev/md1 --re-add /dev/sdb2

watch -n1 cat /proc/mdstat
