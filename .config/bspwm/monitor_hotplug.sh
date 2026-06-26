#!/usr/bin/env bash

LOG_FILE=/tmp/bspwm_monitor.log
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S.%3N')] [HOTPLUG] $*" >> "$LOG_FILE"; }

INITIAL_SETUP_SCRIPT=~/.config/bspwm/initial_setup.sh
POLYBAR_LAUNCH_SCRIPT=~/.config/polybar/launch.sh
LOCK_FILE=/tmp/bspwm_hotplug.lock
PREVIOUS_STATE=""

# Detect externals by connector TYPE, not by a fixed name: under PRIME offload the ports enumerate
# as HDMI-1-0 / DP-1-0, under sync as HDMI-0 / DP-1. The old literal 'HDMI-0 connected' grep never
# matched under offload, so hotplug docking silently did nothing.
#
# Reconfiguration is serialized under flock so an overlapping run (or a manual initial_setup) can't
# interleave, and the display scripts are idempotent so a missed/late tick just reconciles next pass.
while true; do
    CURRENT_STATE=$(xrandr -q | grep -w connected | grep -E '^(HDMI|DP)' \
                    | awk '{print $1}' | sort | tr '\n' ',')

    if [ "$CURRENT_STATE" != "$PREVIOUS_STATE" ]; then
        log "External state changed: '${PREVIOUS_STATE}' -> '${CURRENT_STATE}'"
        flock "$LOCK_FILE" "$INITIAL_SETUP_SCRIPT"
        $POLYBAR_LAUNCH_SCRIPT &

        PREVIOUS_STATE=$CURRENT_STATE
    fi

    sleep 4
done
