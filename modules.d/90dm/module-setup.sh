#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    return 255
}

depends() {
    return 0
}

installkernel() {
    instmods =drivers/md
}

install() {
    modinfo -k $kernel dm_mod >/dev/null 2>&1 && \
        inst_hook pre-udev 30 "$moddir/dm-pre-udev.sh"

    inst dmsetup

    type -P dmeventd >/dev/null && dracut_install dmeventd
    inst_rules 10-dm.rules 95-dm-notify.rules
    # Gentoo ebuild for LVM2 prior to 2.02.63-r1 doesn't install above rules
    # files, but provides the one below:
    inst_rules 64-device-mapper.rules
    inst_rules "$moddir/11-dm.rules"

    inst_hook shutdown 30 "$moddir/dm-shutdown.sh"
}

