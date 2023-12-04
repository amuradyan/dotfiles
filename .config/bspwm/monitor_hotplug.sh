#!/usr/bin/env bash

INITIAL_SETUP_SCRIPT=~/.config/bspwm/initial_setup.sh
POLYBAR_LAUNCH_SCRIPT=~/.config/polybar/launch.sh
PREVIOUS_STATE=""

while true; do
    HDMI_CONNECTED=$(xrandr -q | grep 'HDMI-1 connected')
    DP_CONNECTED=$(xrandr -q | grep -w 'DP-1 connected')
    CURRENT_STATE="$HDMI_CONNECTED$DP_CONNECTED"

    if [ "$CURRENT_STATE" != "$PREVIOUS_STATE" ]; then
        $INITIAL_SETUP_SCRIPT
        $POLYBAR_LAUNCH_SCRIPT &

        PREVIOUS_STATE=$CURRENT_STATE
    fi

    sleep 10
done
