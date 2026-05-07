#!/usr/bin/env bash

state=$(bluetoothctl show | grep "Powered" | awk '{print $2}')

if [ "$state" = "yes" ]; then
  bluetoothctl power off
  notify-send "🔵 Bluetooth" "Disattivato"
else
  bluetoothctl power on
  notify-send "🔵 Bluetooth" "Attivato"
fi

