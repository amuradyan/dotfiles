#!/usr/bin/env bash

LOG_FILE=/tmp/bspwm_monitor.log
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S.%3N')] [DISPLAY_BOTH] $*" >> "$LOG_FILE"; }

# HDMI + DP both attached. Output names resolved by type for offload/sync parity.
source ~/.config/bspwm/lib/detect_outputs.sh
ensure_prime_sink

if [ "$GPU_MODE" = sync ]; then
  # NVIDIA primary resizes the framebuffer; original arrangement (HDMI right, DP above).
  xrandr --output "$EDP"  --primary \
         --output "$HDMI" --auto --right-of "$EDP" \
         --output "$DP"   --auto --above "$EDP"
else
  # Offload/reverse-PRIME: the canvas pinned at boot (Virtual 3840x3360, offload-only)
  # fits ONE stacked external + panel, never two externals — any 2-external arrangement
  # exceeds it (side-by-side > 3840 wide, double-stack > 3360 tall). Drive a single
  # stacked external cleanly and recommend gpu-sync for a true multi-monitor
  # battlestation (the NVIDIA driver resizes the fb there, and you're on AC anyway).
  log "Offload framebuffer fits one stacked external; dual external needs gpu-sync. Driving HDMI only."
  exec ~/.config/bspwm/display_hdmi.sh
fi

bspc monitor "$HDMI" -d I II III
bspc monitor "$DP"   -d IV V VI
bspc monitor "$EDP"  -d VII VIII IX X
