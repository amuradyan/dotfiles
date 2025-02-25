#!/usr/bin/env bash

xrandr --output eDP-1 --auto  \
       --output HDMI-1-0 --primary --auto --above eDP-1

bspc wm --reorder-monitors eDP-1 HDMI-1-0

bspc monitor eDP-1 -d I II III IV
bspc monitor HDMI-1-0 -d V VI VII VIII IX X
