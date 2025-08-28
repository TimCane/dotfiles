
#!/bin/sh

# Detect device name (hostname)
DEVICE=$(hostname)

case "$DEVICE" in
	orion)
		# Orion xrandr config
		xrandr --output DP-0 --primary --mode 2560x1440 --pos 2560x0 --rotate normal \
					 --output DP-1 --off \
					 --output HDMI-0 --off \
					 --output DP-2 --mode 2560x1440 --pos 5120x0 --rotate normal \
					 --output DP-3 --off \
					 --output DP-4 --mode 2560x1440 --pos 0x0 --rotate normal \
					 --output DP-5 --off \
					 --output USB-C-0 --off
		;;
	luna)
		# TODO: Add xrandr config for luna
		echo "No xrandr config for luna yet."
		;;
	ursa)
		# TODO: Add xrandr config for ursa
		echo "No xrandr config for ursa yet."
		;;
	*)
		echo "Unknown device: $DEVICE"
		;;
esac
