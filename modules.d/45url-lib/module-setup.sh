#!/bin/bash
# module-setup for url-lib

check() {
    command -v curl >/dev/null || return 1
    return 255
}

depends() {
    echo network
    return 0
}

install() {
    inst_simple "$moddir/url-lib.sh" "/lib/url-lib.sh"
    dracut_install curl
    # also install libs for curl https
    inst_libdir_file "libnsspem.so*"
    inst_libdir_file "libnsssysinit.so*"
    inst_libdir_file "libsoftokn3.so*"
    inst_libdir_file "libsqlite3.so*"

    mkdir -m 0755 -p "$initdir/etc/ssl/certs"
    if ! inst_any -t /etc/ssl/certs/ca-bundle.crt \
            /etc/ssl/certs/ca-bundle.crt \
            /etc/ssl/certs/ca-certificates.crt; then
        dwarn "Couldn't find SSL CA cert bundle; HTTPS won't work."
    fi
}

