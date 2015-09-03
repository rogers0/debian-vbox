#!/bin/sh

TARGET=/opt/blah.bin

clear_cache() {
	sync; sync; sync
	# free pagecache, dentries and inodes. should be non-destructive
	echo 'sync; echo 3 > /proc/sys/vm/drop_caches'
	sync; echo 3 > /proc/sys/vm/drop_caches
}

clear_cache
echo dd if=/dev/zero of=$TARGET bs=1M count=10
dd if=/dev/zero of=$TARGET bs=1M count=10
clear_cache

echo md5sum $TARGET
md5sum $TARGET
