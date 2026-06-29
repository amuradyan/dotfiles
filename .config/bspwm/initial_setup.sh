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
  # No external connected — collapse X and bspwm back to the internal panel ($EDP) only.
  # Name-agnostic: a stale external may be HDMI-0/DP-1 (sync) or HDMI-1-0/DP-1-0 (offload).
  log "Single monitor mode ($EDP)"

  # Geometry teardown: a disconnected external keeps its last mode/position (e.g. HDMI-1-0 at
  # 3840x2160+0+0), leaving a pointer dead-zone and an oversized 3840x3360 canvas. Turn off any
  # non-panel output still holding a geometry, pin the panel at the origin, then shrink the
  # framebuffer. One output per xrandr call (multi-output xrandr SIGFPEs under reverse-PRIME).
  log "Collapsing geometry to $EDP only"
  xrandr -q | awk '/^(HDMI|DP)[^ ]* (connected|disconnected) [0-9]+x[0-9]+\+/{print $1}' \
    | while read -r o; do xrandr --output "$o" --off 2>>"$LOG_FILE" || log "WARN: --off $o failed"; done
  xrandr --output "$EDP" --primary --mode 1920x1200 --pos 0x0 2>>"$LOG_FILE" || log "WARN: $EDP reposition failed"
  xrandr --fb 1920x1200 2>>"$LOG_FILE" || log "WARN: fb shrink failed"

  # Ensure every named desktop I-X exists on the panel (targets for any fold below).
  log "Extending $EDP to I-X"
  bspc monitor "$EDP" -d I II III IV V VI VII VIII IX X

  # Fold any monitor bspwm still holds (race: its auto-removal hasn't fired) onto the panel.
  # bspc monitor -r transfers the removed monitor's desktops *with their windows* to the remaining
  # monitor (identity preserved); the normalize below collapses any name dupes onto the panel.
  for m in $(bspc query -M --names); do
    [ "$m" = "$EDP" ] && continue
    log "Folding stale monitor $m into $EDP, then removing it"
    bspc monitor "$m" -r 2>>"$LOG_FILE" || log "WARN: removing $m failed"
  done

  # Normalize the panel to I-X (collapses any duplicate empties left by -r).
  bspc monitor "$EDP" -d I II III IV V VI VII VIII IX X

  log "========== SINGLE-MONITOR SETUP COMPLETE =========="
fi
