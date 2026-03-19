#!/usr/bin/env bash

# Get volume and mute state via wpctl (PipeWire)
volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)

if [ -z "$volume" ]; then
    echo "󰖁 N/A"
    exit 0
fi

# Check muted
if echo "$volume" | grep -q "MUTED"; then
    echo "󰖁 MUTED"
    exit 0
fi

# Extract percentage
vol=$(echo "$volume" | awk '{printf "%.0f", $2 * 100}')

# Choose icon based on level
if [ "$vol" -ge 70 ]; then
    icon="󰕾"
elif [ "$vol" -ge 30 ]; then
    icon="󰖀"
elif [ "$vol" -gt 0 ]; then
    icon="󰕿"
else
    icon="󰖁"
fi

echo "${icon} ${vol}%"
