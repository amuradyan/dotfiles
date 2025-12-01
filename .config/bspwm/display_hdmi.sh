#!/usr/bin/env bash

LOG_FILE=/tmp/bspwm_monitor.log
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S.%3N')] [DISPLAY_HDMI] $*" >> "$LOG_FILE"; }

log "========== DISPLAY_HDMI STARTED (EXPERIMENT 5B: RECORD BEFORE XRANDR) =========="

log "Step 1: Window state BEFORE recording:"
bspc query -N | xargs -I {} sh -c 'desktop=$(bspc query -D -n {} --names 2>/dev/null); monitor=$(bspc query -M -n {} --names 2>/dev/null); echo "  $monitor:$desktop - window {}"' >> "$LOG_FILE" 2>&1

log "Step 2: Recording window positions on desktops V-X BEFORE xrandr"
log "  Current eDP-1-1 desktops: $(bspc query -D -m eDP-1-1 --names | tr '\n' ' ')"
declare -A window_desktop_map
for desktop in V VI VII VIII IX X; do
  log "  Querying -m eDP-1-1 -d $desktop..."
  for win in $(bspc query -N -m eDP-1-1 -d $desktop 2>/dev/null); do
    window_desktop_map[$win]=$desktop
    log "    Recording: window $win on desktop $desktop"
  done
done
log "  Total windows recorded: ${#window_desktop_map[@]}"

log "Step 3: Running xrandr to configure displays"
xrandr --output eDP-1-1 --primary --mode 1920x1200  \
       --output HDMI-0 --auto --above eDP-1-1

log "Step 4: Window state AFTER xrandr:"
bspc query -N | xargs -I {} sh -c 'desktop=$(bspc query -D -n {} --names 2>/dev/null); monitor=$(bspc query -M -n {} --names 2>/dev/null); echo "  $monitor:$desktop - window {}"' >> "$LOG_FILE" 2>&1

log "Step 5: Shrinking eDP-1-1 to I-IV (windows will auto-relocate to IV)"
bspc monitor eDP-1-1 -d I II III IV

log "Step 6: Window state AFTER shrinking eDP-1-1 (windows auto-relocated):"
bspc query -N | xargs -I {} sh -c 'desktop=$(bspc query -D -n {} --names 2>/dev/null); monitor=$(bspc query -M -n {} --names 2>/dev/null); echo "  $monitor:$desktop - window {}"' >> "$LOG_FILE" 2>&1

log "Step 7: Creating HDMI-0 with V-X"
bspc monitor HDMI-0 -d V VI VII VIII IX X

log "Step 8: Restoring windows to their original desktops on HDMI-0"
for win in "${!window_desktop_map[@]}"; do
  original_desktop="${window_desktop_map[$win]}"
  log "  Moving window $win to desktop $original_desktop"
  bspc node $win -d $original_desktop
done

log "Step 9: Window state AFTER restoring windows to HDMI-0:"
bspc query -N | xargs -I {} sh -c 'desktop=$(bspc query -D -n {} --names 2>/dev/null); monitor=$(bspc query -M -n {} --names 2>/dev/null); echo "  $monitor:$desktop - window {}"' >> "$LOG_FILE" 2>&1

log "Step 10: Reordering monitors"
bspc wm --reorder-monitors eDP-1-1 HDMI-0

log "========== DISPLAY_HDMI COMPLETE (EXPERIMENT 5: POSITION TRACKING) =========="
