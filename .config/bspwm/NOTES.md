# bspwm Multi-Monitor Window Migration Research

## Problem Statement

**Desired Behavior:**

- Laptop (eDP-1-1): desktops I-IV
- HDMI (HDMI-0): desktops V-X
- When HDMI disconnects: windows on V-X should migrate to laptop desktops V-X
- When HDMI reconnects: windows on laptop V-X should migrate to HDMI desktops V-X

**Current Status:**

- HDMI disconnect: ✓ **WORKS** - Windows properly migrate from HDMI V-X to laptop V-X
- HDMI reconnect: ✗ **BROKEN** - Windows bunch up on laptop desktop IV instead of migrating to HDMI V-X

## Environment

**Hardware:**

- eDP-1-1 (laptop): 1920x1200
- HDMI-0 (external): 3840x2160

**Desktop Assignment:**

- Single monitor mode: eDP-1-1 gets all 10 desktops (I-X)
- Dual monitor mode: eDP-1-1 gets I-IV, HDMI-0 gets V-X

**Detection Mechanism:**

- `monitor_hotplug.sh` polls xrandr every 10 seconds
- Calls `initial_setup.sh` when state change detected
- `initial_setup.sh` routes to appropriate display script

**Key Files:**

- `bspwmrc` - Initial startup configuration
- `monitor_hotplug.sh` - Polling loop for monitor state changes
- `initial_setup.sh` - Dispatcher that detects monitors and routes to display scripts
- `display_hdmi.sh` - Configures dual-monitor setup
- Backups: `*.backup` files contain previous working versions

## Experiments

### Experiment 1: Auto-relocation approach (backup version)

**Date:** Before 2025-11-30

**Hypothesis:** bspwm will automatically relocate windows when desktop assignments change

**Implementation:**

- `display_hdmi.sh.backup`: Simple desktop reassignment with no manual window migration

  ```bash
  bspc monitor eDP-1-1 -d I II III IV
  bspc monitor HDMI-0 -d V VI VII VIII IX X
  ```

**Results:**

- HDMI disconnect: ✓ Works (windows appear on laptop V-X)
- HDMI reconnect: ✗ Fails (windows bunch on laptop IV)

**Conclusion:**

- Auto-relocation is unreliable and direction-dependent
- Need manual window migration for reconnect scenario

---

### Experiment 2: Manual migration for disconnect scenario

**Date:** 2025-11-30

**Hypothesis:** Manually migrating windows from HDMI-0 to eDP-1-1 before removing monitor will preserve window placement

**Implementation:**

- Modified `initial_setup.sh` single-monitor section (lines 22-26):

  ```bash
  for desktop in V VI VII VIII IX X; do
    for win in $(bspc query -N -d HDMI-0:$desktop 2>/dev/null); do
      bspc node $win -d eDP-1-1:$desktop
    done
  done
  ```

**Results:**

- ✗ **FAILED** - Windows still orphaned
- Log analysis shows: "No windows on HDMI-0:V/VI/VII..." when migration attempted
- 7 Firefox windows exist in X11 but not managed by bspwm after disconnect

**Conclusion:**

- Code is correct but runs too late
- 10-second polling delay means HDMI physically disconnected before script runs
- Monitor already gone from bspwm when migration code executes
- Windows orphaned in the gap between physical disconnect and script detection

**Log Evidence:**

```
[2025-11-30 11:59:38.184] [INITIAL_SETUP]   No windows on HDMI-0:V
[2025-11-30 11:59:38.196] [INITIAL_SETUP]   No windows on HDMI-0:VI
...
```

---

### Experiment 3: Architecture rewrite with proper ordering

**Date:** 2025-11-30 22:55

**Hypothesis:** The core issue is operation ordering, not just timing. By ensuring target desktops exist BEFORE migrating windows, and using a reusable migration abstraction, both disconnect and reconnect should work reliably.

**Implementation:**

1. **Created `lib/migrate_windows.sh`** - Reusable migration function

   ```bash
   migrate_windows FROM_MONITOR TO_MONITOR DESKTOP1 [DESKTOP2 ...]
   ```

2. **Rewrote `display_hdmi.sh`** (reconnect scenario) with correct ordering:

   ```bash
   # Step 1: Create HDMI-0 with V-X FIRST (target exists)
   bspc monitor HDMI-0 -d V VI VII VIII IX X

   # Step 2: Migrate windows from eDP-1-1 to HDMI-0
   migrate_windows eDP-1-1 HDMI-0 V VI VII VIII IX X

   # Step 3: Shrink eDP-1-1 to I-IV LAST (V-X already empty)
   bspc monitor eDP-1-1 -d I II III IV
   ```

3. **Rewrote single-monitor section in `initial_setup.sh`** with same principle:

   ```bash
   # Step 1: Extend eDP-1-1 to I-X FIRST (target exists)
   bspc monitor eDP-1-1 -d I II III IV V VI VII VIII IX X

   # Step 2: Migrate windows
   migrate_windows HDMI-0 eDP-1-1 V VI VII VIII IX X

   # Step 3: Remove HDMI-0 LAST (already empty)
   bspc monitor HDMI-0 -r
   ```

4. **Reduced polling interval** from 10s → 2s (5x faster detection for disconnect scenario)

**Expected Results:**

- Reconnect: Should work immediately (no timing issue, HDMI already present)
- Disconnect: Should work much better (2s window instead of 10s for race condition)

**Status:** ✗ FAILED

**Test Results (2025-11-30 23:15):**

*Initial state:*

- HDMI disconnected, eDP-1-1 has all desktops I-X
- 3 windows: VS Code (I), Firefox (II), zsh terminal (X)

*After HDMI reconnect:*

- Desktop assignment: ✓ Perfect (eDP-1-1: I-IV, HDMI-0: V-X)
- Window migration: ✗ Failed
  - VS Code stayed on eDP-1-1:I ✓
  - Firefox stayed on eDP-1-1:II ✓
  - zsh terminal: **moved to eDP-1-1:I instead of HDMI-0:X** ✗

**Root Cause:**
Creating HDMI-0 with V-X while eDP-1-1 still has V-X creates **duplicate desktop names**:

- Before migration: eDP-1-1 has {I-X}, HDMI-0 has {V-X}
- Desktops V-X exist on BOTH monitors simultaneously

When duplicate desktop names exist, bspwm auto-relocates windows immediately and unpredictably. By the time migration code runs, windows are already gone from source desktops.

**Log Evidence:**

```
Step 4: Assigning desktops - HDMI-0 gets V-X FIRST
Step 6: Migrating windows from eDP-1-1:{V-X} to HDMI-0:{V-X}
  No windows on eDP-1-1:V
  No windows on eDP-1-1:VI
  ...
  No windows on eDP-1-1:X  ← Terminal was here before Step 4!
Step 8: Shrinking eDP-1-1 to I-IV
```

**Conclusion (Reconnect):**
The hypothesis was partially correct - ordering matters, but creating target desktops BEFORE migration creates duplicates which trigger unwanted auto-relocation. Need to:

1. Migrate windows FIRST (while source desktops still exist uniquely)
2. THEN reassign desktops (no duplicates)

**Disconnect Test (2025-11-30 23:25):**

*Setup before disconnect:*

- HDMI-0 connected with desktops V-X
- 4 windows: VS Code (eDP-1-1:I), Firefox (eDP-1-1:II), 2x zsh (eDP-1-1:I and HDMI-0:VI)

*After HDMI disconnect:*

- Desktop assignment: ✓ Correct (eDP-1-1: I-X)
- Window on HDMI-0:VI: **✗ ORPHANED** (exists in X11 but not in bspwm)

**Root Cause:**
Physical disconnect is instant → bspwm immediately removes HDMI-0 → window becomes orphaned BEFORE hotplug script detects the change (0-2 second gap). The migration code in initial_setup.sh runs too late - HDMI-0 monitor no longer exists in bspwm by the time it tries to migrate windows from it.

This is the classic race condition from Experiment 2, still present despite 2-second polling.

---

### Experiment 4: Testing backup/original scripts

**Date:** 2025-11-30 23:36

**Hypothesis:** The backup scripts claim to have disconnect working. Need to verify if they actually avoid the orphaning problem that Experiment 3 encountered.

**Implementation:**

- Reverted to backup versions of all scripts:
  - `initial_setup.sh.backup` → `initial_setup.sh`
  - `display_hdmi.sh.backup` → `display_hdmi.sh`
  - `monitor_hotplug.sh.backup` → `monitor_hotplug.sh`
- Current Experiment 3 versions saved as `*.current`
- Hotplug script restarted with 10-second polling (backup default)

**Key Differences from Experiment 3:**

- Backup migrates only VII-X desktops, not V-VI
- Backup runs xrandr BEFORE extending desktops (Experiment 3 runs it AFTER)
- 10-second polling vs 2-second polling

**Test Results:**

*Reconnect Test (2025-11-30 23:47):*

- Initial state: zsh on eDP-1-1:X
- After HDMI connect: ✗ **FAILED** - zsh on eDP-1-1:IV instead of HDMI-0:X

**Reconnect failure mechanism:**

```
Step 4: bspc monitor eDP-1-1 -d I II III IV  (shrinks from I-X to I-IV)
→ Window on X auto-relocated to IV (last available desktop)

Step 6: bspc monitor HDMI-0 -d V VI VII VIII IX X  (creates HDMI-0)
→ Too late, window already trapped on desktop IV
```

*Disconnect Test (2025-11-30 23:53):*

- Initial state: zsh on HDMI-0:X
- After HDMI disconnect: ✓ **SUCCESS** - zsh on eDP-1-1:X

**Disconnect success mechanism (accidental, not intentional):**

```
Step 2: bspc monitor eDP-1-1 -d I II III IV V VI VII VIII IX X
→ Creates DUPLICATE desktop names (both eDP-1-1 and HDMI-0 have X)
→ bspwm auto-relocates window from HDMI-0:X to eDP-1-1:X immediately
→ This happens BEFORE physical disconnect, avoiding orphaning race condition

Step 3: Manual migration code finds no windows (already auto-relocated)
→ The manual migration code is redundant - auto-relocation did the work
```

**Why disconnect works but reconnect fails:**

- **Disconnect:** Creates duplicate desktop names → triggers auto-relocation from HDMI-0 to eDP-1-1 → works by accident
- **Reconnect:** Shrinks eDP-1-1 first → windows auto-relocate to wrong desktop (IV) → creating HDMI-0 too late

**Conclusion:**
Backup scripts accidentally exploit bspwm's auto-relocation for disconnect (duplicate names), but get bitten by it for reconnect (shrinking first). The working disconnect mechanism is not by design - it's a side effect of duplicate desktop names.

**Status:** ✓ Disconnect working, ✗ Reconnect broken

---

### Experiment 5: Position tracking approach for reconnect

**Date:** 2025-12-01 00:00

**Hypothesis:** Instead of trying to avoid duplicate desktop names or shrinking first, record window positions BEFORE any changes, then restore them AFTER creating HDMI-0. This avoids both the duplicate name problem and the auto-relocation-to-IV problem.

**Implementation:**

Modified `display_hdmi.sh` with position tracking:

```bash
# Step 4: Record windows on V-X before any changes
declare -A window_desktop_map
for desktop in V VI VII VIII IX X; do
  for win in $(bspc query -N -d eDP-1-1:$desktop); do
    window_desktop_map[$win]=$desktop
  done
done

# Step 5: Shrink eDP-1-1 (windows auto-relocate to IV, but we don't care)
bspc monitor eDP-1-1 -d I II III IV

# Step 7: Create HDMI-0
bspc monitor HDMI-0 -d V VI VII VIII IX X

# Step 8: Restore windows to their original desktops on HDMI-0
for win in "${!window_desktop_map[@]}"; do
  bspc node $win -d HDMI-0:${window_desktop_map[$win]}
done
```

**Key Advantages:**

- No duplicate desktop names at any point (avoids unpredictable auto-relocation)
- Don't care where windows end up after shrinking (we restore them explicitly)
- Simple state management - just a map of window IDs to desktop names
- Works for any number of windows on any V-X desktops

**Test Results (2025-12-01 00:08):**

*Reconnect:* ✗ **FAILED**

- Initial state: zsh on eDP-1-1:X
- After HDMI connect: zsh on eDP-1-1:I (should be HDMI-0:X)

**Failure Analysis:**

Looking at logs (00:08:26-27):

```
Step 3: Window 0x02200007 on eDP-1-1:X ✓ (window exists on desktop X)
Step 4: Recording positions... → NO recordings made! ✗
Step 5: Shrink eDP-1-1 → window auto-relocated to eDP-1-1:I
Step 8: Restore windows → nothing to restore (map empty)
```

**Root Cause:**
The query `bspc query -N -d eDP-1-1:X` returned nothing even though window 0x02200007 was on desktop X. The recording loop found zero windows on V-X desktops, so the restoration step had nothing to restore.

**Hypothesis:**
After xrandr creates HDMI-0 physically (Step 2), bspwm might auto-detect it and modify desktop assignments before our recording step runs. Need to investigate what desktops exist on each monitor after xrandr but before our bspc commands.

**Debugging Session (2025-12-01 00:15-00:25):**

*Issue 1: Query syntax bug*

- Problem: `bspc query -N -d eDP-1-1:X` returns "Invalid descriptor"
- Root cause: Wrong syntax - monitor:desktop format not supported
- Solution: Use `bspc query -N -m eDP-1-1 -d X` instead

*Issue 2: Recording timing*

- Problem: Recording after xrandr found 0 windows even when desktop state looked correct
- Solution: Record BEFORE xrandr runs, when desktop state is stable

*Issue 3: Move command syntax bug*

- Problem: `bspc node $win -d HDMI-0:X` returns "Invalid descriptor"
- Root cause: Same syntax issue - monitor:desktop format not supported
- Solution: Use `bspc node $win -d X` (desktop names are unique across monitors)
- Manual test confirmed: Successfully moved window to HDMI-0:X using `-d X`

**Implementation (Experiment 5B):**

```bash
# Step 2: Record BEFORE xrandr (stable state)
for desktop in V VI VII VIII IX X; do
  for win in $(bspc query -N -m eDP-1-1 -d $desktop); do
    window_desktop_map[$win]=$desktop
  done
done

# Step 3: Run xrandr
# Step 5: Shrink eDP-1-1
# Step 7: Create HDMI-0

# Step 8: Restore windows
for win in "${!window_desktop_map[@]}"; do
  bspc node $win -d ${window_desktop_map[$win]}
done
```

**Test Results (2025-12-01 00:26):**

*Reconnect:* ✓ **SUCCESS**

- Initial state: zsh on eDP-1-1:X
- After HDMI connect: zsh on **HDMI-0:X** ✓

**Final working implementation:**

- Record window positions BEFORE xrandr (when desktop state is stable)
- Use correct query syntax: `bspc query -N -m eDP-1-1 -d X`
- Use correct move syntax: `bspc node $win -d X` (not `HDMI-0:X`)

**Status:** ✓ **RECONNECT WORKING** - Position tracking approach successful!

**Disconnect Test (2025-12-01):**
✓ **CONFIRMED WORKING** - Disconnect still works correctly with position tracking implementation.

---

## Root Cause Analysis (2025-12-01)

### The Three Interconnected Problems

**Problem 1: Shrink-first ordering**

```bash
# Backup approach (broken):
bspc monitor eDP-1-1 -d I II III IV        # Shrinks FIRST
bspc monitor HDMI-0 -d V VI VII VIII IX X  # Creates target SECOND
```

When eDP-1-1 shrinks from I-X to I-IV, windows on V-X have nowhere to go → bspwm auto-relocates them to desktop IV (last available). By the time HDMI-0 is created, windows are already trapped on IV.

**Problem 2: Duplicate desktop name trap**

```bash
# Experiment 3 approach (also broken):
bspc monitor HDMI-0 -d V VI VII VIII IX X    # Creates V-X on HDMI-0
# Now BOTH monitors have desktops V-X simultaneously!
migrate_windows eDP-1-1 HDMI-0 V VI VII VIII IX X
bspc monitor eDP-1-1 -d I II III IV          # Shrinks SECOND
```

Creating target desktops BEFORE shrinking seems logical, but it creates duplicate names. When V-X exists on both monitors, bspwm **immediately** auto-relocates windows unpredictably. Migration code runs too late - windows already moved.

**Problem 3: Query syntax bugs**

```bash
bspc query -N -d eDP-1-1:X     # ✗ "Invalid descriptor"
bspc query -N -m eDP-1-1 -d X  # ✓ Correct syntax

bspc node $win -d HDMI-0:X     # ✗ "Invalid descriptor"
bspc node $win -d X            # ✓ Correct (desktop names are unique)
```

### The Solution

**Position tracking** avoids all three issues:

```bash
# 1. Record BEFORE changes (stable state, no duplicates yet)
for win in $(bspc query -N -m eDP-1-1 -d X); do
  window_desktop_map[$win]=X
done

# 2. Let shrinking happen (don't care where windows go)
bspc monitor eDP-1-1 -d I II III IV

# 3. Create HDMI-0 (no duplicates now)
bspc monitor HDMI-0 -d V VI VII VIII IX X

# 4. Explicitly restore to recorded positions
bspc node $win -d X  # Goes to HDMI-0:X (only X that exists)
```

**Key insight**: Don't fight bspwm's auto-relocation. Record state, let chaos happen, then restore explicitly.

---

### Current State (2025-12-01)

**Status:** ✓ **BOTH SCENARIOS WORKING**

- HDMI reconnect: ✓ Windows correctly migrate from eDP-1-1:V-X to HDMI-0:V-X
- HDMI disconnect: ✓ Windows correctly migrate from HDMI-0:V-X to eDP-1-1:V-X

**Implementation:**

- Position tracking approach in `display_hdmi.sh`
- Records window positions before any desktop changes
- Explicitly restores windows after monitor configuration
- No reliance on bspwm's auto-relocation behavior

## Known Dead Ends

### ❌ Auto-relocation approach

- Comments in old scripts mention "Let bspwm auto-relocate windows"
- **Does NOT work** reliably for HDMI reconnect
- Windows bunch on desktop IV instead of migrating to correct HDMI desktops

### ❌ Polling-based migration for disconnect

- 10-second polling interval creates race condition
- Physical disconnect happens instantly
- Script runs 0-10 seconds later when monitor already gone
- Windows orphaned in this gap
- Cannot be fixed by improving migration code alone

### ❌ Manual window restoration after orphaning

- Attempted: `bspc node $win --to-desktop V` on orphaned windows
- **Failed** - bspwm rejects orphaned windows

## Key Insights

1. **Polling creates timing vulnerability**
   - Physical state changes instantly
   - Detection happens up to 10 seconds later
   - Migration code runs too late for disconnect events

2. **Window orphaning is permanent**
   - Once orphaned (exist in X11 but not bspwm), windows cannot be easily re-adopted
   - Reconnecting monitor doesn't restore them
   - Manual `bspc node` commands fail on orphaned windows

3. **Auto-relocation is asymmetric**
   - Disconnect: somewhat works (but windows can orphan)
   - Reconnect: broken (windows bunch on wrong desktop)

4. **Desktop assignment order matters**
   - When shrinking eDP-1-1 from I-X to I-IV, windows on V-X need to go somewhere
   - bspwm doesn't intelligently migrate them to HDMI-0:V-X
   - They default to last available desktop (IV)

## ~~Next Steps - Potential Solutions~~ (OBSOLETE - Problem Solved)

The reconnect issue was solved using position tracking (see Experiment 5 and Root Cause Analysis above).

For reference, these were the options considered before finding the solution:

- **Option A: Event-based detection** - Would help disconnect scenario but not reconnect
- **Option B: Reduce polling interval** - Band-aid, doesn't solve fundamental ordering problem
- **Option C: Pre-emptive migration** - The winning approach (position tracking)
- **Option D: Single-monitor architecture** - Too drastic, unnecessary

## Verification Commands

Check monitor and desktop status:

```bash
# List monitors
bspc query -M --names

# Check desktop assignment
bspc query -m eDP-1-1 -D --names    # Should show: I II III IV
bspc query -m HDMI-0 -D --names     # Should show: V VI VII VIII IX X

# Check window distribution
bspc query -N -m eDP-1-1
bspc query -N -m HDMI-0

# Check for orphaned windows
xdotool search --class firefox      # X11 sees them
bspc query -N | grep -c .           # bspwm may not
```

Check hotplug processes:

```bash
ps aux | grep monitor_hotplug | grep -v grep    # Should be 1-2 processes
```

View migration logs:

```bash
tail -f /tmp/bspwm_monitor.log
```

## Historical Issues (Resolved)

### Desktop assignments backwards after restart (2025-09-17)

- **Cause:** Multiple monitor_hotplug.sh processes running
- **Fix:** Kill duplicate processes, ensure only one runs

### Wrong monitor name in hotplug script (2025-09-17)

- **Cause:** Script checked for HDMI-1-0, actual monitor is HDMI-0
- **Fix:** Corrected monitor name in monitor_hotplug.sh:8

### Single monitor only got 4 desktops (2025-09-17)

- **Cause:** bspwmrc hardcoded dual-monitor setup
- **Fix:** Made bspwmrc call initial_setup.sh for dynamic detection
