#!/usr/bin/env python3
# Battery popup for polybar (clicked via popup-show.sh bat).
# Lines: pack health (full vs design) · cycle count · charge + TLP cap ·
#        live draw and time remaining (the actionable line; adapts to the state).
import os

BASE = '/sys/class/power_supply/BAT0'


def read(name):
    try:
        with open(os.path.join(BASE, name)) as f:
            return f.read().strip()
    except OSError:
        return None


def num(name):
    try:
        return int(read(name))
    except (TypeError, ValueError):
        return None


status = read('status') or 'unknown'
cap    = num('capacity')
e_full = num('energy_full')
e_des  = num('energy_full_design')
e_now  = num('energy_now')
p_now  = num('power_now')
cycles = num('cycle_count')
limit  = num('charge_control_end_threshold')

# Fallback for packs that report charge_* (µAh) + voltage instead of energy_* (µWh).
if e_full is None:
    volt = num('voltage_now')
    if volt:
        c_full, c_des, c_now = num('charge_full'), num('charge_full_design'), num('charge_now')
        if c_full: e_full = c_full * volt // 1_000_000
        if c_des:  e_des  = c_des  * volt // 1_000_000
        if c_now:  e_now  = c_now  * volt // 1_000_000
        cur = num('current_now')
        if p_now is None and cur:
            p_now = cur * volt // 1_000_000


def hm(hours):
    m = max(0, int(round(hours * 60)))
    return f"{m // 60}h {m % 60:02d}m"


if e_full and e_des:
    print(f"{'health':<8}{round(100 * e_full / e_des)}%   {e_full / 1e6:.1f} / {e_des / 1e6:.1f} Wh")
if cycles is not None:
    print(f"{'cycles':<8}{cycles}")
if cap is not None:
    print(f"{'charge':<8}{cap}%" + (f"   (cap {limit}%)" if limit else ""))

# Live draw + time remaining — the most useful dynamic metric.
w = (p_now or 0) / 1e6
st = status.lower()
if st == 'discharging' and p_now and e_now:
    print(f"{'draw':<8}{w:.1f} W  ·  {hm(e_now / p_now)} left")
elif st == 'charging' and p_now and e_full and e_now:
    print(f"{'draw':<8}{w:.1f} W  ·  {hm((e_full - e_now) / p_now)} to full")
elif st in ('not charging', 'full'):
    print(f"{'draw':<8}on AC · holding ({status})")
else:
    print(f"{'draw':<8}{w:.1f} W · {status}")
