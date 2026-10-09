#!/usr/bin/env bash
# Quick Look preview (portable). macOS: native Quick Look with auto-focus.
# Linux: fall back to the default GUI viewer; headless (ssh/ET + herdr) shows
# images full-pane via the Kitty graphics viewer of imgview.yazi.
file="$1"
[[ -z "$file" ]] && exit 0

if command -v qlmanage >/dev/null 2>&1; then
    qlmanage -p "$file" &>/dev/null &
    PID=$!
    sleep 0.05
    osascript -e 'tell application "System Events" to set frontmost of process "qlmanage" to true' 2>/dev/null
    wait $PID
elif [[ -n "$WAYLAND_DISPLAY$DISPLAY" ]] && command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$file" >/dev/null 2>&1 &
elif [[ "$(file -b --mime-type -- "$file")" == image/* ]]; then
    exec python3 "$HOME/dotfiles/shared/yazi/.config/yazi/plugins/imgview.yazi/view.py" "$file"
fi
