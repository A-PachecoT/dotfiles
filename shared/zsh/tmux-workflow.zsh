# =============================================================================
# tmux + yazi dev workflow (PORTABLE — sourced by macOS .zshrc and Linux user.zsh)
# =============================================================================
# Architecture:
#   - tmux session = Company/context (cofoundy, bilio, personal, notes)
#   - tmux window  = Project (switch with Cmd+1-9 on macOS / Alt+1-9 elsewhere)
#   - Dev layout   = yazi + console + Claude Code
#
# Single source of truth for: cl, y, tw, ts, tp, th + tm aliases.
# Keep this file free of platform-specific binaries: use `tmux` (on PATH),
# not `/opt/homebrew/bin/tmux`. Platform GUI bits (pdf, open -a) stay in the
# per-platform rc files.
# -----------------------------------------------------------------------------

# cl - Claude Code launcher used by the dev layout (tw)
alias cl="claude --dangerously-skip-permissions --teammate-mode tmux"

# etc - Connect to the remote box via Eternal Terminal (et).
# et gives mosh-like roaming/reconnect BUT carries OSC52, so tmux copy reaches the
# LOCAL clipboard (mosh drops OSC52). Run from the mac. Server side: ./install.sh et
# Override target host with $ET_REMOTE.
#   etc          -> attach/create tmux session "cofoundy"
#   etc bilio    -> session "bilio"
etc() {
    local session="${1:-cofoundy}"
    et "${ET_REMOTE:-andre@andre-arch}" -c "tmux new -A -s ${session}"
}

# tm - TUI session manager (shows CPU, allows killing sessions)
alias tm="$HOME/dotfiles/scripts/tm"
alias tma="tmux attach -t"
alias tml="tmux list-sessions"
alias tmka="tmux kill-server"

# --- Yazi (File Manager) ---
# y to launch, exits into the directory you were browsing.
# --client-id enables IPC so external scripts can control yazi.
function y() {
    local tmp="$(mktemp -t yazi-cwd.XXXXXX)" cwd
    # TMUX_PANE is like "%144"; strip the % to get a numeric client id for IPC.
    local client_id="${TMUX_PANE#%}"
    yazi "$@" --cwd-file="$tmp" --client-id "${client_id:-$$}"
    if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

# th - tmux help
th() {
    echo -e "\033[1;34m━━━ tmux commands ━━━\033[0m"
    echo -e "\033[1mtm\033[0m          Session manager TUI (CPU, kill sessions)"
    echo -e "\033[1mtw .\033[0m        Setup dev layout (yazi + console + claude)"
    echo -e "\033[1mts NAME\033[0m     Switch/create session"
    echo -e "\033[1mtp\033[0m          Project picker → new window with layout"
    echo -e "\033[1mtml\033[0m         List sessions"
    echo -e "\033[1mtmka\033[0m        Kill ALL sessions"
}

# tw - Setup dev layout in CURRENT window (most used command)
# Layout: Left 60% (yazi 80% + console 20%) | Right 40% (Claude Code)
# Usage: tw [path]  or just  tw .
tw() {
    [[ -z "$TMUX" ]] && { echo "Not in tmux. Open your terminal/tmux first."; return 1; }

    local path="${1:-$PWD}"
    [[ "$path" == "." ]] && path="$PWD"
    [[ -d "$path" ]] || { echo "Invalid path"; return 1; }
    path="$(cd "$path" 2>/dev/null && /bin/pwd)"
    local name="${path##*/}"

    builtin cd "$path"
    tmux rename-window "$name"
    tmux split-window -h -c "$path" -p 60
    tmux select-pane -t 1
    tmux split-window -v -c "$path" -p 20
    tmux send-keys -t 3 "cl -c" Enter
    tmux send-keys -t 1 "y" Enter
    tmux select-pane -t 3
}

# ts - Switch to session (create if needed)
# Usage: ts          (fzf menu of sessions)
#        ts cofoundy (switch to specific session)
ts() {
    local session="$1"

    if [[ -z "$session" ]]; then
        session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --height=40% --reverse --prompt="session> ")
        [[ -z "$session" ]] && return 0
    fi

    if tmux has-session -t "$session" 2>/dev/null; then
        if [[ -n "$TMUX" ]]; then
            tmux switch-client -t "$session"
        else
            tmux attach -t "$session"
        fi
    else
        if [[ -n "$TMUX" ]]; then
            tmux new-session -d -s "$session"
            tmux switch-client -t "$session"
        else
            tmux new-session -s "$session"
        fi
    fi
}

# tp - Project picker → new window with dev layout
# Override search roots with $TP_PROJECT_ROOTS (space-separated) per machine.
tp() {
    [[ -z "$TMUX" ]] && { echo "Not in tmux. Open your terminal/tmux first."; return 1; }

    local roots=(${=TP_PROJECT_ROOTS:-~/projects ~/cofoundy/projects ~/cofoundy/packages ~/dotfiles})
    local project=$(find ${roots} -maxdepth 2 -type d -name ".git" 2>/dev/null | \
        sed 's/\/.git$//' | \
        fzf --prompt="Project: " --preview 'ls -la {}')
    [[ -n "$project" ]] && { tmux new-window -c "$project" && tw "$project"; }
}
