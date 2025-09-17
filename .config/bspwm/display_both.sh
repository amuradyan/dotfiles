#!/usr/bin/env bash

xrandr --output eDP-1-1 --primary \
       --output HDMI-0 --auto --right-of eDP-1-1 \
       --output DP-1 --auto --above eDP-1-1

bspc monitor HDMI-0 -d I II III
bspc monitor DP-1 -d IV V VI
bspc monitor eDP-1-1 -d VII VIII IX X
