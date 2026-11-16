#!/usr/bin/env bash
# Reveal a file in the system file manager (portable).
# macOS: Finder. Linux seen from the Mac (Herdr app / ssh): a copy in the Mac's Finder
# (mac-bridge-open). Linux with a local GUI: dolphin/nautilus/thunar; else no-op.
target="$1"
[[ -z "$target" ]] && exit 0

if command -v open >/dev/null 2>&1; then
    open -R "$target"
elif [[ -n "${HC_TERMINAL_ID:-}${SSH_CONNECTION:-}" && -f "$target" ]] \
    && "$HOME/dotfiles/scripts/mac-bridge-open" reveal "$target" 2>/dev/null; then
    :  # Arch seen from the Mac (Herdr app / ssh): reveal a copy in the Mac's Finder
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
