#!/usr/bin/env python3
"""3-finger touchpad gesture handler for bspwm.

L/R swipe: continuous desktop switch — one step per PX_PER_DESKTOP of motion.
Up swipe : rofi -show window, fired once at gesture end.
"""

import re
import subprocess
import sys

PX_PER_DESKTOP = 80
UP_PX_THRESHOLD = 60
DEVICE = "/dev/input/by-path/pci-0000:00:15.0-platform-i2c_designware.0-event-mouse"

UPDATE_RE = re.compile(
    r"GESTURE_SWIPE_UPDATE\b.*?\s(\d+)\s+(-?\d+(?:\.\d+)?)/\s*(-?\d+(?:\.\d+)?)"
)
BEGIN_RE = re.compile(r"GESTURE_SWIPE_BEGIN\b.*?\s(\d+)\s*$")


def spawn(*argv):
    subprocess.Popen(
        argv, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True
    )


def main():
    proc = subprocess.Popen(
        ["libinput", "debug-events", "--device", DEVICE],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        bufsize=1,
    )

    fingers = 0
    dx = dy = 0.0
    dispatched_x = 0.0

    for line in proc.stdout:
        if "GESTURE_SWIPE_BEGIN" in line:
            m = BEGIN_RE.search(line)
            fingers = int(m.group(1)) if m else 0
            dx = dy = dispatched_x = 0.0

        elif "GESTURE_SWIPE_UPDATE" in line and fingers == 3:
            m = UPDATE_RE.search(line)
            if not m:
                continue
            dx += float(m.group(2))
            dy += float(m.group(3))
            while dx - dispatched_x >= PX_PER_DESKTOP:
                spawn("bspc", "desktop", "-f", "next.local")
                dispatched_x += PX_PER_DESKTOP
            while dx - dispatched_x <= -PX_PER_DESKTOP:
                spawn("bspc", "desktop", "-f", "prev.local")
                dispatched_x -= PX_PER_DESKTOP

        elif "GESTURE_SWIPE_END" in line:
            if fingers == 3 and abs(dy) > abs(dx):
                if dy < -UP_PX_THRESHOLD:
                    spawn("rofi", "-show", "window")
                elif dy > UP_PX_THRESHOLD:
                    spawn("rofi", "-show", "drun")
            fingers = 0
            dx = dy = dispatched_x = 0.0


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(0)
