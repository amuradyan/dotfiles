#!/usr/bin/env bash

LOG_FILE=/tmp/bspwm_monitor.log
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S.%3N')] [DISPLAY_BOTH] $*" >> "$LOG_FILE"; }

# HDMI + DP both attached. Output names resolved by type for offload/sync parity.
source ~/.config/bspwm/lib/detect_outputs.sh
source ~/.config/bspwm/lib/migrate_windows.sh
ensure_prime_sink

if [ "$GPU_MODE" = sync ]; then
  # NVIDIA primary resizes the framebuffer; original arrangement (HDMI right, DP above).
  xrandr --output "$EDP"  --primary \
         --output "$HDMI" --auto --right-of "$EDP" \
         --output "$DP"   --auto --above "$EDP" 2>>"$LOG_FILE" || log "WARN: sync xrandr failed"
else
  # Offload/reverse-PRIME: the framebuffer reallocates on demand, but two externals don't lay out
  # cleanly here (stacking two 4K above the panel needs ~5520 tall, beyond the pinned Virtual;
  # side-by-side needs a very wide canvas). Drive a single stacked external cleanly and use gpu-sync
  # for a true multi-monitor battlestation (the NVIDIA driver resizes the fb freely there, and
  # you're on AC anyway).
  log "Offload framebuffer fits one stacked external; dual external needs gpu-sync. Driving HDMI only."
  exec ~/.config/bspwm/display_hdmi.sh
fi

# Panel owns I-IV and leads the count (super+1..4 -> panel); externals take V-X (HDMI V-VII,
# DP VIII-X). Hand each external its desktops with their windows (identity-preserving): create the
# external desktops, migrate by name (monitor-scoped), then shrink the panel so nothing strands on IV.
bspc monitor "$HDMI" -d V VI VII
bspc monitor "$DP"   -d VIII IX X
migrate_windows "$EDP" "$HDMI" V VI VII
migrate_windows "$EDP" "$DP"   VIII IX X
bspc monitor "$EDP" -d I II III IV
bspc wm --reorder-monitors "$EDP" "$HDMI" "$DP"
