#!/bin/sh

i3lock \
    --color=11111bff \
    --ignore-empty-password \
    --screen 1 \
    --clock \
    --indicator \
    --time-color=cdd6f4ff \
    --time-font=Noto Sans \
    --time-size=150 \
    --date-color=a6adc8ff \
    --date-font=Noto Sans \
    --date-size=25 \
    --date-pos="tx:ty-140" \
    --bar-indicator \
    --bar-color=11111bff \
    --ring-color=cba6f7ff \
    --keyhl-color=cba6f7ff \
    --bshl-color=f38ba8ff \
    --bar-pos="x+(w / 2)-250:y+(h / 2) + 10" \
    --bar-total-width="500" \
    --bar-max-height=10 \
    --bar-base-width=100 \
    --bar-periodic-step=10 \
    --bar-count=8 \
    --refresh-rate=20