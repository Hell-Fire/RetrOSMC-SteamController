#!/bin/bash

function reset_controller() {
	VENDOR="28de"
	DEVICES="/sys/bus/usb/devices"
	for device in $(ls $DEVICES); do
		VENDORFILE="$DEVICES/$device/idVendor"
		[[ ! -f "$VENDORFILE" ]] && continue
		if [[ "$(cat $VENDORFILE)" = "$VENDOR" ]]; then
			DRIVER=$(realpath "$DEVICES/$device/driver")
			sudo bash -c "echo $device > $DRIVER/unbind"
			sudo bash -c "echo $device > $DRIVER/bind"
		fi
	done
}

function cleanup() {
	echo "Stopping Xbox mode"
	sc-xbox.py stop
	reset_controller
}
trap cleanup SIGINT

if [[ "$1" = "stop" ]]; then
	cleanup
	exit 0
fi

while true; do
	if [[ -z "$(pgrep steamlink.sh)" && -z "$(pgrep sc-xbox.py)" ]]; then
		# Steamlink isn't running, also not running Xbox mode
		echo "Starting Xbox mode"
		sc-xbox.py start
	fi
	if [[ "$(pgrep steamlink.sh)" && "$(pgrep sc-xbox.py)" ]]; then
		# Steamlink is running, stop Xbox mode
		cleanup
	fi
	sleep 5
done

