#!/bin/bash

if [[ "$(id -u)" -eq "0" ]]; then
	echo "Don't run as root"
	return 1
fi

cd "$(dirname $0)"

APT_DEPS="python3-libusb1 python3-psutil"

for package in $APT_DEPS; do
	dpkg -l "$package" > /dev/null
	if [[ "$?" -eq "1" ]]; then
		echo "Missing dependencies, installing"
		sudo apt-get --assume-yes install $APT_DEPS
		break
	fi
done


SC="$HOME/steamcontroller"

echo "Checking for steamcontroller updates"
UPDATED=0
if [[ -d "$SC" ]]; then
	pushd "$SC" > /dev/null
	git pull
	popd > /dev/null
else
	git clone "https://github.com/ynsta/steamcontroller.git" "$SC"
fi

echo "Installing steamcontroller"
pushd "$SC" > /dev/null
sudo python3 setup.py install
popd > /dev/null

echo "Installing steamcontroller-watchdog service file"
SERVICEFILE="/lib/systemd/system/steamcontroller-watchdog.service"
sudo bash -c "sed 's,__INSTALLPATH__,$(pwd),' $(basename "$SERVICEFILE") > $SERVICEFILE"

echo "Reloading service files"
sudo systemctl daemon-reload

echo "Enabling steamcontroller-watchdog"
sudo systemctl enable steamcontroller-watchdog

echo "Starting steamcontroller-watchdog"
sudo systemctl start steamcontroller-watchdog

