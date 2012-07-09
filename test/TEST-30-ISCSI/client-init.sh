#!/bin/sh
export PATH=/sbin:/bin:/usr/sbin:/usr/bin
exec >/dev/console 2>&1
export TERM=linux
export PS1='initramfs-test:\w\$ '
stty sane
echo "made it to the rootfs! Powering down."
while read dev fs fstype opts rest; do
    [ "$fstype" != "ext3" ] && continue
    echo "iscsi-OK $dev $fstype $opts" > /dev/sda
    break
done < /proc/mounts
#sh -i
poweroff -f
