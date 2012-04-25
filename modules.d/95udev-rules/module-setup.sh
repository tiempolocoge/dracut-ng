#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

install() {
    local _i
    # FIXME: would be nice if we didn't have to know which rules to grab....
    # ultimately, /lib/initramfs/rules.d or somesuch which includes links/copies
    # of the rules we want so that we just copy those in would be best
    dracut_install udevadm
    [ -d ${initdir}/lib/systemd ] || mkdir -p ${initdir}/lib/systemd
    for _i in /lib/systemd/systemd-udevd /lib/udev/udevd /sbin/udevd; do
        [ -x "$_i" ] || continue
        inst "$_i"
        [[ $_i != "/lib/systemd/systemd-udevd" ]] \
            && ln -s "$_i" ${initdir}/lib/systemd/systemd-udevd
        break
    done

    for i in /etc/udev/udev.conf /etc/group; do
        inst_simple $i
    done

    dracut_install basename

    inst_rules 50-udev-default.rules 60-persistent-storage.rules \
        61-persistent-storage-edd.rules 80-drivers.rules 95-udev-late.rules \
        60-pcmcia.rules
    #Some debian udev rules are named differently
    inst_rules 50-udev.rules 95-late.rules

    # for firmware loading
    inst_rules 50-firmware.rules
    dracut_install cat uname


    inst_dir /run/udev
    inst_dir /run/udev/rules.d

    if [ ! -x /lib/udev/vol_id ]; then
        dracut_install blkid
        inst_rules "$moddir/59-persistent-storage.rules"
    else
        inst_rules "$moddir/59-persistent-storage-volid.rules"
    fi
    inst_rules "$moddir/61-persistent-storage.rules"

    for _i in \
        ata_id \
        cdrom_id \
        create_floppy_devices \
        edd_id \
        firmware.sh \
        firmware \
        firmware.agent \
        hotplug.functions \
        fw_unit_symlinks.sh \
        hid2hci \
        path_id \
        input_id \
        scsi_id \
        usb_id \
        vol_id \
        pcmcia-socket-startup \
        pcmcia-check-broken-cis \
        ; do
        [ -e /lib/udev/$_i ] && dracut_install /lib/udev/$_i
        [ -e /usr/lib/udev/$_i ] && dracut_install /usr/lib/udev/$_i
    done

    [ -f /etc/arch-release ] && \
        inst "$moddir/load-modules.sh" /lib/udev/load-modules.sh

    inst_libdir_file "libnss_files*"
}

