#!/usr/bin/env bash

# migrate_windows - Migrate windows between monitors for specific desktops
#
# Usage: migrate_windows FROM_MONITOR TO_MONITOR DESKTOP1 [DESKTOP2 ...]
#
# Example: migrate_windows HDMI-0 eDP-1-1 V VI VII VIII IX X
#
# This function migrates all windows from specified desktops on FROM_MONITOR
# to the corresponding desktops on TO_MONITOR.
#
# IMPORTANT: Target desktops must already exist on TO_MONITOR before calling this function.

migrate_windows() {
  local from_monitor=$1
  local to_monitor=$2
  shift 2
  local desktops="$@"

  if [ -z "$from_monitor" ] || [ -z "$to_monitor" ] || [ -z "$desktops" ]; then
    echo "Error: migrate_windows requires FROM_MONITOR TO_MONITOR DESKTOP [DESKTOP...]" >&2
    return 1
  fi

  for desktop in $desktops; do
    local windows=$(bspc query -N -d "$from_monitor:$desktop" 2>/dev/null)

    if [ -n "$windows" ]; then
      for window in $windows; do
        bspc node "$window" -d "$to_monitor:$desktop" 2>/dev/null
      done
    fi
  done
}
