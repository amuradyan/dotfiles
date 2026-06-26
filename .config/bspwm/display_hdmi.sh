#!/usr/bin/env bash

LOG_FILE=/tmp/bspwm_monitor.log
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S.%3N')] [DISPLAY_HDMI] $*" >> "$LOG_FILE"; }

# Output names resolved by type (eDP-1/HDMI-1-0 under offload, eDP-1-1/HDMI-0
# under sync) and reverse-PRIME bound when on offload.
source ~/.config/bspwm/lib/detect_outputs.sh
ensure_prime_sink

log "========== DISPLAY_HDMI STARTED (mode=$GPU_MODE EDP=$EDP HDMI=$HDMI) =========="

log "Step 1: Window state BEFORE recording:"
bspc query -N | xargs -I {} sh -c 'desktop=$(bspc query -D -n {} --names 2>/dev/null); monitor=$(bspc query -M -n {} --names 2>/dev/null); echo "  $monitor:$desktop - window {}"' >> "$LOG_FILE" 2>&1

log "Step 2: Recording window positions on desktops V-X BEFORE xrandr"
log "  Current $EDP desktops: $(bspc query -D -m "$EDP" --names | tr '\n' ' ')"
declare -A window_desktop_map
for desktop in V VI VII VIII IX X; do
  log "  Querying -m $EDP -d $desktop..."
  for win in $(bspc query -N -m "$EDP" -d $desktop 2>/dev/null); do
    window_desktop_map[$win]=$desktop
    log "    Recording: window $win on desktop $desktop"
  done
done
log "  Total windows recorded: ${#window_desktop_map[@]}"

log "Step 3: Running xrandr to configure displays (mode=$GPU_MODE)"
if [ "$GPU_MODE" = sync ]; then
  # NVIDIA primary resizes the framebuffer fine; stack the external above the panel.
  xrandr --output "$EDP"  --primary --mode 1920x1200 \
         --output "$HDMI" --auto --above "$EDP"
else
  # Offload/reverse-PRIME: stack the external ABOVE the panel (mirrors gpu-sync's --above).
  # With the modesetting Virtual pinned (services.xserver.screenSection, offload-only) the
  # framebuffer reallocates on demand — verified growing to 3840x3360 for a 4K-above-panel
  # layout — so position the external on top and the panel directly below it. Per-output
  # calls only ('--auto'/'--above'/multi-output SIGFPE under reverse-PRIME); the harmless
  # fb-realloc BadValue is ignored.
  HMODE=$(xrandr -q | grep -A1 "^$HDMI connected" | tail -1 | awk '{print $1}')
  HMODE=${HMODE:-1920x1080}; HH=${HMODE#*x}
  xrandr --output "$HDMI" --mode "$HMODE" --pos 0x0 2>/dev/null || true
  xrandr --output "$EDP"  --primary --mode 1920x1200 --pos "0x$HH" --transform none 2>/dev/null || true
fi

log "Step 4: Window state AFTER xrandr:"
bspc query -N | xargs -I {} sh -c 'desktop=$(bspc query -D -n {} --names 2>/dev/null); monitor=$(bspc query -M -n {} --names 2>/dev/null); echo "  $monitor:$desktop - window {}"' >> "$LOG_FILE" 2>&1

log "Step 5: Shrinking $EDP to I-IV (windows will auto-relocate to IV)"
bspc monitor "$EDP" -d I II III IV

log "Step 6: Window state AFTER shrinking $EDP (windows auto-relocated):"
bspc query -N | xargs -I {} sh -c 'desktop=$(bspc query -D -n {} --names 2>/dev/null); monitor=$(bspc query -M -n {} --names 2>/dev/null); echo "  $monitor:$desktop - window {}"' >> "$LOG_FILE" 2>&1

log "Step 7: Creating $HDMI with V-X"
bspc monitor "$HDMI" -d V VI VII VIII IX X

log "Step 8: Restoring windows to their original desktops on $HDMI"
for win in "${!window_desktop_map[@]}"; do
  original_desktop="${window_desktop_map[$win]}"
  log "  Moving window $win to desktop $original_desktop"
  bspc node $win -d $original_desktop
done

log "Step 9: Window state AFTER restoring windows to $HDMI:"
bspc query -N | xargs -I {} sh -c 'desktop=$(bspc query -D -n {} --names 2>/dev/null); monitor=$(bspc query -M -n {} --names 2>/dev/null); echo "  $monitor:$desktop - window {}"' >> "$LOG_FILE" 2>&1

log "Step 10: Reordering monitors"
bspc wm --reorder-monitors "$EDP" "$HDMI"

log "========== DISPLAY_HDMI COMPLETE (mode=$GPU_MODE) =========="
