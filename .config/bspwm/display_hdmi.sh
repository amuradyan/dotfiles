#!/usr/bin/env bash

xrandr --output eDP-1 --primary --mode 1920x1080 \
       --output HDMI-1 --auto --mode 1920x1080 --above eDP-1 \
       --output DP-1 --off

bspc monitor HDMI-1 -d I II III IV V VI
bspc monitor eDP-1 -d VII VIII IX X
