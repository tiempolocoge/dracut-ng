#!/bin/sh
#
# Format:
#       bond=<bondname>[:<bondslaves>:[:<options>]]
#
#       bondslaves is a comma-separated list of physical (ethernet) interfaces
#       options is a comma-separated list on bonding options (modinfo bonding for details) in format compatible with initscripts
#       if options include multi-valued arp_ip_target option, then its values should be separated by semicolon.
#
#       bond without parameters assumes bond=bond0:eth0,eth1:mode=balance-rr
#

# return if bond already parsed
[ -n "$bondname" ] && return

# Check if bond parameter is valid
if getarg bond= >/dev/null ; then
    :
fi

# We translate list of slaves to space-separated here to mwke it easier to loop over them in ifup
# Ditto for bonding options
parsebond() {
    local v=${1}:
    set --
    while [ -n "$v" ]; do
        set -- "$@" "${v%%:*}"
        v=${v#*:}
    done

    unset bondname bondslaves bondoptions
    case $# in
    0)  bondname=bond0; bondslaves="eth0 eth1" ;;
    1)  bondname=$1; bondslaves="eth0 eth1" ;;
    2)  bondname=$1; bondslaves=$(str_replace "$2" "," " ") ;;
    3)  bondname=$1; bondslaves=$(str_replace "$2" "," " "); bondoptions=$(str_replace "$3" "," " ") ;;
    *)  die "bond= requires zero to four parameters" ;;
    esac
}

unset bondname bondslaves bondoptions

# Parse bond for bondname, bondslaves, bondmode and bondoptions
if getarg bond >/dev/null; then
    # Read bond= parameters if they exist
    bond="$(getarg bond=)"
    if [ ! "$bond" = "bond" ]; then
        parsebond "$(getarg bond=)"
    fi
    # Simple default bond
    if [ -z "$bondname" ]; then
        bondname=bond0
        bondslaves="eth0 eth1"
    fi
    # Make it suitable for initscripts export
    bondoptions=$(str_replace "$bondoptions" ";" ",")
    echo "bondname=$bondname" > /tmp/bond.${bondname}.info
    echo "bondslaves=\"$bondslaves\"" >> /tmp/bond.${bondname}.info
    echo "bondoptions=\"$bondoptions\"" >> /tmp/bond.${bondname}.info
    return
fi
