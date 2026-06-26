#!/usr/bin/env bash

LOG_FILE=/tmp/bspwm_monitor.log
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S.%3N')] [INITIAL_SETUP] $*" >> "$LOG_FILE"; }

SCRIPTS_DIR=~/.config/bspwm
source "$SCRIPTS_DIR/lib/detect_outputs.sh"

# Bind dGPU-attached connectors to the Intel source up front when on offload, so
# externals can be detected and lit; a no-op under sync.
ensure_prime_sink

log "========== INITIAL_SETUP STARTED (mode=$GPU_MODE EDP=$EDP HDMI=${HDMI:-none} DP=${DP:-none}) =========="

if [ -n "$HDMI" ] && [ -n "$DP" ]; then
  $SCRIPTS_DIR/display_both.sh
elif [ -n "$HDMI" ]; then
  $SCRIPTS_DIR/display_hdmi.sh
elif [ -n "$DP" ]; then
  $SCRIPTS_DIR/display_dp.sh
else
  # No external connected — internal panel ($EDP) only. Reclaim all desktops onto
  # it and drop any stale external monitor bspwm still holds. Name-agnostic:
  # the stale monitor may be HDMI-0/DP-1 (sync) or HDMI-1-0/DP-1-0 (offload).
  log "Single monitor mode ($EDP)"
  source "$SCRIPTS_DIR/lib/migrate_windows.sh"

  xrandr --output "$EDP" --primary --mode 1920x1200 2>/dev/null || true

  log "Extending $EDP to I-X"
  bspc monitor "$EDP" -d I II III IV V VI VII VIII IX X

  for m in $(bspc query -M --names); do
    [ "$m" = "$EDP" ] && continue
    log "Folding stale monitor $m into $EDP, then removing it"
    migrate_windows "$m" "$EDP" I II III IV V VI VII VIII IX X
    bspc monitor "$m" -r 2>/dev/null || true
  done

  log "========== SINGLE-MONITOR SETUP COMPLETE =========="
fi
