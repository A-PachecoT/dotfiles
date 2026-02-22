#!/usr/bin/env python3
"""
GLOBAL PreToolUse hook - blocks CATASTROPHIC commands only.
Project-level hooks can be more strict.

Exit code 2 = block the command
Exit code 0 = allow the command
"""
import json
import sys
import re
import os

# Safe targets for rm -rf (basenames only)
RM_RF_SAFE_TARGETS = {
    "node_modules",
    "package-lock.json",
    ".cache",
    "dist",
    "build",
    ".next",
    ".astro",
    "__pycache__",
    ".turbo",
}

# Only block truly catastrophic commands
BLOCKED_PATTERNS = [
    # Root/home destruction (exact patterns, not paths starting with /)
    (r"rm\s+(-[a-zA-Z]*r[a-zA-Z]*\s+|)/$", "rm / (root deletion)"),
    (r"rm\s+(-[a-zA-Z]*r[a-zA-Z]*\s+|)/\s*$", "rm / (root deletion)"),
    (r"rm\s+-[a-zA-Z]*r[a-zA-Z]*\s+~\s*$", "rm -r ~ (home deletion)"),
    (r"rm\s+-[a-zA-Z]*r[a-zA-Z]*\s+~/\s*$", "rm -r ~/ (home deletion)"),
    (r"rm\s+-[a-zA-Z]*r[a-zA-Z]*\s+/\*", "rm -r /* (root wildcard)"),

    # Disk/system destruction
    (r"dd\s+.*of=/dev/[sh]d", "dd writing to disk device"),
    (r"dd\s+.*if=/dev/zero.*of=/dev/", "dd disk wiping"),
    (r"mkfs\s+/dev/[sh]d", "formatting disk"),
    (r">\s*/dev/[sh]d", "redirecting to disk device"),

    # Fork bomb
    (r":\(\)\s*\{\s*:\|:\s*&\s*\}", "fork bomb"),

    # System file destruction
    (r"rm\s+-[a-zA-Z]*r[a-zA-Z]*\s+/etc/?$", "rm /etc"),
    (r"rm\s+-[a-zA-Z]*r[a-zA-Z]*\s+/usr/?$", "rm /usr"),
    (r"rm\s+-[a-zA-Z]*r[a-zA-Z]*\s+/var/?$", "rm /var"),
    (r"rm\s+-[a-zA-Z]*r[a-zA-Z]*\s+/bin/?$", "rm /bin"),
]

def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    tool_name = input_data.get("tool_name", "")
    if tool_name != "Bash":
        sys.exit(0)

    command = input_data.get("tool_input", {}).get("command", "")

    for pattern, description in BLOCKED_PATTERNS:
        if re.search(pattern, command):
            print(f"", file=sys.stderr)
            print(f"{'='*50}", file=sys.stderr)
            print(f"GLOBAL SAFETY: BLOCKED", file=sys.stderr)
            print(f"Reason: {description}", file=sys.stderr)
            print(f"{'='*50}", file=sys.stderr)
            sys.exit(2)

    # Block rm -rf unless ALL targets are in the safe list
    rm_rf_match = re.findall(r"rm\s+-[a-zA-Z]*r[a-zA-Z]*f?\s+(.+?)(?:\s*&&|$|\s*;|\s*\|)", command)
    if not rm_rf_match:
        rm_rf_match = re.findall(r"rm\s+-[a-zA-Z]*f[a-zA-Z]*\s+(.+?)(?:\s*&&|$|\s*;|\s*\|)", command)
    for targets_str in rm_rf_match:
        targets = targets_str.strip().split()
        for target in targets:
            basename = os.path.basename(target.rstrip("/"))
            if basename not in RM_RF_SAFE_TARGETS:
                print(f"", file=sys.stderr)
                print(f"{'='*50}", file=sys.stderr)
                print(f"GLOBAL SAFETY: BLOCKED rm -rf", file=sys.stderr)
                print(f"Target '{basename}' not in safe list.", file=sys.stderr)
                print(f"Safe: {', '.join(sorted(RM_RF_SAFE_TARGETS))}", file=sys.stderr)
                print(f"{'='*50}", file=sys.stderr)
                sys.exit(2)

    sys.exit(0)

if __name__ == "__main__":
    main()
