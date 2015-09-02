#/bin/sh

for i in $(find /sys |grep sectors_kb); do
	echo -e $(cat $i) \\t $i
done
