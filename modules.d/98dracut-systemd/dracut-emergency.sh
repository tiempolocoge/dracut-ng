#!/bin/sh

export DRACUT_SYSTEMD=1
if [ -f /dracut-state.sh ]; then
    . /dracut-state.sh 2>/dev/null
fi
type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

source_conf /etc/conf.d

type plymouth >/dev/null 2>&1 && plymouth quit

export _rdshell_name="dracut" action="Boot" hook="emergency"

source_hook "$hook"


if getargbool 1 rd.shell -d -y rdshell || getarg rd.break -d rdbreak; then
    echo
    rdsosreport
    echo
    echo
    echo 'Entering emergency mode. Exit the shell to continue.'
    echo 'Type "journalctl" to view system logs.'
    echo 'You might want to save "/run/initramfs/rdsosreport.txt" to a USB stick or /boot'
    echo 'after mounting them and attach it to a bug report.'
    echo
    echo
    [ -f /etc/profile ] && . /etc/profile
    [ -z "$PS1" ] && export PS1="$_name:\${PWD}# "
    exec sh -i -l
else
    warn "$action has failed. To debug this issue add \"rd.shell rd.debug\" to the kernel command line."
    exit 1
fi

/bin/rm -f -- /.console_lock

exit 0
