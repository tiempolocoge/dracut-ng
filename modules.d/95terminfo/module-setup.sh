#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

install() {
    local _terminfodir
    # terminfo bits make things work better if you fall into interactive mode
    for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
        [ -d ${_terminfodir} ] && break
    done

    if [ -d ${_terminfodir} ]; then
        for f in $(find ${_terminfodir} -type f); do
            inst_simple $f
        done
    fi
}

