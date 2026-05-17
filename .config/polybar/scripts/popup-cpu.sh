#!/usr/bin/env python3
import os, re

with open('/proc/loadavg') as f:
    la = f.read().split()

temp = None
for z in sorted(os.listdir('/sys/class/thermal')):
    if not z.startswith('thermal_zone'):
        continue
    try:
        with open(f'/sys/class/thermal/{z}/type') as f:
            t = f.read().strip()
        if t in ('x86_pkg_temp', 'coretemp', 'acpitz'):
            with open(f'/sys/class/thermal/{z}/temp') as f:
                temp = int(f.read().strip()) // 1000
            break
    except OSError:
        pass

cur_sum, cur_n = 0.0, 0
with open('/proc/cpuinfo') as f:
    for line in f:
        if line.startswith('cpu MHz'):
            cur_sum += float(line.split(':')[1])
            cur_n += 1
cur_ghz = cur_sum / cur_n / 1000 if cur_n else 0.0

try:
    with open('/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq') as f:
        max_ghz = int(f.read().strip()) / 1_000_000
except OSError:
    max_ghz = 0.0

print(f"load   {la[0]}  {la[1]}  {la[2]}")
if temp is not None:
    print(f"temp   {temp} C")
if max_ghz:
    print(f"freq   {cur_ghz:.1f} / {max_ghz:.1f} GHz")
else:
    print(f"freq   {cur_ghz:.1f} GHz")
