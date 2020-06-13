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
			sleep 2
			sudo bash -c "echo $device > $DRIVER/bind"
			sleep 2
		fi
	done
}

function find_steamlink_shell_pid() {
	POSSIBLE="$(pgrep shell)"
	for PID in $POSSIBLE; do
		if [[ "$(realpath /proc/$PID/exe)" = "/home/osmc/.local/share/SteamLink/bin/shell" ]]; then
			echo $PID
			break
		fi
	done
}

function cleanup() {
	echo "Stopping Xbox mode"
	sc-xbox.py stop
	sleep 2
	reset_controller
	STEAMLINK_SHELL_PID="$(find_steamlink_shell_pid)"
	if [[ "$STEAMLINK_SHELL_PID" ]]; then
		# SteamLink shell doesn't always pick up the controller after we've rebound it
		# Get the steamlink.sh script to do our dirty work restarting it by faking
		# a command launch.
		echo "/bin/true" > /home/osmc/.local/share/SteamLink/.tmp/launch_cmdline.txt
		kill "$STEAMLINK_SHELL_PID"
	fi
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

