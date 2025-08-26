#!/usr/bin/env bash

# Workspace groups for 3 monitors
# Each group maps to 3 workspaces (one per monitor)

group=$1

case $group in
  1)
    i3-msg "workspace 1; move workspace to output DP-4"
    i3-msg "workspace 2; move workspace to output DP-0"
    i3-msg "workspace 3; move workspace to output DP-2"
    ;;
  2)
    i3-msg "workspace 4; move workspace to output DP-4"
    i3-msg "workspace 5; move workspace to output DP-0"
    i3-msg "workspace 6; move workspace to output DP-2"
    ;;
  3)
    i3-msg "workspace 7; move workspace to output DP-4"
    i3-msg "workspace 8; move workspace to output DP-0"
    i3-msg "workspace 9; move workspace to output DP-2"
    ;;
  *)
    echo "Usage: $0 {1|2|3}" >&2
    exit 1
    ;;
esac
