#!/usr/bin/env bash

# The prompt shows the active layout and both Shifts switch it, so the layout
# is left as is. This flag drops the misleading ", Group 2" suffix the prompt
# otherwise appends to every non-first layout.
XSECURELOCK_SHOW_LOCKS_AND_LATCHES=1 xsecurelock
