#!/usr/bin/env bash

# Monitor brightness control script using xrandr
# Usage: ./brightness.sh [inc|dec] [step]
# Example: ./brightness.sh inc 0.1
#          ./brightness.sh dec 0.05

# Default step size if not specified
STEP=${2:-0.1}

# Get all connected monitors
MONITORS=$(xrandr --query | grep " connected" | cut -d" " -f1)

# Function to adjust brightness
adjust_brightness() {
  local action=$1
  local monitor=$2

  # Get current brightness
  current=$(xrandr --verbose --current | grep -i "brightness" | grep -oP '[0-9]*\.[0-9]*' | head -n 1)

  # Calculate new brightness
  if [ "$action" = "inc" ]; then
    new=$(echo "$current + $STEP" | bc)
    # Cap at maximum 1.0
    new=$(echo "if ($new > 1.0) 1.0 else $new" | bc)
  else
    new=$(echo "$current - $STEP" | bc)
    # Floor at minimum 0.1
    new=$(echo "if ($new < 0.1) 0.1 else $new" | bc)
  fi

  # Apply new brightness
  xrandr --output "$monitor" --brightness "$new"

  echo "Monitor $monitor: brightness changed from $current to $new"
}

# Check if action parameter is provided
if [ -z "$1" ]; then
  echo "Error: No action specified"
  echo "Usage: $0 [inc|dec] [step]"
  exit 1
fi

# Validate action parameter
if [ "$1" != "inc" ] && [ "$1" != "dec" ]; then
  echo "Error: Invalid action. Use 'inc' to increase or 'dec' to decrease"
  echo "Usage: $0 [inc|dec] [step]"
  exit 1
fi

# Apply brightness adjustment to all connected monitors
for monitor in $MONITORS; do
  adjust_brightness "$1" "$monitor"
done

# Notify user that brightness adjustment is complete
echo "Brightness adjustment complete for all monitors"
exit 0