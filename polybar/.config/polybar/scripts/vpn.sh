#!/usr/bin/env bash

# Polybar module: ProtonVPN status + toggle

STATUS=$(protonvpn-cli status 2>/dev/null)

if echo "$STATUS" | grep -q "Connected"; then
    SERVER=$(echo "$STATUS" | awk '/Server:/{print $2}')
    echo "%{F#b8bb26}󰌾 $SERVER%{F-}"
else
    echo "%{F#fb4934}󰌿 VPN%{F-}"
fi

case "$1" in
    toggle)
        if protonvpn-cli status 2>/dev/null | grep -q "Connected"; then
            protonvpn-cli disconnect
        else
            protonvpn-cli connect --fastest
        fi
        ;;
esac
