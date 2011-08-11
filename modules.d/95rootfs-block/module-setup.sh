#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

depends() {
    echo fs-lib
}

install() {
    dracut_install umount
    inst_hook cmdline 95 "$moddir/parse-block.sh"
    inst_hook pre-udev 30 "$moddir/block-genrules.sh"
    inst_hook mount 99 "$moddir/mount-root.sh"
}

