#!/usr/bin/env bash

BATTERY_PATH="/sys/class/power_supply/BAT0"

FYI=1
WORRYING=2
CRITICAL=3

get_notification_params() {
  id=$1

  case $id in
    $FYI)
      echo "low #006600 #ffffff"
      ;;
    $WORRYING)
      echo "normal #ffff00 #000000"
      ;;
    $CRITICAL)
      echo "critical #993333 #000000"
      ;;
    *)
      echo "Invalid ID for notification"
      ;;
  esac
}

send_notification() {
  id=$1
  read urgency bgcolor fgcolor <<< $(get_notification_params "$id")
  current_charge=$(cat "$BATTERY_PATH/capacity")

  if [ "$urgency" != "Invalid ID for notification" ]; then
    dunstify \
      -u "$urgency" \
      --hints=string:bgcolor:"$bgcolor" \
      --hints=string:fgcolor:"$fgcolor" \
      -r "$id" \
      "Battery Warning" "Battery level is at ${current_charge}%!"
  fi
}

previous_charge=-1

while true; do
  current_charge=$(cat "$BATTERY_PATH/capacity")

  if [ "$current_charge" -lt "$previous_charge" ]; then
    if [ "$current_charge" -le 5 ] && [ "$current_charge" -ge 2 ]; then
      send_notification "$CRITICAL"
    elif [ "$current_charge" -eq 10 ]; then
      send_notification "$WORRYING"
    elif [ "$current_charge" -eq 15 ]; then
      send_notification "$FYI"
    fi
  fi

  previous_charge="$current_charge"

  sleep 60
done
