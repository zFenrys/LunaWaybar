#!/usr/bin/env bash

# Leggi la prima riga dello stato Mullvad
STATUS=$(mullvad status | head -n1)

if echo "$STATUS" | grep -q "Connected"; then
    mullvad disconnect
    notify-send "🛡️ Mullvad VPN" "Disconnessa" -u normal
elif echo "$STATUS" | grep -q "Disconnected"; then
    mullvad connect
    # Mostra subito stato aggiornato
    sleep 2
    NEW_STATUS=$(mullvad status | head -n1)
    notify-send "🛡️ Mullvad VPN" "Connessa: $NEW_STATUS" -u normal
else
    # Stato intermedio (Connecting..., Reconnecting...)
    notify-send "🛡️ Mullvad VPN" "Stato: $STATUS" -u low
fi

