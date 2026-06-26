#!/usr/bin/env bash

# DisplayPort only. Output names resolved by type for offload/sync parity.
source ~/.config/bspwm/lib/detect_outputs.sh
ensure_prime_sink

if [ "$GPU_MODE" = sync ]; then
  # NVIDIA primary resizes the framebuffer fine; stack the external above the panel.
  xrandr --output "$EDP" --primary --mode 1920x1200 \
         --output "$DP"  --auto --above "$EDP"
else
  # Offload/reverse-PRIME: the X screen is frozen at its boot size and cannot grow,
  # and '--auto'/'--above'/multi-output xrandr calls SIGFPE. Configure each output
  # separately with an explicit mode, side-by-side within the existing framebuffer.
  DMODE=$(xrandr -q | grep -A1 "^$DP connected" | tail -1 | awk '{print $1}')
  xrandr --output "$EDP" --primary --mode 1920x1200 --pos 0x0 --transform none 2>/dev/null || true
  xrandr --output "$DP"  --mode "${DMODE:-1920x1080}" --pos 1920x0 2>/dev/null || true
fi

bspc monitor "$DP"  -d I II III IV V VI
bspc monitor "$EDP" -d VII VIII IX X
