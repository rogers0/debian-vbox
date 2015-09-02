#!/bin/sh

mdadm /dev/md0 --re-add /dev/sdb1
mdadm /dev/md1 --re-add /dev/sdb2
watch -n1 cat /proc/mdstat
