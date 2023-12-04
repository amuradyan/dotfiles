#!/usr/bin/env bash

xrandr --output eDP-1 --primary --mode 1920x1080 \
       --output HDMI-1 --auto --mode 1920x1080 --right-of eDP-1 \
       --output DP-1 --auto --above eDP-1

bspc monitor HDMI-1 -d I II III
bspc monitor DP-1 -d IV V VI
bspc monitor eDP-1 -d VII VIII IX X
