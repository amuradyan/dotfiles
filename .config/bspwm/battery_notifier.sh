#!/usr/bin/env bash

BATTERY_PATH="/sys/class/power_supply/BAT0"

send_notification() {
  level=$1
  urgency=$2
  bgcolor=$3
  fgcolor=$4

  dunstify \
    -u "$urgency" \
    --hints=string:bgcolor:"$bgcolor" \
    --hints=string:fgcolor:"$fgcolor" \
    "Battery Warning" "Battery level is at ${level}%!"
}

previous_charge=-1

while true; do
  current_charge=$(cat "$BATTERY_PATH/capacity")

  if [ "$current_charge" -lt "$previous_charge" ]; then
    if [ "$current_charge" -le 5 ] && [ "$current_charge" -ge 2 ]; then
      send_notification "$current_charge" critical "#993333" "#000000"
    elif [ "$current_charge" -eq 10 ]; then
      send_notification "$current_charge" normal "#ffff00" "#000000"
    elif [ "$current_charge" -eq 15 ]; then
      send_notification "$current_charge" low "#006600" "#ffffff"
    fi
  fi

  previous_charge="$current_charge"

  sleep 60
done
