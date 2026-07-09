#!/usr/bin/env bash
# Catch the exact moment Option+<char> global hotkey dispatch dies.
#
# Built while chasing 2026-07-09's bug, whose cause turned out to be a hidden
# password field (Obsidian's git prompt) holding keyboard first-responder: it
# swallowed Option+<char> as *text* while Option+Tab and Ctrl+<char>, which
# produce no character, still reached the hotkey layer. Restarting AeroSpace
# "fixed" it only because that stole focus back from the panel.
#
# The instrument stays useful for any recurrence: a text field anywhere can
# silently eat character-producing hotkeys with no error and no log.
#
# How it works:
#   - A synthetic CGEventPost of Option+P triggers a Carbon hotkey, so the
#     check needs no human at the keyboard.
#   - Binds ONCE. Rebinding each cycle races Hammerspoon's GC and produces a
#     false positive (learned the hard way -- it reported a death that wasn't).
#
# Polls every INTERVAL seconds and, on death, dumps a tight window of system
# activity. When it fires, suspect a focused text field before suspecting a
# hotkey conflict: check `IsSecureEventInputEnabled()` and the frontmost app's
# open panels/dialogs.
#
# Usage: scripts/hotkey-canary.sh [interval_seconds]
set -uo pipefail

INTERVAL="${1:-10}"
CANARY=/tmp/canary.log
OUT="$HOME/hotkey-forensics-$(date +%Y%m%d-%H%M%S).txt"
SNAP=/tmp/canary-procs.snapshot

post_option_p() {
  python3 - <<'PY' 2>/dev/null
import ctypes, ctypes.util, time
q = ctypes.cdll.LoadLibrary(ctypes.util.find_library("ApplicationServices"))
q.CGEventCreateKeyboardEvent.restype = ctypes.c_void_p
q.CGEventCreateKeyboardEvent.argtypes = [ctypes.c_void_p, ctypes.c_uint16, ctypes.c_bool]
q.CGEventSetFlags.argtypes = [ctypes.c_void_p, ctypes.c_uint64]
q.CGEventPost.argtypes = [ctypes.c_uint32, ctypes.c_void_p]
for down in (True, False):
    e = q.CGEventCreateKeyboardEvent(None, 35, down)  # kVK_ANSI_P
    q.CGEventSetFlags(e, 0x00080000)                  # Option
    q.CGEventPost(0, e)
    time.sleep(0.06)
PY
}

secure_input() {
  python3 -c "
import ctypes, ctypes.util
c = ctypes.cdll.LoadLibrary(ctypes.util.find_library('Carbon'))
c.IsSecureEventInputEnabled.restype = ctypes.c_bool
print(c.IsSecureEventInputEnabled())" 2>/dev/null
}

si_holder() {
  ioreg -l -w 0 2>/dev/null |
    sed -n 's/.*"kCGSSessionSecureInputPID"=\([0-9]*\).*/\1/p' | head -1
}

hotkey_mode() {
  python3 -c "
import ctypes
SL = ctypes.cdll.LoadLibrary('/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight')
SL.SLSMainConnectionID.restype = ctypes.c_int
m = ctypes.c_int(-1)
SL.SLSGetGlobalHotKeyOperatingMode.argtypes = [ctypes.c_int, ctypes.POINTER(ctypes.c_int)]
SL.SLSGetGlobalHotKeyOperatingMode(SL.SLSMainConnectionID(), ctypes.byref(m))
print(m.value)" 2>/dev/null
}

# Bind exactly once. Rebinding races Hammerspoon's GC.
hs -c '_canary = hs.hotkey.bind({"alt"}, "p", function()
  local f = io.open("/tmp/canary.log", "a"); f:write("FIRED\n"); f:close() end)
  return "armed"' >/dev/null 2>&1

: >"$CANARY"
post_option_p; sleep 1
if [ ! -s "$CANARY" ]; then
  echo "REFUSING TO START: hotkey dispatch is already broken."
  echo "Restart AeroSpace first (killall AeroSpace && open -a AeroSpace)."
  exit 1
fi
echo "canary armed and healthy — polling every ${INTERVAL}s"
echo "forensics -> $OUT"
ps -axo pid=,comm= >"$SNAP"

DEATH=""
while true; do
  sleep "$INTERVAL"
  : >"$CANARY"
  post_option_p
  sleep 1
  if [ ! -s "$CANARY" ]; then
    DEATH="$(date '+%Y-%m-%d %H:%M:%S')"
    break
  fi
  echo "[$(date +%T)] ok   (secureInput=$(secure_input) holder=$(si_holder))"
  ps -axo pid=,comm= >"$SNAP"
done

WIN_START=$(date -j -v-40S -f "%Y-%m-%d %H:%M:%S" "$DEATH" "+%Y-%m-%d %H:%M:%S")
echo "[$DEATH] ⌥P DIED — dumping window from $WIN_START"

{
  echo "════ Option+char hotkey dispatch DIED at $DEATH ════"
  echo "window analysed: $WIN_START .. $DEATH"
  echo
  echo "── invariants at death"
  echo "  globalHotKeyOperatingMode : $(hotkey_mode)   (0=enabled)"
  echo "  secureInput               : $(secure_input)  holder=$(si_holder)"
  echo "  secureInput holder proc   : $(ps -p "$(si_holder)" -o comm= 2>/dev/null || echo 'DEAD (orphaned)')"
  echo "  AeroSpace                 : $(ps -o pid=,etime= -p "$(pgrep -x AeroSpace)" 2>/dev/null || echo 'not running')"
  echo "  frontmost                 : $(osascript -e 'tell application "System Events" to get name of first process whose frontmost is true' 2>/dev/null)"
  echo "  input source              : $(defaults read com.apple.HIToolbox AppleCurrentKeyboardLayoutInputSourceID 2>/dev/null)"
  echo
  echo "── processes that appeared since last healthy poll"
  comm -13 <(sort "$SNAP") <(ps -axo pid=,comm= | sort) | head -30
  echo
  echo "── processes that DISAPPEARED since last healthy poll"
  comm -23 <(sort "$SNAP") <(ps -axo pid=,comm= | sort) | head -30
  echo
  echo "── WindowServer / hidd / loginwindow / TSM in the window"
  /usr/bin/log show --start "$WIN_START" --end "$DEATH" --predicate \
    'process == "WindowServer" OR process == "hidd" OR process == "loginwindow" OR eventMessage CONTAINS "InputSource" OR eventMessage CONTAINS "SecureInput" OR eventMessage CONTAINS "HotKey"' \
    2>/dev/null | grep -viE "TCCAccessRequest|libxpc.dylib|ASEProcessing|FuseBoard" | head -40
  echo
  echo "── USB / HID / display in the window"
  /usr/bin/log show --start "$WIN_START" --end "$DEATH" --predicate \
    'eventMessage CONTAINS "Dongle" OR eventMessage CONTAINS "IOHID" OR eventMessage CONTAINS "USBHostPort" OR eventMessage CONTAINS "CGDisplay" OR process == "powerd"' \
    2>/dev/null | head -25
} >"$OUT" 2>&1

echo "wrote $OUT"
