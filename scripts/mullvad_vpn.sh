#!/usr/bin/env bash

STATUS=$(mullvad status | head -n1)

if echo "$STATUS" | grep -q "Connected"; then
    RELAY=$(mullvad status | grep "Relay" | awk '{print $2}')
    echo "{\"text\":\"$RELAY\",\"class\":\"connected\"}"
else
    echo "{\"text\":\"No VPN\",\"class\":\"disconnected\"}"
fi
