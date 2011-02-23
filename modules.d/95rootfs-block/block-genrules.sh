#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

if [ "${root%%:*}" = "block" ]; then
    {
        printf 'KERNEL=="%s", SYMLINK+="root"\n' \
            ${root#block:/dev/} 
        printf 'SYMLINK=="%s", SYMLINK+="root"\n' \
            ${root#block:/dev/} 
    } >> /dev/.udev/rules.d/99-root.rules
    
    printf '[ -e "%s" ] && { ln -s "%s" /dev/root 2>/dev/null; rm "$job"; }\n' \
        "${root#block:}" "${root#block:}" >> /initqueue-settled/blocksymlink.sh

    echo '[ -e /dev/root ]' > /initqueue-finished/block.sh
fi
