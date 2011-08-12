#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

installkernel() {
    if [[ -z $drivers ]]; then
        block_module_test() {
            local blockfuncs='ahci_init_controller|ata_scsi_ioctl|scsi_add_host|blk_init_queue|register_mtd_blktrans|scsi_esp_register|register_virtio_device'

            egrep -q "$blockfuncs" "$1"
        }
        hostonly='' instmods sr_mod sd_mod scsi_dh scsi_dh_rdac scsi_dh_emc
        hostonly='' instmods pcmcia firewire-ohci
        hostonly='' instmods usb_storage sdhci sdhci-pci

        # install keyboard support
        hostonly='' instmods atkbd i8042 usbhid hid-apple hid-sunplus hid-cherry hid-logitech hid-microsoft ehci-hcd ohci-hcd uhci-hcd
        # install unix socket support
        hostonly='' instmods unix
        instmods "=drivers/pcmcia" =ide "=drivers/usb/storage"
        instmods $(filter_kernel_modules block_module_test)
        # if not on hostonly mode, install all known filesystems,
        # if the required list is not set via the filesystems variable
        if ! [[ $hostonly ]]; then
            if [[ -z $filesystems ]]; then
                instmods '=fs'
                # hardcoded list of exceptions
                # to save a lot of space
                rm -fr ${initdir}/lib/modules/*/kernel/fs/ocfs2
            fi
        else
            hostonly='' instmods $(get_fs_type "/dev/block/$(find_root_block_device)")
        fi
    else
        hostonly='' instmods $drivers
    fi

    [[ $add_drivers ]] && hostonly='' instmods $add_drivers
    [[ $filesystems ]] && hostonly='' instmods $filesystems

    # force install of scsi_wait_scan
    hostonly='' instmods scsi_wait_scan
}

install() {
    local _f
    [ -f /etc/modprobe.conf ] && dracut_install /etc/modprobe.conf
    for i in $(find /etc/modprobe.d/ -type f -name '*.conf'); do
        inst_simple "$i"
    done
    inst_hook cmdline 01 "$moddir/parse-kernel.sh"
    inst_simple "$moddir/insmodpost.sh" /sbin/insmodpost.sh

    local f

    for _f in modules.builtin.bin modules.builtin; do
        [[ $srcmods/$_f ]] && inst_simple "$srcmods/$_f" "/lib/modules/$kernel/$_f" \
            && break
    done || {
        dfatal "No modules.builtin.bin and modules.builtin found!"
        return 1
    }
}
