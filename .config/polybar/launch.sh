#!/usr/bin/env bash

if type "xrandr"; then
  for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    MONITOR=$m polybar --reload top &
  done
else
  polybar --reload top &
fi

# killall -q polybar

# polybar top >> /tmp/top_bar.log 2>&1 &
