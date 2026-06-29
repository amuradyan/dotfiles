#!/usr/bin/env bash

LOG_FILE=/tmp/bspwm_monitor.log
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S.%3N')] [DISPLAY_HDMI] $*" >> "$LOG_FILE"; }

# Output names resolved by type (eDP-1/HDMI-1-0 under offload, eDP-1-1/HDMI-0
# under sync) and reverse-PRIME bound when on offload.
source ~/.config/bspwm/lib/detect_outputs.sh
source ~/.config/bspwm/lib/desktop_handoff.sh
ensure_prime_sink

log "========== DISPLAY_HDMI STARTED (mode=$GPU_MODE EDP=$EDP HDMI=$HDMI) =========="

# Step 1: position the outputs. Per-output xrandr calls under offload ('--auto'/'--above'/
# multi-output SIGFPE under reverse-PRIME); the harmless fb-realloc BadValue is logged, not fatal.
log "Step 1: Configuring displays (mode=$GPU_MODE)"
if [ "$GPU_MODE" = sync ]; then
  # NVIDIA primary resizes the framebuffer fine; stack the external above the panel.
  xrandr --output "$EDP"  --primary --mode 1920x1200 \
         --output "$HDMI" --auto --above "$EDP" 2>>"$LOG_FILE" || log "WARN: sync xrandr failed"
else
  # Offload/reverse-PRIME: stack the external ABOVE the panel (mirrors gpu-sync's --above). With the
  # modesetting Virtual pinned (services.xserver.screenSection, offload-only) the framebuffer
  # reallocates on demand — verified growing to 3840x3360 for a 4K-above-panel layout.
  HMODE=$(output_preferred_mode "$HDMI"); HMODE=${HMODE:-1920x1080}; HH=${HMODE#*x}
  xrandr --output "$HDMI" --mode "$HMODE" --pos 0x0 2>>"$LOG_FILE" || log "INFO: HDMI mode set ($HMODE; fb-realloc BadValue ignored)"
  xrandr --output "$EDP"  --primary --mode 1920x1200 --pos "0x$HH" --transform none 2>>"$LOG_FILE" || log "WARN: $EDP reposition failed"
fi

# Step 2: hand desktops V-X — whole, with their windows AND identity — from the panel back to the
# external. While undocked, bspwm parked V-X (with their windows) on the panel; handoff_desktops moves
# them back by ID. (bspwm resolves a desktop *name* globally and ignores -m, so per-window moves
# mis-target while V-X transiently exist on both monitors; whole-desktop moves by ID don't.) eDP keeps
# I-IV automatically; the external's throwaway default desktop is dropped once empty.
log "Step 2: Handing V-X back to $HDMI (identity-preserving)"
# Ensure the panel holds the full I-X set first: on a fresh boot bspwm only auto-created a single
# "Desktop", so there would be no V-X to hand over (-d renames the existing desktop to I and creates
# the rest, preserving any window); after an undock the panel already holds I-X so this is a no-op.
bspc monitor "$EDP" -d I II III IV V VI VII VIII IX X
handoff_desktops "$EDP" "$HDMI" V VI VII VIII IX X
log "  $HDMI now owns: $(bspc query -D -m "$HDMI" --names | tr '\n' ' ')"

# Step 3: panel leads the global desktop order (super+1..4 -> panel).
log "Step 3: Reordering monitors ($EDP first)"
bspc wm --reorder-monitors "$EDP" "$HDMI"

log "========== DISPLAY_HDMI COMPLETE (mode=$GPU_MODE) =========="
