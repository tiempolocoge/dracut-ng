#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# called by dracut
check() {
    local _arch=$(uname -m)
    # Only for systems on s390 using indirect booting via userland grub
    [ "$_arch" = "s390" -o "$_arch" = "s390x" ] || return 1
    # /boot/zipl contains a first stage kernel used to launch grub in initrd
    [ -d /boot/zipl ] || return 1
    return 0
}

# called by dracut
depends() {
    echo grub2
    return 0
}

# called by dracut
installkernel() {
    instmods ext2
}

# called by dracut
cmdline() {
    local _boot_zipl

    _boot_zipl=$(sed -n 's/\(.*\)\w*\/boot\/zipl.*/\1/p' /etc/fstab)
    if [ -n "$_boot_zipl" ] ; then
        echo "rd.zipl=${_boot_zipl}"
    fi
}

# called by dracut
install() {
    inst_multiple mount umount

    inst_hook cmdline 91 "$moddir/parse-zipl.sh"
    inst "${moddir}/install_zipl_cmdline.sh" /sbin/install_zipl_cmdline.sh
    if [[ $hostonly_cmdline == "yes" ]] ; then
        local _zipl=$(cmdline)

        [[ $_zipl ]] && printf "%s\n" "$_zipl" > "${initdir}/etc/cmdline.d/91zipl.conf"
    fi
    dracut_need_initqueue
}
