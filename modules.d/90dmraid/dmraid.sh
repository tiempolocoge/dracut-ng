#!/bin/sh

if udevadm settle --timeout=0 >/dev/null 2>&1; then
    # run dmraid if udev has settled
    dmraid -ay -Z
    [ -e "$job" ] && rm -f "$job"
fi

