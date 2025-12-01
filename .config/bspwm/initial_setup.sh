#!/usr/bin/env bash

LOG_FILE=/tmp/bspwm_monitor.log
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S.%3N')] [INITIAL_SETUP] $*" >> "$LOG_FILE"; }

HDMI_CONNECTED=$(xrandr -q | grep 'HDMI-0 connected')
DP_CONNECTED=$(xrandr -q | grep -w 'DP-1-1 connected')

SCRIPTS_DIR=~/.config/bspwm

log "========== INITIAL_SETUP STARTED (BACKUP VERSION) =========="

if [ -n "$HDMI_CONNECTED" ] && [ -n "$DP_CONNECTED" ]; then
  $SCRIPTS_DIR/display_both.sh
elif [ -n "$HDMI_CONNECTED" ]; then
  $SCRIPTS_DIR/display_hdmi.sh
elif [ -n "$DP_CONNECTED" ]; then
  $SCRIPTS_DIR/display_dp.sh
else
  # Single monitor setup - eDP-1-1 only
  log "Single monitor mode detected"
  log "Step 1: Running xrandr to configure single display"
  xrandr --output eDP-1-1 --primary --mode 1920x1200 --output HDMI-0 --off 2>/dev/null || true

  log "Step 2: Extending eDP-1-1 to I-X (creates duplicate desktop names temporarily)"
  bspc monitor eDP-1-1 -d I II III IV V VI VII VIII IX X
  log "Window state AFTER extending eDP-1-1 (while HDMI-0 may still exist in bspwm):"
  bspc query -N | xargs -I {} sh -c 'desktop=$(bspc query -D -n {} --names 2>/dev/null); monitor=$(bspc query -M -n {} --names 2>/dev/null); echo "  $monitor:$desktop - window {}"' >> "$LOG_FILE" 2>&1

  # For each desktop on HDMI-0, move its windows to the corresponding desktop on eDP-1
  log "Step 3: Migrating windows from HDMI-0 (only VII-X, not V-VI)"
  for desktop in VII VIII IX X; do
    # Get all windows on the current desktop of HDMI-0
    windows=$(bspc query -N -d HDMI-0:$desktop 2>/dev/null)

    if [ -z "$windows" ]; then
      log "  No windows on HDMI-0:$desktop"
    else
      for window in $windows; do
        log "  Moving window $window from HDMI-0:$desktop to eDP-1-1:$desktop"
        bspc node $window -d eDP-1-1:$desktop
      done
    fi
  done

  log "Step 4: Window state AFTER migration, BEFORE removing HDMI-0:"
  bspc query -N | xargs -I {} sh -c 'desktop=$(bspc query -D -n {} --names 2>/dev/null); monitor=$(bspc query -M -n {} --names 2>/dev/null); echo "  $monitor:$desktop - window {}"' >> "$LOG_FILE" 2>&1

  # After all windows have been moved, remove HDMI-0 from the monitor setup if it exists
  log "Step 5: Removing HDMI-0 from bspwm"
  bspc monitor HDMI-0 -r 2>/dev/null || true

  log "Step 6: Window state AFTER removing HDMI-0:"
  bspc query -N | xargs -I {} sh -c 'desktop=$(bspc query -D -n {} --names 2>/dev/null); monitor=$(bspc query -M -n {} --names 2>/dev/null); echo "  $monitor:$desktop - window {}"' >> "$LOG_FILE" 2>&1

  log "========== DISCONNECT MIGRATION COMPLETE =========="

  # echo "No external monitors detected."
  # bspc monitor eDP-1 -d I II III IV V VI VII VIII IX X; for desktop in V VI VII VIII IX X; do for win in $(bspc query -N -d HDMI-1-0:$desktop); do bspc node $win -d eDP-1:$desktop; done; done; bspc monitor HDMI-1-0 -r
  # bspc monitor eDP-1 -o I II III IV V VI VII VIII IX X
  # bspc monitor HDMI-1-0 -r
  # I had to comment --off, since it logs me out of the session on NixOS 24 with NVIDIA drivers
  # xrandr --output HDMI-1-0 --off --output DP-1 --off
fi
