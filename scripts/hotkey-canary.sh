#!/usr/bin/env bash
# Detect the exact moment Option+<char> global hotkeys stop dispatching,
# and capture what happened in the minutes before.
#
# Mechanism: bind ⌥P in Hammerspoon, post a synthetic Option+P every cycle,
# check whether the handler ran. When it stops running, dump forensics.
#
# Usage: scripts/hotkey-canary.sh [interval_seconds]
set -uo pipefail

INTERVAL="${1:-60}"
CANARY=/tmp/canary.log
OUT="$HOME/hotkey-forensics-$(date +%Y%m%d-%H%M%S).txt"

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

arm_canary() {
  hs -c '_canary = hs.hotkey.bind({"alt"}, "p", function()
    local f = io.open("/tmp/canary.log", "a"); f:write("FIRED\n"); f:close() end)
    return "ok"' >/dev/null 2>&1
}

forensics() {
  {
    echo "════ HOTKEY DEATH DETECTED: $(date '+%F %T') ════"
    echo
    echo "── AeroSpace"
    ps -o pid,lstart,etime,comm -p "$(pgrep -x AeroSpace)" 2>/dev/null
    echo "  focused ws: $(aerospace list-workspaces --focused 2>&1)"
    echo "  monitors:";  aerospace list-monitors 2>&1 | sed 's/^/    /'
    echo
    echo "── Secure Input"
    echo "  enabled: $(secure_input)   holder pid: $(si_holder)"
    ps -p "$(si_holder)" -o comm= 2>/dev/null || echo "  (holder is DEAD -> orphaned)"
    echo
    echo "── frontmost app"
    osascript -e 'tell application "System Events" to get name of first process whose frontmost is true' 2>/dev/null
    echo
    echo "── displays"
    system_profiler SPDisplaysDataType 2>/dev/null | grep -E "^ {8}[A-Za-z].*:|Online|Resolution"
    echo
    echo "── USB / HID events (last 10 min)"
    /usr/bin/log show --last 10m --predicate \
      'eventMessage CONTAINS "Dongle" OR eventMessage CONTAINS "IOHIDInterface" OR eventMessage CONTAINS "USBHostPort"' \
      2>/dev/null | tail -25
    echo
    echo "── display / power events (last 10 min)"
    /usr/bin/log show --last 10m --predicate \
      'process == "powerd" OR eventMessage CONTAINS "CGDisplay"' 2>/dev/null | tail -15
    echo
    echo "── processes started in the last 10 min"
    ps -axo pid=,lstart=,comm= | while read -r line; do
      ts=$(echo "$line" | awk '{print $2,$3,$4,$5,$6}')
      st=$(date -j -f "%a %b %d %T %Y" "$ts" +%s 2>/dev/null) || continue
      [ $(( $(date +%s) - st )) -lt 600 ] && echo "  $line"
    done
    echo
    echo "── Karabiner (last 10 lines today)"
    grep -h "$(date +%Y-%m-%d)" /var/log/karabiner/*.log 2>/dev/null | tail -10
  } >>"$OUT" 2>&1
}

echo "canary running — interval ${INTERVAL}s"
echo "forensics will be written to: $OUT"
arm_canary

while true; do
  : >"$CANARY"
  arm_canary
  post_option_p
  sleep 1
  if [ ! -s "$CANARY" ]; then
    echo "[$(date +%T)] ⌥P did NOT fire — capturing forensics"
    forensics
    echo "[$(date +%T)] wrote $OUT"
    exit 0
  fi
  echo "[$(date +%T)] ok"
  sleep "$INTERVAL"
done
