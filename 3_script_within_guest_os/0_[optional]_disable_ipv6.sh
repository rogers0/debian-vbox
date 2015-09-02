#!/bin/bash

sed -i '/GRUB_CMDLINE_LINUX/s/""/"ipv6.disable=1"/;/GRUB_TIMEOUT/s/5/1/' /etc/default/grub
sysctl net.ipv6.conf.eth0.disable_ipv6=1
