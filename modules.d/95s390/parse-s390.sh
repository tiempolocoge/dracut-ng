initrdargs="$initrdargs dasd" 

[ -d /etc/modprobe.d ] || mkdir /etc/modprobe.d

dasd_arg=$(getarg dasd=)
if [ -n "$dasd_arg" ]; then
	echo "option dasd_mod dasd=$dasd_arg" >> /etc/modprobe.d/dasd.conf
fi
unset dasd_arg
