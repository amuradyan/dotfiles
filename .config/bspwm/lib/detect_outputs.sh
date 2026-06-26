#!/usr/bin/env bash
# detect_outputs.sh — resolve X outputs by connector TYPE so the bspwm display
# scripts work under both NVIDIA PRIME modes (the output names differ):
#   sync    (gpu-sync boot):  panel eDP-1-1 · HDMI-0   · DP-1
#   offload (default boot):   panel eDP-1   · HDMI-1-0 · DP-1-0
# Source this file; it sets EDP, HDMI, DP, GPU_MODE and defines ensure_prime_sink.

# First *connected* output whose name starts with $1 (anchored, so 'DP' != 'eDP').
_first_connected() {
  xrandr -q | grep -w connected | grep -E "^$1" | awk '{print $1}' | head -1
}

EDP=$(_first_connected 'eDP'); EDP=${EDP:-eDP-1}
HDMI=$(_first_connected 'HDMI')
DP=$(_first_connected 'DP')

# NVIDIA render-offload provider (NVIDIA-G0 under offload); empty on pure Intel.
NV=$(xrandr --listproviders 2>/dev/null | sed -n 's/.*name:\(NVIDIA[^ ]*\).*/\1/p' | head -1)

# Panel name is the simplest reliable tell: Intel-primary (offload) drops the
# trailing GPU index, so eDP-1 => offload, eDP-1-1 => sync.
case "$EDP" in
  eDP-1) GPU_MODE=offload ;;
  *)     GPU_MODE=sync ;;
esac

# Under offload the external connectors hang off the dGPU; bind them to the Intel
# source (reverse PRIME) so they can be lit. Idempotent; a no-op under sync or
# when nothing external is attached.
ensure_prime_sink() {
  [ "$GPU_MODE" = offload ] || return 0
  [ -n "$HDMI$DP" ]         || return 0
  [ -n "$NV" ]              || return 0
  xrandr --setprovideroutputsource "$NV" modesetting 2>/dev/null || true
}

# Preferred mode (the '+'-marked resolution) for a connected output, e.g. "3840x2160".
# Robust to xrandr column layout — reads the indented mode block under the output header and
# returns the first preferred line. Empty if the output is absent/disconnected (callers fall back).
output_preferred_mode() {
  xrandr -q | awk -v o="$1" '
    $1 == o && $2 == "connected" { f = 1; next }  # enter the block (exact field: "disconnected" excluded)
    f && /^[^[:space:]]/         { f = 0 }        # a non-indented line starts the next output
    f && /\+/                    { print $1; exit } # indented mode line marked preferred
  '
}
