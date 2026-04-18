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

# Only block truly catastrophic commands not covered by project-level hooks
# Note: rm -rf and git destructive ops are handled by cofoundy-toolkit PreToolUse hook
BLOCKED_PATTERNS = [
    # Disk/system destruction
    (r"dd\s+.*of=/dev/[sh]d", "dd writing to disk device"),
    (r"dd\s+.*if=/dev/zero.*of=/dev/", "dd disk wiping"),
    (r"mkfs\s+/dev/[sh]d", "formatting disk"),
    (r">\s*/dev/[sh]d", "redirecting to disk device"),

    # Fork bomb
    (r":\(\)\s*\{\s*:\|:\s*&\s*\}", "fork bomb"),
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

    sys.exit(0)

if __name__ == "__main__":
    main()
