#!/usr/bin/env bash
# Reveal a file in the system file manager (portable).
# macOS: Finder. Linux (with GUI session): dolphin/nautilus/thunar --select, else
# open the containing directory. No-op when headless (e.g. accessed over mosh/ssh).
target="$1"
[[ -z "$target" ]] && exit 0

if command -v open >/dev/null 2>&1; then
    open -R "$target"
elif [[ -z "$WAYLAND_DISPLAY$DISPLAY" ]]; then
    exit 0  # headless: nothing to reveal
elif command -v dolphin >/dev/null 2>&1; then
    dolphin --select "$target" >/dev/null 2>&1 &
elif command -v nautilus >/dev/null 2>&1; then
    nautilus --select "$target" >/dev/null 2>&1 &
elif command -v thunar >/dev/null 2>&1; then
    thunar "$(dirname -- "$target")" >/dev/null 2>&1 &
elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$(dirname -- "$target")" >/dev/null 2>&1 &
fi
