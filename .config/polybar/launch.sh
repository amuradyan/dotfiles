#!/usr/bin/env zsh

# Polybar's click-left / exec handlers run via /bin/sh and inherit this
# script's PATH. ~/.local/bin (rofi-bluetooth lives there as a symlink)
# is added by ~/.profile, which X-session children don't always source.
export PATH="$HOME/.local/bin:$PATH"

# Kill existing bars first so re-runs (e.g. on monitor hotplug, which re-runs this)
# don't stack duplicate bars per monitor. Match by command line — NixOS wraps the
# polybar binary, so the process name isn't a plain "polybar" that killall would catch.
pkill -f 'polybar --reload top'
while pgrep -f 'polybar --reload top' >/dev/null; do sleep 0.2; done

if type "xrandr"; then
  for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    MONITOR=$m polybar --reload top &
  done
else
  polybar --reload top &
fi
