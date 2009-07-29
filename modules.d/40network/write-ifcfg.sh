#!/bin/sh

# NFS root might have reached here before /tmp/net.ifaces was written
udevadm settle --timeout=30
# Don't write anything if we don't know our bootdev
[ -f /tmp/net.ifaces ] || return 1

read IFACES < /tmp/net.ifaces

for netif in $IFACES ; do
    mkdir -p /tmp/ifcfg/
    # bridge?
    unset bridge
    if [ "$netif" = "$bridgename" ]; then
        bridge=yes
    fi
    cat /sys/class/net/$netif/address > /tmp/net.$netif.hwaddr
    echo "# Generated by dracut initrd" > /tmp/ifcfg/ifcfg-$netif
    echo "DEVICE=$netif" >> /tmp/ifcfg/ifcfg-$netif
    echo "ONBOOT=yes" >> /tmp/ifcfg/ifcfg-$netif
    echo "NETBOOT=yes" >> /tmp/ifcfg/ifcfg-$netif
    if [ -f /tmp/net.$netif.lease ]; then
	echo "BOOTPROTO=dhcp" >> /tmp/ifcfg/ifcfg-$netif
    else
	echo "BOOTPROTO=none" >> /tmp/ifcfg/ifcfg-$netif
        # If we've booted with static ip= lines, the override file is there
	. /tmp/net.$netif.override 
	echo "IPADDR=$ip" >> /tmp/ifcfg/ifcfg-$netif
	echo "NETMASK=$mask" >> /tmp/ifcfg/ifcfg-$netif
	[ -n "$gw" ] && echo "GATEWAY=$gw" >> /tmp/ifcfg/ifcfg-$netif
    fi

    # bridge needs differente things written to ifcfg
    if [ -z "$bridge" ]; then
        # standard interface
        echo "HWADDR=$(cat /sys/class/net/$netif/address)" >> /tmp/ifcfg/ifcfg-$netif
        echo "TYPE=Ethernet" >> /tmp/ifcfg/ifcfg-$netif
        echo "NAME=\"Boot Disk\"" >> /tmp/ifcfg/ifcfg-$netif
    else
        # bridge
	echo "TYPE=Bridge" >> /tmp/ifcfg/ifcfg-$netif
        echo "NAME=\"Boot Disk\"" >> /tmp/ifcfg/ifcfg-$netif
        # write separate ifcfg file for the raw eth interface
        echo "DEVICE=$ethname" >> /tmp/ifcfg/ifcfg-$ethname
        echo "TYPE=Ethernet" >> /tmp/ifcfg/ifcfg-$ethname
        echo "ONBOOT=yes" >> /tmp/ifcfg/ifcfg-$ethname
        echo "NETBOOT=yes" >> /tmp/ifcfg/ifcfg-$ethname
        echo "HWADDR=$(cat /sys/class/net/$ethname/address)" >> /tmp/ifcfg/ifcfg-$ethname
        echo "BRIDGE=$netif" >> /tmp/ifcfg/ifcfg-$ethname
        echo "NAME=$ethname" >> /tmp/ifcfg/ifcfg-$ethname
    fi
done
