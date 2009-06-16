#!/bin/sh

# Don't write anything if we don't know our bootdev
[ -f /tmp/net.bootdev ] || return 1

read netif < /tmp/net.bootdev

cat /sys/class/net/$netif/address > /tmp/net.$netif.hwaddr
echo "# Generated by dracut initrd" > /tmp/net.$netif.ifcfg
echo "DEVICE=$netif" >> /tmp/net.$netif.ifcfg
echo "HWADDR=$(cat /sys/class/net/$netif/address)" >> /tmp/net.$netif.ifcfg
echo "TYPE=Ethernet" >> /tmp/net.$netif.ifcfg
echo "ONBOOT=yes" >> /tmp/net.$netif.ifcfg
if [ -f /tmp/net.$netif.lease ]; then
    echo "BOOTPROTO=dhcp" >> /tmp/net.$netif.ifcfg
else
    echo "BOOTPROTO=none" >> /tmp/net.$netif.ifcfg
    # Static: XXX Implement me!
    #IPADDR=172.16.101.1
    #NETMASK=255.255.255.0
    #DNS1=1.2.3.4
    #DNS2=1.2.3.5
    #GATEWAY=172.16.101.254
fi
