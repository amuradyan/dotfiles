#!/usr/bin/env bash

BATTERY_PATH="/sys/class/power_supply/BAT0"

suspend_laptop() {
  current_charge=$(cat "$BATTERY_PATH/capacity")
  charging_status=$(cat "$BATTERY_PATH/status")

  # Suspend the laptop when the battery reaches 3% or lower and is not charging
  if [ "$current_charge" -le 3 ] && [ "$charging_status" != "Charging" ]; then
    systemctl suspend
  fi
}

# Run the suspend check every 60 seconds
while true; do
  suspend_laptop
  sleep 60
done
