#!/bin/sh

if [ $(id -u) != 0 ]; then
	echo "Must be run as root"
	exit 1
fi

# name of the ethernet gadget interface on the host
USB_IFACE=${1:-cdce0}
# host interface to use for upstream connection
UPSTREAM_IFACE=${2:-egress}

/sbin/sysctl -w net.inet.ip.forwarding=1
/sbin/pfctl -e

RULE="match out on ${UPSTREAM_IFACE} from ${USB_IFACE}:network to any nat-to (${UPSTREAM_IFACE}:0)"
RULES=$(cat <<EOF
$(cat /etc/pf.conf)
${RULE}
EOF
)

if echo "${RULES}" | /sbin/pfctl -nf -; then
	echo "${RULES}" | /sbin/pfctl -f -
else
	echo "Invalid rules. Please check /etc/pf.conf"
	echo
	echo "The rule we attempted to append was:"
	echo "'${RULE}'"
	/sbin/sysctl -w net.inet.ip.forwarding=0
	exit 1
fi
