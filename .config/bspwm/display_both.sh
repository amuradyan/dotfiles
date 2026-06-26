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
  # Offload/reverse-PRIME: the X screen is frozen at its boot size (e.g. 7680x2400)
  # and cannot grow, and '--auto'/'--above'/multi-output xrandr calls SIGFPE. Lay all
  # three side-by-side with explicit modes. NOTE: a panel + two large externals can
  # exceed the frozen framebuffer width; if an output stays dark, reboot into the
  # gpu-sync entry — the proper path for multi-monitor docking (you're on AC anyway).
  log "Offload 3-monitor layout is framebuffer-limited; gpu-sync recommended for docking."
  HMODE=$(xrandr -q | grep -A1 "^$HDMI connected" | tail -1 | awk '{print $1}')
  DMODE=$(xrandr -q | grep -A1 "^$DP connected"   | tail -1 | awk '{print $1}')
  HW=${HMODE%x*}
  xrandr --output "$EDP"  --primary --mode 1920x1200 --pos 0x0 --transform none 2>/dev/null || true
  xrandr --output "$HDMI" --mode "${HMODE:-1920x1080}" --pos 1920x0 2>/dev/null || true
  xrandr --output "$DP"   --mode "${DMODE:-1920x1080}" --pos "$((1920 + ${HW:-1920}))x0" 2>/dev/null || true
fi

bspc monitor "$HDMI" -d I II III
bspc monitor "$DP"   -d IV V VI
bspc monitor "$EDP"  -d VII VIII IX X
