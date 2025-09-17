#!/usr/bin/env bash

HDMI_CONNECTED=$(xrandr -q | grep 'HDMI-0 connected')
DP_CONNECTED=$(xrandr -q | grep -w 'DP-1-1 connected')

SCRIPTS_DIR=~/.config/bspwm

if [ -n "$HDMI_CONNECTED" ] && [ -n "$DP_CONNECTED" ]; then
  $SCRIPTS_DIR/display_both.sh
elif [ -n "$HDMI_CONNECTED" ]; then
  $SCRIPTS_DIR/display_hdmi.sh
elif [ -n "$DP_CONNECTED" ]; then
  $SCRIPTS_DIR/display_dp.sh
else
  # Single monitor setup - eDP-1-1 only
  xrandr --output eDP-1-1 --primary --mode 1920x1200 --output HDMI-0 --off 2>/dev/null || true

  # First, extend the desktops on eDP-1 from I-VI to I-X
  echo "Extending desktops on eDP-1 from I-VI to I-X"
  bspc monitor eDP-1-1 -d I II III IV V VI VII VIII IX X

  # For each desktop on HDMI-0, move its windows to the corresponding desktop on eDP-1
  for desktop in VII VIII IX X; do
    echo "Moving windows from desktop $desktop on HDMI-0 to eDP-1"

    # Get all windows on the current desktop of HDMI-0
    windows=$(bspc query -N -d HDMI-0:$desktop)

    for window in $windows; do
      echo "  Moving window $window to desktop $desktop on eDP-1"
      # Move the window to the corresponding desktop on eDP-1
      bspc node $window -d eDP-1-1:$desktop
    done
  done

  # After all windows have been moved, remove HDMI-0 from the monitor setup if it exists
  echo "Removing HDMI-0 from the monitor setup"
  bspc monitor HDMI-0 -r 2>/dev/null || true

  echo "Migration complete: All desktops extended to eDP-1 and all windows transferred"
fi
