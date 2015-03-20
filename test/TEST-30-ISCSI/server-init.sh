#!/bin/sh
exec </dev/console >/dev/console 2>&1
set -x
export PATH=/sbin:/bin:/usr/sbin:/usr/bin
export TERM=linux
export PS1='nfstest-server:\w\$ '
stty sane
echo "made it to the rootfs!"
echo server > /proc/sys/kernel/hostname
ip addr add 127.0.0.1/8 dev lo
ip link set lo up
ip link set dev eth0 name ens3
ip addr add 192.168.50.1/24 dev ens3
ip link set ens3 up
>/var/lib/dhcpd/dhcpd.leases
chmod 777 /var/lib/dhcpd/dhcpd.leases
dhcpd -d -cf /etc/dhcpd.conf -lf /var/lib/dhcpd/dhcpd.leases &
/usr/sbin/iscsi-target -D -t iqn.2009-06.dracut &
# Wait forever for the VM to die
echo "Serving iSCSI"
while :; do
	[ -n "$(jobs -rp)" ] && echo > /dev/watchdog
	sleep 10
done
mount -n -o remount,ro /
poweroff -f
