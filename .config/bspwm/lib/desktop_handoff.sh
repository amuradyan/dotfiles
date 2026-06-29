#!/usr/bin/env bash

# handoff_desktops FROM_MONITOR TO_MONITOR DESKTOP [DESKTOP...]
#
# Move the named desktops — whole, with their windows AND their identity (name) — from FROM_MONITOR
# to TO_MONITOR, then drop TO_MONITOR's throwaway default desktop. Used when docking: the panel's
# V-X (parked there while undocked) move back onto the freshly-connected external.
#
# WHY whole-desktop moves instead of per-window migration: bspwm resolves a desktop *name* globally
# and IGNORES a co-given `-m MONITOR` (verified: with "IV" on two monitors, `bspc query -D -m HDMI -d IV`
# returns the *other* monitor's IV). So any "move the windows on monitor M's desktop NAME" logic
# mis-targets the instant the same name exists on both monitors (exactly the transient state while
# docking). Moving whole desktops by their unique ID never creates a duplicate name to resolve.

handoff_desktops() {
  local from_monitor=$1 to_monitor=$2
  shift 2

  if [ -z "$from_monitor" ] || [ -z "$to_monitor" ] || [ -z "$1" ]; then
    echo "Error: handoff_desktops requires FROM_MONITOR TO_MONITOR DESKTOP [DESKTOP...]" >&2
    return 1
  fi

  local want=" $* " first=$1 id name w

  # Move the wanted desktops that currently live on FROM to TO. `bspc query -D -m FROM` (monitor only)
  # IS honored; we resolve each desktop's name from its ID, never via the broken `-m -d NAME` form.
  for id in $(bspc query -D -m "$from_monitor"); do
    name=$(bspc query -D -d "$id" --names)
    case "$want" in *" $name "*) bspc desktop "$id" --to-monitor "$to_monitor" ;; esac
  done

  # Locate the first wanted desktop's ID on TO — the fold target for any leftover default below.
  local target=""
  for id in $(bspc query -D -m "$to_monitor"); do
    [ "$(bspc query -D -d "$id" --names)" = "$first" ] && { target=$id; break; }
  done

  # Drop TO's leftover default(s): any desktop on TO whose name is NOT in the wanted set. On a fresh
  # connect that's the single auto-created "Desktop" — and bspwm may have parked a window on it — so
  # fold its windows into the first wanted desktop first, then remove it regardless of emptiness. On a
  # re-dock the wanted desktops already moved over and there is no leftover (idempotent).
  for id in $(bspc query -D -m "$to_monitor"); do
    name=$(bspc query -D -d "$id" --names)
    case "$want" in
      *" $name "*) ;;
      *)
        if [ -n "$target" ]; then
          for w in $(bspc query -N -d "$id" -n .window); do
            bspc node "$w" --to-desktop "$target"
          done
        fi
        bspc desktop "$id" -r 2>/dev/null
        ;;
    esac
  done
}
