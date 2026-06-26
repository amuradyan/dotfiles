#!/usr/bin/env bash

INITIAL_SETUP_SCRIPT=~/.config/bspwm/initial_setup.sh
POLYBAR_LAUNCH_SCRIPT=~/.config/polybar/launch.sh
PREVIOUS_STATE=""

# Detect externals by connector TYPE, not by a fixed name: under PRIME offload the
# ports enumerate as HDMI-1-0 / DP-1-0, under sync as HDMI-0 / DP-1. The old
# literal 'HDMI-0 connected' grep never matched under offload, so hotplug docking
# silently did nothing.
while true; do
    CURRENT_STATE=$(xrandr -q | grep -w connected | grep -E '^(HDMI|DP)' \
                    | awk '{print $1}' | sort | tr '\n' ',')

    if [ "$CURRENT_STATE" != "$PREVIOUS_STATE" ]; then
        $INITIAL_SETUP_SCRIPT
        $POLYBAR_LAUNCH_SCRIPT &

        PREVIOUS_STATE=$CURRENT_STATE
    fi

    sleep 10
done
