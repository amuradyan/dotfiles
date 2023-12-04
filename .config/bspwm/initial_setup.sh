#!/usr/bin/env bash

HDMI_CONNECTED=$(xrandr -q | grep 'HDMI-1 connected')
DP_CONNECTED=$(xrandr -q | grep -w 'DP-1 connected')

SCRIPTS_DIR=~/.config/bspwm

if [ -n "$HDMI_CONNECTED" ] && [ -n "$DP_CONNECTED" ]; then
  $SCRIPTS_DIR/display_both.sh
elif [ -n "$HDMI_CONNECTED" ]; then
  $SCRIPTS_DIR/display_hdmi.sh
elif [ -n "$DP_CONNECTED" ]; then
  $SCRIPTS_DIR/display_dp.sh
else
  echo "No external monitors detected."
  xrandr --output HDMI-1 --off --output DP-1 --off
  bspc monitor eDP-1 -d I II III IV V VI VII VIII IX X
fi
