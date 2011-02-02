#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    [ -x /sbin/bootchartd ] || return 1
    return 255
}

depends() {
    return 0
}

install() {
    inst /sbin/bootchartd 
    inst /bin/bash 
    inst_symlink /init /sbin/init
    inst_dir /lib/bootchart/tmpfs
    inst /lib/bootchart/bootchart-collector 
    inst /etc/bootchartd.conf 
    inst /sbin/accton 
    inst /usr/bin/pkill /bin/pkill
    inst /bin/echo
    inst /bin/grep 
    inst /bin/usleep
    inst /usr/bin/[  /bin/[

    mknod -m 0666 "${initdir}/dev/null" c 1 3
}

