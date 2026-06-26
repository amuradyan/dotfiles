#!/usr/bin/env bash

# DisplayPort only. Output names resolved by type for offload/sync parity.
source ~/.config/bspwm/lib/detect_outputs.sh
ensure_prime_sink

if [ "$GPU_MODE" = sync ]; then
  # NVIDIA primary resizes the framebuffer fine; stack the external above the panel.
  xrandr --output "$EDP" --primary --mode 1920x1200 \
         --output "$DP"  --auto --above "$EDP"
else
  # Offload/reverse-PRIME: stack the external ABOVE the panel (mirrors gpu-sync's --above).
  # The modesetting framebuffer reallocates on demand (Virtual pinned via
  # services.xserver.screenSection, offload-only), so position the external on top and the
  # panel directly below it. Per-output calls only ('--auto'/'--above'/multi-output SIGFPE
  # under reverse-PRIME); the harmless fb-realloc BadValue is ignored.
  DMODE=$(xrandr -q | grep -A1 "^$DP connected" | tail -1 | awk '{print $1}')
  DMODE=${DMODE:-1920x1080}; DH=${DMODE#*x}
  xrandr --output "$DP"  --mode "$DMODE" --pos 0x0 2>/dev/null || true
  xrandr --output "$EDP" --primary --mode 1920x1200 --pos "0x$DH" --transform none 2>/dev/null || true
fi

bspc monitor "$DP"  -d I II III IV V VI
bspc monitor "$EDP" -d VII VIII IX X
