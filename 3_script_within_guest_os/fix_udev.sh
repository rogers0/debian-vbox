#!/bin/sh

echo 'ACTION=="add|change", KERNEL=="dm-[0-9]", ATTR{queue/max_sectors_kb}="128"' > /etc/udev/rules.d/80-local.rules
