#!/usr/bin/env bash
# Spawned by polybar's format-action when the icon is clicked.
# Renders the matching stat script's output as a rofi popup positioned
# under the bar that contains the click.
# usage: popup-show.sh <cpu|mem|disk>

set -u

module="${1:-}"
scripts=~/.config/polybar/scripts

case "$module" in
  cpu)  body=$("$scripts/popup-cpu.sh")  ; w=320 ;;
  mem)  body=$("$scripts/popup-mem.sh")  ; w=280 ;;
  disk) body=$("$scripts/popup-disk.sh") ; w=300 ;;
  *) echo "usage: $0 <cpu|mem|disk>" >&2; exit 2 ;;
esac

eval "$(xdotool getmouselocation --shell)"
icon_x=${X:-0}

# Find the polybar bar window containing the click. Adapts to whichever
# monitor was clicked and to bar repositioning when monitors come and go.
bar_bottom=28   # safe default for a top-of-screen bar
for win in $(xdotool search --class polybar 2>/dev/null); do
  eval "$(xdotool getwindowgeometry --shell "$win" 2>/dev/null)"
  if [ "${WIDTH:-0}" -ge 800 ] \
      && [ "$icon_x" -ge "$X" ] \
      && [ "$icon_x" -lt "$((X + WIDTH))" ]; then
    bar_bottom=$((Y + HEIGHT))
    break
  fi
done

xoff=$(( icon_x - w / 2 ))
[ "$xoff" -lt 0 ] && xoff=0
yoff=$(( bar_bottom + 1 ))

exec rofi -dmenu -p "" -mesg "$body" \
  -theme ~/.config/rofi/popup.rasi \
  -theme-str "window { width: ${w}px; }" \
  -location 1 -xoffset "$xoff" -yoffset "$yoff" \
  -lines 0 -no-fixed-num-lines \
  < /dev/null
