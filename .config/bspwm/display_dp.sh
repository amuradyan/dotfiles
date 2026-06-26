#!/usr/bin/env bash

LOG_FILE=/tmp/bspwm_monitor.log
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S.%3N')] [DISPLAY_DP] $*" >> "$LOG_FILE"; }

# DisplayPort only. Output names resolved by type for offload/sync parity.
source ~/.config/bspwm/lib/detect_outputs.sh
source ~/.config/bspwm/lib/migrate_windows.sh
ensure_prime_sink

log "========== DISPLAY_DP STARTED (mode=$GPU_MODE EDP=$EDP DP=$DP) =========="

log "Step 1: Configuring displays (mode=$GPU_MODE)"
if [ "$GPU_MODE" = sync ]; then
  # NVIDIA primary resizes the framebuffer fine; stack the external above the panel.
  xrandr --output "$EDP" --primary --mode 1920x1200 \
         --output "$DP"  --auto --above "$EDP" 2>>"$LOG_FILE" || log "WARN: sync xrandr failed"
else
  # Offload/reverse-PRIME: stack the external above the panel (mirrors gpu-sync's --above). The
  # framebuffer reallocates on demand (Virtual pinned via services.xserver.screenSection,
  # offload-only). Per-output calls only; the harmless fb-realloc BadValue is logged, not fatal.
  DMODE=$(output_preferred_mode "$DP"); DMODE=${DMODE:-1920x1080}; DH=${DMODE#*x}
  xrandr --output "$DP"  --mode "$DMODE" --pos 0x0 2>>"$LOG_FILE" || log "INFO: DP mode set ($DMODE; fb-realloc BadValue ignored)"
  xrandr --output "$EDP" --primary --mode 1920x1200 --pos "0x$DH" --transform none 2>>"$LOG_FILE" || log "WARN: $EDP reposition failed"
fi

# Hand V-X (with their windows) to DP, preserving identity. Same ordering as display_hdmi:
# create -> migrate by name (monitor-scoped) -> shrink the panel, so nothing is stranded on IV.
log "Step 2: Handing V-X to $DP (identity-preserving)"
bspc monitor "$DP"  -d V VI VII VIII IX X
migrate_windows "$EDP" "$DP" V VI VII VIII IX X
bspc monitor "$EDP" -d I II III IV
bspc wm --reorder-monitors "$EDP" "$DP"

log "========== DISPLAY_DP COMPLETE (mode=$GPU_MODE) =========="
