#!/bin/sh
#
# This implementation is incomplete: Discovery mode is not implemented and
# the argument handling doesn't follow currently agreed formats. This is mainly
# because rfc4173 does not say anything about iscsi_initiator but open-iscsi's
# iscsistart needs this.
#

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh
type parse_iscsi_root >/dev/null 2>&1 || . /lib/net-lib.sh
type write_fs_tab >/dev/null 2>&1 || . /lib/fs-lib.sh

PATH=/usr/sbin:/usr/bin:/sbin:/bin

# Huh? Empty $1?
[ -z "$1" ] && exit 1

# Huh? Empty $2?
[ -z "$2" ] && exit 1

# Huh? Empty $3? This isn't really necessary, since NEWROOT isn't
# used here. But let's be consistent
[ -z "$3" ] && exit 1

# root is in the form root=iscsi:[<servername>]:[<protocol>]:[<port>]:[<LUN>]:<targetname>
netif="$1"
iroot="$2"

# If it's not iscsi we don't continue
[ "${iroot%%:*}" = "iscsi" ] || exit 1

iroot=${iroot#iscsi}
iroot=${iroot#:}

# XXX modprobe crc32c should go in the cmdline parser, but I haven't yet
# figured out a way how to check whether this is built-in or not
modprobe crc32c 2>/dev/null

if [ -e /sys/module/bnx2i ] && ! [ -e /tmp/iscsiuio-started ]; then
        iscsiuio
        > /tmp/iscsiuio-started
fi

handle_firmware()
{
    if ! [ -e /tmp/iscsistarted-firmware ]; then
        if ! iscsistart -f; then
            warn "iscistart: Could not get list of targets from firmware."
            return 1
        fi

        for p in $(getargs rd.iscsi.param -d iscsi_param); do
	    iscsi_param="$iscsi_param --param $p"
        done

        if ! iscsistart -b $iscsi_param; then
            warn "'iscsistart -b $iscsi_param' failed"
        fi

        if [ -d /sys/class/iscsi_session ]; then
            echo 'started' > "/tmp/iscsistarted-iscsi:"
            echo 'started' > "/tmp/iscsistarted-firmware"
        else
            return 1
        fi

        need_shutdown
    fi
    return 0
}


handle_netroot()
{
    local iscsi_initiator iscsi_target_name iscsi_target_ip iscsi_target_port
    local iscsi_target_group iscsi_protocol iscsirw iscsi_lun
    local iscsi_username iscsi_password
    local iscsi_in_username iscsi_in_password
    local iscsi_iface_name iscsi_netdev_name
    local iscsi_param
    local p

    # override conf settings by command line options
    arg=$(getarg rd.iscsi.initiator -d iscsi_initiator=)
    [ -n "$arg" ] && iscsi_initiator=$arg
    arg=$(getarg rd.iscsi.target.name -d iscsi_target_name=)
    [ -n "$arg" ] && iscsi_target_name=$arg
    arg=$(getarg rd.iscsi.target.ip -d iscsi_target_ip)
    [ -n "$arg" ] && iscsi_target_ip=$arg
    arg=$(getarg rd.iscsi.target.port -d iscsi_target_port=)
    [ -n "$arg" ] && iscsi_target_port=$arg
    arg=$(getarg rd.iscsi.target.group -d iscsi_target_group=)
    [ -n "$arg" ] && iscsi_target_group=$arg
    arg=$(getarg rd.iscsi.username -d iscsi_username=)
    [ -n "$arg" ] && iscsi_username=$arg
    arg=$(getarg rd.iscsi.password -d iscsi_password)
    [ -n "$arg" ] && iscsi_password=$arg
    arg=$(getarg rd.iscsi.in.username -d iscsi_in_username=)
    [ -n "$arg" ] && iscsi_in_username=$arg
    arg=$(getarg rd.iscsi.in.password -d iscsi_in_password=)
    [ -n "$arg" ] && iscsi_in_password=$arg
    for p in $(getargs rd.iscsi.param -d iscsi_param); do
	iscsi_param="$iscsi_param --param $p"
    done

    parse_iscsi_root "$1" || return 1

# XXX is this needed?
    getarg ro && iscsirw=ro
    getarg rw && iscsirw=rw
    fsopts=${fsopts:+$fsopts,}${iscsirw}

    if [ -z $iscsi_initiator ]; then
    # XXX Where are these from?
        [ -f /etc/initiatorname.iscsi ] && . /etc/initiatorname.iscsi
        [ -f /etc/iscsi/initiatorname.iscsi ] && . /etc/iscsi/initiatorname.iscsi
        iscsi_initiator=$InitiatorName

    # XXX rfc3720 says 'SCSI Initiator Name: The iSCSI Initiator Name specifies
    # the worldwide unique name of the initiator.' Could we use hostname/ip
    # if missing?
    fi

    if [ -z $iscsi_initiator ]; then
       if [ -f /sys/firmware/ibft/initiator/initiator-name ]; then
           iscsi_initiator=$(while read line || [ -n "$line" ]; do echo $line;done < /sys/firmware/ibft/initiator/initiator-name)
       fi
    fi

    if [ -z $iscsi_target_port ]; then
        iscsi_target_port=3260
    fi

    if [ -z $iscsi_target_group ]; then
        iscsi_target_group=1
    fi

    if [ -z $iscsi_initiator ]; then
    # XXX is this correct?
        iscsi_initiator=$(iscsi-iname)
    fi

    if [ -z $iscsi_lun ]; then
        iscsi_lun=0
    fi

    echo "InitiatorName='$iscsi_initiator'" > /run/initiatorname.iscsi
    ln -fs /run/initiatorname.iscsi /dev/.initiatorname.iscsi

# FIXME $iscsi_protocol??

    if [ "$root" = "dhcp" ]; then
        # if root is not specified try to mount the whole iSCSI LUN
        printf 'SYMLINK=="disk/by-path/*-iscsi-*-%s", SYMLINK+="root"\n' $iscsi_lun >> /etc/udev/rules.d/99-iscsi-root.rules
        udevadm control --reload
        write_fs_tab /dev/root
        wait_for_dev -n /dev/root

        # install mount script
        [ -z "$DRACUT_SYSTEMD" ] && \
            echo "iscsi_lun=$iscsi_lun . /bin/mount-lun.sh " > $hookdir/mount/01-$$-iscsi.sh
    fi

    # force udevsettle to break
    > $hookdir/initqueue/work

    iscsistart -i $iscsi_initiator -t $iscsi_target_name        \
        -g $iscsi_target_group -a $iscsi_target_ip      \
        -p $iscsi_target_port \
        ${iscsi_username:+-u $iscsi_username} \
        ${iscsi_password:+-w $iscsi_password} \
        ${iscsi_in_username:+-U $iscsi_in_username} \
        ${iscsi_in_password:+-W $iscsi_in_password} \
	${iscsi_iface_name:+--param iface.iscsi_ifacename=$iscsi_iface_name} \
	${iscsi_netdev_name:+--param iface.net_ifacename=$iscsi_netdev_name} \
        ${iscsi_param} \
	|| :

    netroot_enc=$(str_replace "$1" '/' '\2f')
    echo 'started' > "/tmp/iscsistarted-iscsi:${netroot_enc}"
}

ret=0

# loop over all netroot parameter
if getarg netroot; then
    for nroot in $(getargs netroot); do
        [ "${nroot%%:*}" = "iscsi" ] || continue
        nroot="${nroot##iscsi:}"
        if [ -n "$nroot" ]; then
            handle_netroot "$nroot"
            ret=$(($ret + $?))
        fi
    done
    if getargbool 0 rd.iscsi.firmware -d -y iscsi_firmware ; then
        handle_firmware
        ret=$(($ret + $?))
    fi
else
    if [ -n "$iroot" ]; then
        handle_netroot "$iroot"
        ret=$?
    else
        if getargbool 0 rd.iscsi.firmware -d -y iscsi_firmware ; then
            handle_firmware
            ret=$?
        fi
    fi
fi

need_shutdown

# now we have a root filesystem somewhere in /dev/sda*
# let the normal block handler handle root=
exit $ret
