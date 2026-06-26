#!/usr/bin/env zsh

# Polybar's click-left / exec handlers run via /bin/sh and inherit this
# script's PATH. ~/.local/bin (rofi-bluetooth lives there as a symlink)
# is added by ~/.profile, which X-session children don't always source.
export PATH="$HOME/.local/bin:$PATH"

LOG_FILE=/tmp/bspwm_monitor.log
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S.%3N')] [POLYBAR] $*" >> "$LOG_FILE"; }

# Kill existing bars first so re-runs (e.g. on monitor hotplug, which re-runs this) don't stack
# duplicate bars per monitor. Match by command line — NixOS wraps the polybar binary, so the
# process name isn't a plain "polybar" that killall would catch. Bound the wait and escalate to
# SIGKILL if a bar won't exit (e.g. hung on an X11 call) so we never spin forever and block startup.
pkill -f 'polybar --reload top'
for _ in {1..15}; do
  pgrep -f 'polybar --reload top' >/dev/null || break
  sleep 0.2
done
if pgrep -f 'polybar --reload top' >/dev/null; then
  log "polybar did not exit on SIGTERM within 3s; sending SIGKILL"
  pkill -9 -f 'polybar --reload top'
  sleep 0.2
fi

monitors=$(xrandr --query 2>/dev/null | grep " connected" | cut -d" " -f1)
if [ -n "$monitors" ]; then
  for m in ${(f)monitors}; do
    MONITOR=$m polybar --reload top &
  done
else
  log "WARN: no connected monitors reported by xrandr; not spawning bars"
fi
