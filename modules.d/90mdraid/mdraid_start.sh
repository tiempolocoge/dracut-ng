#!/bin/sh

. /lib/dracut-lib.sh
# run mdadm if udev has settled
info "Assembling MD RAID arrays"
udevadm control --stop-exec-queue
mdadm -IRs 2>&1 | vinfo
[ -f /initqueue-settled/mdcontainer_start ] || rm /initqueue-finished/mdraid.sh 2>/dev/null
udevadm control --start-exec-queue
