#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    # TODO: splash_geninitramfs
    # TODO: /usr/share/splashutils/initrd.splash
    return 255
}

depends() {
    return 0
}

install() {
    call_splash_geninitramfs() {
        local out ret 

        out=$(splash_geninitramfs -c "$1" ${@:2} 2>&1)
        ret=$?

        if [[ ${out} ]]; then
            local IFS='
'
            for line in ${out}; do
                if [[ ${line} =~ ^Warning ]]; then
                    dwarning "${line}"
                else
                    derror "${line}"
                    (( ret == 0 )) && ret=1
                fi
            done
        fi

        return ${ret}
    }


    type -P splash_geninitramfs >/dev/null || return 1

    opts=''

    if [[ ${DRACUT_GENSPLASH_THEME} ]]; then
        # Variables from the environment
        # They're supposed to be set up by e.g. Genkernel in basis of cmdline args.
        # If user set them he/she would expect to be included only given theme
        # rather then all even if we're building generic initramfs.
        SPLASH_THEME=${DRACUT_GENSPLASH_THEME}
        SPLASH_RES=${DRACUT_GENSPLASH_RES}
    elif [[ ${hostonly} ]]; then
        # Settings from config only in hostonly
        [[ -e /etc/conf.d/splash ]] && source /etc/conf.d/splash
        [[ ! ${SPLASH_THEME} ]] && SPLASH_THEME=default
        [[ ${SPLASH_RES} ]] && opts+=" -r ${SPLASH_RES}"
    else
        # generic
        SPLASH_THEME=--all
    fi

    dinfo "Installing Gentoo Splash (using the ${SPLASH_THEME} theme)"

    pushd "${initdir}" >/dev/null
    mv dev dev.old
    call_splash_geninitramfs "${initdir}" ${opts} ${SPLASH_THEME} || {
        derror "Could not build splash"
        return 1
    }
    rm -rf dev
    mv dev.old dev
    popd >/dev/null

    dracut_install chvt
    inst /usr/share/splashutils/initrd.splash /lib/gensplash-lib.sh
    inst_hook pre-pivot 90 "${moddir}"/gensplash-newroot.sh
    inst_hook pre-trigger 10 "${moddir}"/gensplash-pretrigger.sh
    inst_hook emergency 50 "${moddir}"/gensplash-emergency.sh
}
