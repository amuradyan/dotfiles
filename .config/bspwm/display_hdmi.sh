#!/usr/bin/env bash

xrandr --output eDP-1-1 --primary --mode 1920x1200  \
       --output HDMI-0 --auto --above eDP-1-1

bspc monitor eDP-1-1 -d I II III IV
bspc monitor HDMI-0 -d V VI VII VIII IX X

bspc wm --reorder-monitors eDP-1-1 HDMI-0
