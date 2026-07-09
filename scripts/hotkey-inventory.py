#!/usr/bin/env python3
"""Inventory of global hotkeys on this Mac, from every readable source.

macOS forbids enumerating another app's Carbon hotkeys (SLSGetHotKey returns
kCGErrorInvalidConnection=1002 cross-connection), so this reconstructs the map
from configuration instead: system symbolic hotkeys + per-app config files.

Reports conflicts: the same combo claimed by two owners. Whoever registers
last silently wins; the other's hotkey dies with no error.
"""
import os, plistlib, re, subprocess, sys
from collections import defaultdict

HOME = os.path.expanduser("~")

# --- macOS symbolic hotkey IDs -> human names (the ones that matter) ---
SYMBOLIC = {
    7: "Move focus to menu bar", 8: "Move focus to Dock",
    9: "Move focus to active window", 10: "Move focus to window toolbar",
    11: "Move focus to floating window", 12: "Turn keyboard access on/off",
    15: "Turn zoom on/off", 17: "Zoom in", 19: "Zoom out",
    27: "Invert colors", 28: "Screenshot to file", 29: "Screenshot to clipboard",
    30: "Screenshot selection to file", 31: "Screenshot selection to clipboard",
    32: "Mission Control", 33: "Application windows",
    36: "Show Desktop", 37: "Show Dashboard",
    51: "Mute", 52: "Volume down", 53: "Volume up",
    57: "Move focus to Dock (next)", 59: "Select next input source",
    60: "Select previous input source", 61: "Select next source in Input menu",
    64: "Spotlight search", 65: "Spotlight Finder window",
    79: "Move left a space", 80: "Move left a space (alt)",
    81: "Move right a space", 82: "Move right a space (alt)",
    98: "Show Help menu", 118: "Switch to Desktop 1",
    119: "Switch to Desktop 2", 120: "Switch to Desktop 3",
    160: "Show Launchpad", 162: "Show Notification Center",
    163: "Show Quick Note", 164: "Toggle Do Not Disturb",
    175: "Show Dictation", 179: "Turn Focus on/off",
    184: "Show Character Viewer", 190: "Screenshot options",
    222: "Show Spotlight", 224: "Show Siri",
}

VK = {0:"a",1:"s",2:"d",3:"f",4:"h",5:"g",6:"z",7:"x",8:"c",9:"v",11:"b",
 12:"q",13:"w",14:"e",15:"r",16:"y",17:"t",18:"1",19:"2",20:"3",21:"4",
 22:"6",23:"5",24:"=",25:"9",26:"7",27:"-",28:"8",29:"0",30:"]",31:"o",
 32:"u",33:"[",34:"i",35:"p",36:"return",37:"l",38:"j",39:"'",40:"k",
 41:";",42:"\\",43:",",44:"/",45:"n",46:"m",47:".",48:"tab",49:"space",
 50:"`",51:"delete",53:"escape",96:"f5",97:"f6",98:"f7",99:"f3",100:"f8",
 101:"f9",103:"f11",105:"f13",107:"f14",109:"f10",111:"f12",113:"f15",
 114:"help",115:"home",116:"pgup",117:"fwddel",118:"f4",119:"end",120:"f2",
 121:"pgdn",122:"f1",123:"left",124:"right",125:"down",126:"up"}


def norm(mods, key):
    """Canonical 'alt+shift+2' form so owners can be compared."""
    order = ["ctrl", "alt", "shift", "cmd"]
    m = sorted({x for x in mods if x in order}, key=order.index)
    return "+".join(m + [key.lower()])


def sym_mods(bits):
    out = []
    if bits & 0x40000: out.append("ctrl")
    if bits & 0x80000: out.append("alt")
    if bits & 0x20000: out.append("shift")
    if bits & 0x100000: out.append("cmd")
    return out


claims = defaultdict(list)   # combo -> [owner, ...]


def add(combo, owner):
    if owner not in claims[combo]:
        claims[combo].append(owner)


# ---------- 1. macOS system shortcuts ----------
def load_symbolic():
    p = f"{HOME}/Library/Preferences/com.apple.symbolichotkeys.plist"
    try:
        xml = subprocess.run(["plutil", "-convert", "xml1", "-o", "-", p],
                             capture_output=True).stdout
        d = plistlib.loads(xml)
    except Exception:
        return
    for k, v in d.get("AppleSymbolicHotKeys", {}).items():
        if not v.get("enabled"):
            continue
        try:
            params = v["value"]["parameters"]
            vk, bits = params[1], params[2]
        except Exception:
            continue
        if vk == 65535:
            continue
        key = VK.get(vk, f"vk{vk}")
        name = SYMBOLIC.get(int(k), f"system #{k}")
        add(norm(sym_mods(bits), key), f"macOS: {name}")


# ---------- 2. AeroSpace ----------
def load_aerospace():
    p = f"{HOME}/.aerospace.toml"
    if not os.path.exists(p):
        return
    mode = None
    for line in open(p):
        s = line.strip()
        m = re.match(r"\[mode\.(\w+)\.binding\]", s)
        if m:
            mode = m.group(1); continue
        m = re.match(r"^([a-z0-9\-]+)\s*=", s)
        if m and mode == "main" and "-" in m.group(1):
            parts = m.group(1).split("-")
            key, mods = parts[-1], parts[:-1]
            add(norm(mods, key), "AeroSpace")


# ---------- 3. Hammerspoon ----------
def load_hammerspoon():
    d = f"{HOME}/.hammerspoon"
    if not os.path.isdir(d):
        return
    pat = re.compile(r'hs\.hotkey\.bind\(\s*\{([^}]*)\}\s*,\s*"([^"]+)"')
    for root, _, files in os.walk(d):
        for f in files:
            if not f.endswith(".lua"):
                continue
            try:
                txt = open(os.path.join(root, f), errors="ignore").read()
            except Exception:
                continue
            for mods, key in pat.findall(txt):
                ms = re.findall(r'"(\w+)"', mods)
                add(norm(ms, key), f"Hammerspoon ({f})")


# ---------- 4. Raycast ----------
def load_raycast():
    try:
        out = subprocess.run(["defaults", "read", "com.raycast.macos"],
                             capture_output=True, text=True).stdout
    except Exception:
        return
    m = re.search(r'raycastGlobalHotkey = "([^"]+)"', out)
    if m:
        raw = m.group(1)  # e.g. "Command-49"
        parts = raw.split("-")
        try:
            key = VK.get(int(parts[-1]), parts[-1])
        except ValueError:
            key = parts[-1]
        ms = [p.lower().replace("command", "cmd").replace("option", "alt")
              for p in parts[:-1]]
        add(norm(ms, key), "Raycast (main window)")


# ---------- 5. per-app menu overrides ----------
def load_user_key_equivalents():
    p = f"{HOME}/Library/Preferences/.GlobalPreferences.plist"
    try:
        xml = subprocess.run(["plutil", "-convert", "xml1", "-o", "-", p],
                             capture_output=True).stdout
        d = plistlib.loads(xml)
    except Exception:
        return
    for menu, combo in (d.get("NSUserKeyEquivalents") or {}).items():
        add(f"raw:{combo}", f"macOS menu override: {menu}")


for fn in (load_symbolic, load_aerospace, load_hammerspoon,
           load_raycast, load_user_key_equivalents):
    try:
        fn()
    except Exception as e:
        print(f"[warn] {fn.__name__}: {e}", file=sys.stderr)

conflicts = {c: o for c, o in claims.items() if len(o) > 1}

print(f"═══ {len(claims)} hotkeys globales, {len(conflicts)} en CONFLICTO ═══\n")

if conflicts:
    print("⚠  CONFLICTOS — dos apps reclaman la misma combo.")
    print("   El último en registrar gana; el otro muere en silencio.\n")
    for combo, owners in sorted(conflicts.items()):
        print(f"  {combo:<24} {'  vs  '.join(owners)}")
    print()

by_owner = defaultdict(list)
for combo, owners in claims.items():
    for o in owners:
        by_owner[o].append(combo)

for owner in sorted(by_owner, key=lambda o: -len(by_owner[o])):
    combos = sorted(by_owner[owner])
    print(f"── {owner}  ({len(combos)})")
    for c in combos:
        mark = "  ⚠" if c in conflicts else ""
        print(f"     {c}{mark}")
