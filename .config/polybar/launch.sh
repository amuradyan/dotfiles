#!/usr/bin/env zsh

# Polybar's click-left / exec handlers run via /bin/sh and inherit this
# script's PATH. ~/.local/bin (rofi-bluetooth lives there as a symlink)
# is added by ~/.profile, which X-session children don't always source.
export PATH="$HOME/.local/bin:$PATH"

if type "xrandr"; then
  for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    MONITOR=$m polybar --reload top &
  done
else
  polybar --reload top &
fi
