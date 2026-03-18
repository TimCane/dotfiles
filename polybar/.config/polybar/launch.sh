#!/usr/bin/env bash

# Terminate already running bar instances
polybar-msg cmd quit 2>/dev/null

# If polybar-msg didn't work, fall back to killall
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 0.5; done

# Build modules-right based on detected hardware
MODULES="sep-left playerctl sep-mid cpu sep-mid memory"
[ -d /sys/class/net/wlan0 ] && MODULES="$MODULES sep-mid wlan"
ls /sys/class/backlight/ &>/dev/null 2>&1 && MODULES="$MODULES sep-mid brightness"
MODULES="$MODULES sep-mid pulseaudio"
[ -d /sys/class/power_supply/BAT0 ] && MODULES="$MODULES sep-mid battery"
MODULES="$MODULES sep-mid power"
export POLYBAR_MODULES_RIGHT="$MODULES"

# Launch polybar on each monitor
if type "xrandr" >/dev/null 2>&1; then
    for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
        MONITOR=$m polybar main -r 2>&1 | tee -a /tmp/polybar-$m.log &
        disown
    done
else
    polybar main -r 2>&1 | tee -a /tmp/polybar.log &
    disown
fi

echo "Polybar launched on all monitors."
