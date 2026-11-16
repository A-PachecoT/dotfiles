#!/usr/bin/env bash
# Quick Look preview (portable). macOS: native Quick Look with auto-focus.
# Linux seen from the Mac (Herdr app / ssh): Quick Look on the Mac via mac-bridge-open.
# Linux with a local GUI: the default viewer; otherwise images full-pane
# via the Kitty graphics viewer of imgview.yazi.
file="$1"
[[ -z "$file" ]] && exit 0

if command -v qlmanage >/dev/null 2>&1; then
    qlmanage -p "$file" &>/dev/null &
    PID=$!
    sleep 0.05
    osascript -e 'tell application "System Events" to set frontmost of process "qlmanage" to true' 2>/dev/null
    wait $PID
elif [[ -n "${HC_TERMINAL_ID:-}${SSH_CONNECTION:-}" && -f "$file" ]] \
    && "$HOME/dotfiles/scripts/mac-bridge-open" quicklook "$file" 2>/dev/null; then
    :  # Arch seen from the Mac (Herdr app / ssh): its WAYLAND_DISPLAY is a screen nobody watches
elif [[ -n "$WAYLAND_DISPLAY$DISPLAY" ]] && command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$file" >/dev/null 2>&1 &
elif [[ "$(file -b --mime-type -- "$file")" == image/* ]]; then
    exec python3 "$HOME/dotfiles/shared/yazi/.config/yazi/plugins/imgview.yazi/view.py" "$file"
fi
