#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
if [ -e /etc/lvm/lvm.conf ] && ! getargbool 1 rd.lvm.conf -n rd_NO_LVMCONF; then
    rm -f /etc/lvm/lvm.conf
fi

if ! getargbool 1 rd.lvm -n rd_NO_LVM; then
    info "rd.lvm=0: removing LVM activation"
    rm -f /etc/udev/rules.d/64-lvm*.rules
else
    for dev in $(getargs rd.lvm.vg rd_LVM_VG=) $(getargs rd.lvm.lv rd_LVM_LV=); do
        printf '[ -e "/dev/%s" ] || return 1\n' $dev \
            >> $hookdir/initqueue/finished/lvm.sh
        {
            printf '[ -e "/dev/%s" ] || ' $dev
            printf 'warn "LVM "%s" not found"\n' $dev
        } >> $hookdir/emergency/90-lvm.sh
    done
fi

