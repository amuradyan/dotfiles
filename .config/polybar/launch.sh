#!/usr/bin/env bash

killall -q polybar

polybar top >> /tmp/top_bar.log 2>&1 &
