#!/usr/bin/env bash

# DisplayPort only. Output names resolved by type for offload/sync parity.
source ~/.config/bspwm/lib/detect_outputs.sh
ensure_prime_sink

if [ "$GPU_MODE" = sync ]; then
  # NVIDIA primary resizes the framebuffer fine; stack the external above the panel.
  xrandr --output "$EDP" --primary --mode 1920x1200 \
         --output "$DP"  --auto --above "$EDP"
else
  # Offload/reverse-PRIME: per-output explicit --mode/--pos calls only ('--auto',
  # '--above' and multi-output calls SIGFPE); the harmless fb-shrink BadValue is
  # ignored. The X screen can't resize at runtime, so the layout must fit the canvas
  # pinned at boot (services.xserver.screenSection Virtual 3840x3360, offload-only).
  # Stack the external ABOVE the panel when the canvas is tall enough, else side-by-side.
  DMODE=$(xrandr -q | grep -A1 "^$DP connected" | tail -1 | awk '{print $1}')
  DMODE=${DMODE:-1920x1080}; DH=${DMODE#*x}
  SCRH=$(xrandr -q | sed -n '1s/.*current [0-9]\+ x \([0-9]\+\).*/\1/p')
  if [ "${SCRH:-0}" -ge "$(( DH + 1200 ))" ]; then
    xrandr --output "$DP"  --mode "$DMODE" --pos 0x0 2>/dev/null || true
    xrandr --output "$EDP" --primary --mode 1920x1200 --pos "0x$DH" --transform none 2>/dev/null || true
  else
    xrandr --output "$EDP" --primary --mode 1920x1200 --pos 0x0 --transform none 2>/dev/null || true
    xrandr --output "$DP"  --mode "$DMODE" --pos 1920x0 2>/dev/null || true
  fi
fi

bspc monitor "$DP"  -d I II III IV V VI
bspc monitor "$EDP" -d VII VIII IX X
