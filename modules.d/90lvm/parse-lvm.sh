#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
if [ -e /etc/lvm/lvm.conf ] && ! getargbool 1 rd.lvm.conf -d -n rd_NO_LVMCONF; then
    rm -f /etc/lvm/lvm.conf
fi

LV_DEVS="$(getargs rd.lvm.vg -d rd_LVM_VG=) $(getargs rd.lvm.lv -d rd_LVM_LV=)"

if ! getargbool 1 rd.lvm -d -n rd_NO_LVM \
    || ( [ -z "$LV_DEVS" ] && ! getargbool 0 rd.auto ); then
    info "rd.lvm=0: removing LVM activation"
    rm -f /etc/udev/rules.d/64-lvm*.rules
else
    for dev in $LV_DEVS; do
        wait_for_dev "/dev/$dev"
    done
fi

