#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    local _rootdev
    # If our prerequisites are not met, fail anyways.
    type -P iscsistart hostname iscsi-iname >/dev/null || return 1

    # If hostonly was requested, fail the check if we are not actually
    # booting from root.

    . $dracutfunctions

    [[ $debug ]] && set -x

    is_iscsi() (
        [[ -L /sys/dev/block/$1 ]] || return
        cd "$(readlink -f /sys/dev/block/$1)"
        until [[ -d sys || -d iscsi_session ]]; do
            cd ..
        done
        [[ -d iscsi_session ]]
    )

    [[ $hostonly ]] && {
        _rootdev=$(find_root_block_device)
        if [[ $_rootdev ]]; then
            # root lives on a block device, so we can be more precise about
            # hostonly checking
            check_block_and_slaves is_iscsi "$_rootdev" || return 1
        else
            return 1
        fi
    }
    return 0
}

depends() {
    echo network rootfs-block
}

installkernel() {
    instmods iscsi_tcp iscsi_ibft crc32c
    iscsi_module_test() {
        local _iscsifuncs='iscsi_register_transport'
        fgrep -q "$_iscsifuncs" "$1"
    }
    instmods $(filter_kernel_modules_by_path drivers/scsi iscsi_module_test)
}

install() {
    dracut_install umount
    inst iscsistart
    inst hostname
    inst iscsi-iname
    inst_hook cmdline 90 "$moddir/parse-iscsiroot.sh"
    inst "$moddir/iscsiroot" "/sbin/iscsiroot"
    inst "$moddir/mount-lun.sh" "/bin/mount-lun.sh"
}
