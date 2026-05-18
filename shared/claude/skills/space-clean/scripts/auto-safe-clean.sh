#!/usr/bin/env bash
# auto-safe-clean.sh — delete only 100% regenerable items, no confirmation.
# Reports bytes freed.

set -uo pipefail

before=$(df -k / | awk 'NR==2 {print $4}')

nuke() {
    local label="$1"; shift
    local size_before size_after freed
    size_before=$(du -sk "$@" 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    rm -rf "$@" 2>/dev/null
    size_after=$(du -sk "$@" 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    freed=$((size_before - size_after))
    if [[ $freed -gt 0 ]]; then
        printf "  %-40s %6.1f MB\n" "$label" "$(echo "$freed / 1024" | bc -l)"
    fi
}

echo "=== auto-safe cleanup ==="

# IPC / launchd droppings in /private/tmp
echo "-- IPC sockets & launchd --"
nuke "zeb_def_ipc_*" /private/tmp/zeb_def_ipc_* 2>/dev/null
nuke "com.apple.launchd.*" /private/tmp/com.apple.launchd.* 2>/dev/null

# Regenerable app caches
echo "-- regenerable caches --"
nuke "Spotify cache" ~/Library/Caches/com.spotify.client/*
nuke "Playwright browsers" ~/Library/Caches/ms-playwright/*
nuke "pip cache" ~/Library/Caches/pip/*
nuke "go build cache" ~/Library/Caches/go-build/*
nuke "Google cache" ~/Library/Caches/Google/*
nuke "camoufox cache" ~/Library/Caches/camoufox/*
nuke "Homebrew downloads" ~/Library/Caches/Homebrew/downloads/*
nuke "uv cache (~/.cache/uv)" ~/.cache/uv/*
nuke "puppeteer cache" ~/.cache/puppeteer/*
nuke "npm _cacache" ~/.npm/_cacache/*
nuke "npm _npx" ~/.npm/_npx/*

# Stale /tmp work folders (>7 days, skip system files)
echo "-- /private/tmp folders >7 days --"
while IFS= read -r path; do
    base=$(basename "$path")
    case "$base" in
        tmux-*|.X*-lock|com.apple.*|launchd-*|powerlog) continue ;;
    esac
    nuke "tmp/$base" "$path"
done < <(find /private/tmp -maxdepth 1 -mindepth 1 -mtime +7 2>/dev/null)

after=$(df -k / | awk 'NR==2 {print $4}')
freed_kb=$((after - before))
freed_gb=$(echo "scale=2; $freed_kb / 1024 / 1024" | bc -l)

echo ""
echo "=== auto-safe phase freed: ${freed_gb} GB ==="
