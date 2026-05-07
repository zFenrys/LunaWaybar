#!/usr/bin/env bash
set -euo pipefail

# escape JSON minimale
escape_json() {
    printf '%s' "$1" \
      | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e ':a;N;s/\n/\\n/g;ta'
}

# Prendi connessioni attive (terse: NAME:TYPE:DEVICE)
NM_OUT=$(nmcli -t -f NAME,TYPE,DEVICE connection show --active 2>/dev/null || true)

if [ -z "$NM_OUT" ]; then
    echo "{\"text\":\"No VPN\",\"class\":\"disconnected\"}"
    exit 0
fi

# Prendi la prima connessione VPN / wireguard che trovi
VPN_LINE=$(printf '%s\n' "$NM_OUT" | awk -F: 'BEGIN{IGNORECASE=1} $2 ~ /vpn|wireguard/ { print; exit }')

if [ -z "$VPN_LINE" ]; then
    echo "{\"text\":\"No VPN\",\"class\":\"disconnected\"}"
    exit 0
fi

NAME=$(printf '%s' "$VPN_LINE" | cut -d: -f1)
TYPE=$(printf '%s' "$VPN_LINE" | cut -d: -f2)
DEVICE=$(printf '%s' "$VPN_LINE" | cut -d: -f3)

# normalizza nome per matching provider
NAME_LOWER=$(printf '%s' "$NAME" | tr '[:upper:]' '[:lower:]')

# helper: prova a estrarre token tipo NL-FREE#214 dal testo
extract_free_token() {
    local input="$1"
    # pattern: 2 lettere, dash, FREE (case-insensitive), #numero
    # prova prima con grep -oP (più preciso) poi fallback a sed
    if command -v grep >/dev/null 2>&1 && grep -P -q '.' <(printf '%s' "$input") 2>/dev/null; then
        token=$(printf '%s\n' "$input" | grep -oP '[A-Z]{2}-FREE#[0-9]+' 2>/dev/null | head -n1 || true)
        if [ -n "$token" ]; then
            printf '%s' "$token"
            return 0
        fi
        # prova anche lowercase/free
        token=$(printf '%s\n' "$input" | grep -oP '[A-Za-z]{2}-[Ff][Rr][Ee][Ee]#[0-9]+' 2>/dev/null | head -n1 || true)
        [ -n "$token" ] && { printf '%s' "$token"; return 0; }
    fi

    # fallback con sed (meno preciso ma più portabile)
    token=$(printf '%s\n' "$input" | sed -nE 's/.*([A-Za-z]{2}-[Ff][Rr][Ee][Ee]#[0-9]+).*/\1/p' | head -n1 || true)
    [ -n "$token" ] && { printf '%s' "$token"; return 0; }

    # niente trovato
    return 1
}

if printf '%s' "$NAME_LOWER" | grep -q 'mullvad'; then
    # Mullvad: preferiamo usare mullvad status per avere il Relay se possibile
    if command -v mullvad >/dev/null 2>&1; then
        MV_OUT=$(mullvad status 2>/dev/null || true)
        RELAY=$(printf '%s\n' "$MV_OUT" | awk 'BEGIN{IGNORECASE=1}
                  /relay[: ]/ { sub(/^[^:]*[: ]+/,""); print; exit }
                  /server[: ]/ { sub(/^[^:]*[: ]+/,""); print; exit }
                  /gateway[: ]/ { sub(/^[^:]*[: ]+/,""); print; exit }
                  /country[: ]/ { sub(/^[^:]*[: ]+/,""); print; exit }
                  /exit ip[: ]/ { sub(/^[^:]*[: ]+/,""); print; exit }' | sed -e 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [ -n "$RELAY" ]; then
            echo "{\"text\":\"$(escape_json "$RELAY")\",\"class\":\"connected\"}"
            exit 0
        fi
    fi
    # fallback: mostra il nome della connessione NM
    echo "{\"text\":\"$(escape_json "$NAME")\",\"class\":\"connected\"}"
    exit 0
fi

if printf '%s' "$NAME_LOWER" | grep -q 'proton'; then
    # Prima prova ad estrarre il token dal NAME
    if token=$(extract_free_token "$NAME" 2>/dev/null); then
        echo "{\"text\":\"$(escape_json "$token")\",\"class\":\"connected\"}"
        exit 0
    fi

    # Altrimenti prova a guardare protonvpn status per trovare token
    if command -v protonvpn >/dev/null 2>&1; then
        PV_OUT=$(protonvpn status 2>/dev/null || true)
        if [ -n "$PV_OUT" ]; then
            if token=$(extract_free_token "$PV_OUT" 2>/dev/null); then
                echo "{\"text\":\"$(escape_json "$token")\",\"class\":\"connected\"}"
                exit 0
            fi
            # prova a estrarre qualche campo utile (es. Server: ...)
            PROTON_LABEL=$(printf '%s\n' "$PV_OUT" | awk 'BEGIN{IGNORECASE=1}
                    /server[: ]/ { sub(/^[^:]*[: ]+/,""); print; exit }
                    /gateway[: ]/ { sub(/^[^:]*[: ]+/,""); print; exit }
                    /connected to[: ]/ { sub(/^[^:]*[: ]+/,""); print; exit }' | sed -e 's/^[[:space:]]*//;s/[[:space:]]*$//')
            if [ -n "$PROTON_LABEL" ]; then
                echo "{\"text\":\"$(escape_json "$PROTON_LABEL")\",\"class\":\"connected\"}"
                exit 0
            fi
        fi
    fi

    # ultimo fallback: mostra il nome della connessione
    echo "{\"text\":\"$(escape_json "$NAME")\",\"class\":\"connected\"}"
    exit 0
fi

# Provider non riconosciuto: mostra il nome della connessione (compatto)
echo "{\"text\":\"$(escape_json "$NAME")\",\"class\":\"connected\"}"
exit 0
