#!/bin/bash

MON1=1   # DP-1
MON2=2   # HDMI-A-2

get() {
  ddcutil -d "$1" getvcp 10 | grep -oP '(?<=current value = )[0-9]+'
}

set_brightness() {
  ddcutil -d "$1" setvcp 10 "$2"
}

case "$1" in
  up1)
    cur=$(get $MON1)
    set_brightness $MON1 $((cur + 5))
    ;;
  down1)
    cur=$(get $MON1)
    set_brightness $MON1 $((cur - 5))
    ;;
  up2)
    cur=$(get $MON2)
    set_brightness $MON2 $((cur + 5))
    ;;
  down2)
    cur=$(get $MON2)
    set_brightness $MON2 $((cur - 5))
    ;;
esac

b1=$(get $MON1)
b2=$(get $MON2)

echo "{\"text\":\"☀ $b1% | $b2%\",\"tooltip\":\"DP-1: $b1%\\nHDMI-A-2: $b2%\"}"
