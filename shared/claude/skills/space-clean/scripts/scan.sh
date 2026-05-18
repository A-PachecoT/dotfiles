#!/usr/bin/env bash
# scan.sh — read-only disk diagnostic. Outputs structured buckets so Claude
# can present them to the user one at a time.

set -uo pipefail

hr() { echo ""; echo "== $1 =="; }

# Disk overview
hr "DISK"
df -h / | awk 'NR==1 || NR==2'

# Top Application Support (>500M)
hr "APP SUPPORT (>500M)"
du -sh ~/Library/Application\ Support/* 2>/dev/null \
    | awk '$1 ~ /[0-9]+(\.[0-9]+)?(G|M)$/ {
        unit=substr($1,length($1)); val=substr($1,1,length($1)-1)+0;
        mb = (unit=="G") ? val*1024 : val;
        if (mb >= 500) print
    }' | sort -hr

# Top Caches (>500M, excluding ones auto-cleaned)
hr "CACHES (>500M, not auto-cleaned)"
du -sh ~/Library/Caches/* 2>/dev/null \
    | grep -vE "com.spotify.client|ms-playwright|^[^/]*/pip$|go-build|/Google$|camoufox|Homebrew" \
    | awk '$1 ~ /[0-9]+(\.[0-9]+)?(G|M)$/ {
        unit=substr($1,length($1)); val=substr($1,1,length($1)-1)+0;
        mb = (unit=="G") ? val*1024 : val;
        if (mb >= 500) print
    }' | sort -hr

# Containers / Group Containers (>500M) — flag WhatsApp/Docker specially
hr "CONTAINERS / GROUP CONTAINERS (>500M)"
{
    du -sh ~/Library/Containers/* 2>/dev/null
    du -sh ~/Library/Group\ Containers/* 2>/dev/null
} | awk '$1 ~ /[0-9]+(\.[0-9]+)?(G|M)$/ {
        unit=substr($1,length($1)); val=substr($1,1,length($1)-1)+0;
        mb = (unit=="G") ? val*1024 : val;
        if (mb >= 500) print
    }' | sort -hr | while IFS= read -r line; do
        case "$line" in
            *WhatsApp*) echo "  $line  ← in-app cleanup only (Settings → Storage and Data)" ;;
            *com.docker.docker*) echo "  $line  ← Docker Desktop → Troubleshoot → Clean / Purge data" ;;
            *) echo "  $line" ;;
        esac
    done

# Package manager caches (regenerable but slow rebuild)
hr "PACKAGE MANAGER CACHES (regenerable, slow rebuild)"
for d in ~/.cache/huggingface ~/.cache/pre-commit ~/.bun ~/.cargo/registry \
         ~/Library/pnpm ~/.rustup ~/.cache/prisma; do
    [[ -d "$d" ]] || continue
    sz=$(du -sh "$d" 2>/dev/null | awk '{print $1}')
    [[ -n "$sz" ]] && echo "  $sz  $d"
done | sort -hr

# Downloads — grouped
hr "DOWNLOADS — grouped"
cd ~/Downloads 2>/dev/null || { echo "(no Downloads dir)"; exit 0; }

count_size() {
    local pattern="$1"
    local n s
    n=$(eval "ls -1 $pattern 2>/dev/null | wc -l" | tr -d ' ')
    s=$(eval "du -sk $pattern 2>/dev/null" | awk '{sum+=$1} END {printf "%.1f MB", sum/1024}')
    echo "$n files, $s"
}

echo "  installers (.dmg/.pkg):     $(count_size '*.dmg *.pkg')"
echo "  tool screenshots (ISO ts):  $(count_size '*_20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]T*.png')"
echo "  whatsapp media:             $(count_size 'WhatsApp*')"
echo "  audio/video sueltos:        $(count_size '*.m4a *.wav *.mp3 *.mov')"
echo "  archives:                   $(count_size '*.zip *.rar *.tar.gz *.7z')"
echo "  pdfs (all):                 $(count_size '*.pdf')"
echo ""
echo "  Top 15 individual files by size:"
stat -f "%z %Sm %N" -t "%Y-%m-%d" * 2>/dev/null \
    | sort -k1 -n -r \
    | head -15 \
    | awk '{
        size=$1; date=$2; $1=""; $2="";
        sub(/^  /,"");
        if (size > 1073741824) printf "    %.1fG  %s  %s\n", size/1073741824, date, $0;
        else if (size > 1048576) printf "    %dM   %s  %s\n", size/1048576, date, $0
    }'
cd - > /dev/null

# /tmp folders < 7 days (potentially active)
hr "/private/tmp FOLDERS <7 DAYS"
while IFS= read -r path; do
    base=$(basename "$path")
    case "$base" in
        tmux-*|.X*-lock|com.apple.*|launchd-*|powerlog|claude-501) continue ;;
    esac
    sz=$(du -sh "$path" 2>/dev/null | awk '{print $1}')
    mtime=$(stat -f "%Sm" -t "%Y-%m-%d" "$path" 2>/dev/null)
    echo "  $sz  $mtime  $base"
done < <(find /private/tmp -maxdepth 1 -mindepth 1 -mtime -7 2>/dev/null) | sort -hr

# Xcode / iOS simulators
hr "XCODE / IOS SIMULATORS"
if command -v xcrun &>/dev/null; then
    unavailable=$(xcrun simctl list devices 2>/dev/null | grep -c "unavailable" || echo 0)
    echo "  unavailable simulators: $unavailable (run 'xcrun simctl delete unavailable' to remove)"
    dd_size=$(du -sh ~/Library/Developer/Xcode/DerivedData 2>/dev/null | awk '{print $1}')
    [[ -n "$dd_size" ]] && echo "  DerivedData: $dd_size"
    archives_size=$(du -sh ~/Library/Developer/Xcode/Archives 2>/dev/null | awk '{print $1}')
    [[ -n "$archives_size" ]] && echo "  Archives:    $archives_size"
    sim_size=$(du -sh ~/Library/Developer/CoreSimulator 2>/dev/null | awk '{print $1}')
    [[ -n "$sim_size" ]] && echo "  CoreSimulator: $sim_size"
else
    echo "  (xcrun not installed)"
fi

# Docker / colima
hr "DOCKER / COLIMA"
if command -v docker &>/dev/null && docker info &>/dev/null; then
    docker system df 2>/dev/null | sed 's/^/  /'
else
    echo "  (docker daemon not running)"
fi
colima_size=$(du -sh ~/.colima 2>/dev/null | awk '{print $1}')
[[ -n "$colima_size" ]] && echo "  ~/.colima: $colima_size"

echo ""
echo "=== scan complete ==="
