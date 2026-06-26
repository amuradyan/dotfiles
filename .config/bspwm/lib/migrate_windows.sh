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

  if [ -z "$from_monitor" ] || [ -z "$to_monitor" ] || [ -z "$1" ]; then
    echo "Error: migrate_windows requires FROM_MONITOR TO_MONITOR DESKTOP [DESKTOP...]" >&2
    return 1
  fi

  # Address desktops by (monitor + name), NOT the string "monitor:desktop" — the latter is an
  # invalid bspc descriptor ("Invalid descriptor found in 'eDP-1:V'") and silently matches nothing.
  # Resolve the target to a desktop ID so the move stays unambiguous even if a same-named desktop
  # transiently exists on both monitors; a window on the source's "V" lands on the target's "V".
  local desktop dst win
  for desktop in "$@"; do
    dst=$(bspc query -D -m "$to_monitor" -d "$desktop" 2>/dev/null)   # target desktop ID on $to_monitor
    [ -z "$dst" ] && continue
    for win in $(bspc query -N -m "$from_monitor" -d "$desktop" -n .window 2>/dev/null); do
      bspc node "$win" -d "$dst" 2>/dev/null
    done
  done
}
