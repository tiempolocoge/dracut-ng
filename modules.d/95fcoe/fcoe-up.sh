#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# We get called like this:
# fcoe-up <network-device> <dcb|nodcb>
#
# Note currently only nodcb is supported, the dcb option is reserved for
# future use.

PATH=/usr/sbin:/usr/bin:/sbin:/bin

# Huh? Missing arguments ??
[ -z "$1" -o -z "$2" ] && exit 1

export PS4="fcoe-up.$1.$$ + "
exec >>/run/initramfs/loginit.pipe 2>>/run/initramfs/loginit.pipe
type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh
type ip_to_var >/dev/null 2>&1 || . /lib/net-lib.sh

netif=$1
dcb=$2

linkup "$netif"

netdriver=$(readlink -f /sys/class/net/$netif/device/driver)
netdriver=${netdriver##*/}

if [ "$dcb" = "dcb" ]; then
    # Note lldpad will stay running after switchroot, the system initscripts
    # are to kill it and start a new lldpad to take over. Data is transfered
    # between the 2 using a shm segment
    lldpad -d
    # stupid tools, need sleep
    sleep 1
    dcbtool sc "$netif" dcb on
    sleep 1
    dcbtool sc "$netif" app:fcoe e:1 a:1 w:1
    sleep 1
    fipvlan "$netif" -c -s
elif [ "$netdriver" = "bnx2x" ]; then
    # If driver is bnx2x, do not use /sys/module/fcoe/parameters/create but fipvlan
    modprobe 8021q
    udevadm settle --timeout=30
    # Sleep for 3 s to allow dcb negotiation
    sleep 3
    fipvlan "$netif" -c -s
else
    echo -n "$netif" > /sys/module/fcoe/parameters/create
fi

need_shutdown
