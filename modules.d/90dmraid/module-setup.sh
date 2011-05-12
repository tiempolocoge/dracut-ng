#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    local _rootdev
    # if we don't have dmraid installed on the host system, no point
    # in trying to support it in the initramfs.
    type -P dmraid >/dev/null || return 1

    . $dracutfunctions
    [[ $debug ]] && set -x

    is_dmraid() { get_fs_type /dev/block/$1 |grep -v linux_raid_member | \
        grep -q _raid_member; }

    [[ $hostonly ]] && {
        _rootdev=$(find_root_block_device)
        if [[ $_rootdev ]]; then
        # root lives on a block device, so we can be more precise about
        # hostonly checking
            check_block_and_slaves is_dmraid "$_rootdev" || return 1
        else
        # root is not on a block device, use the shotgun approach
            dmraid -r | grep -q ok || return 1
        fi
    }

    return 0
}

depends() {
    echo dm rootfs-block
    return 0
}

install() {
    local _i
    dracut_install dmraid partx kpartx

    inst  dmeventd

    for _i in {"$libdir","$usrlibdir"}/libdmraid-events*.so; do
        [ -e "$_i" ] && dracut_install "$_i"
    done

    inst_rules 10-dm.rules 13-dm-disk.rules 95-dm-notify.rules
    # Gentoo ebuild for LVM2 prior to 2.02.63-r1 doesn't install above rules
    # files, but provides the one below:
    inst_rules 64-device-mapper.rules

    inst "$moddir/dmraid.sh" /sbin/dmraid_scan

    if [ ! -x /lib/udev/vol_id ]; then
        inst_rules 64-md-raid.rules
    fi

    inst_rules "$moddir/61-dmraid-imsm.rules"
    inst "$moddir/dmraid-cleanup.sh" /sbin/dmraid-cleanup
    inst_hook pre-trigger 30 "$moddir/parse-dm.sh"

}

