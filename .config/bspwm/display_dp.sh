#!/usr/bin/env bash

xrandr --output eDP-1 --primary --mode 1920x1080 \
       --output DP-1 --auto --above eDP-1 \
       --output HDMI-1 --off

bspc monitor DP-1 -d I II III IV V VI
bspc monitor eDP-1 -d VII VIII IX X
