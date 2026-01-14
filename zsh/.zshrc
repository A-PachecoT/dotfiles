# Homebrew setup for Apple Silicon
eval "$(/opt/homebrew/bin/brew shellenv)"

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"

# Claude CLI
export PATH="/Users/styreep/.local/bin:$PATH"

alias l="ls -la"
alias proj="cd ~/projects"
alias cl="claude --dangerously-skip-permissions"
alias cu="cursor ."
alias python="python3"
alias py="python3"
export PATH="$HOME/Library/TinyTeX/bin/universal-darwin:$PATH"

# pnpm
export PNPM_HOME="/Users/styreep/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
export PATH=$HOME/google-cloud-sdk/bin:$PATH
export LESSUTFCHARDEF="e000-e09f:w,e0a0-e0bf:p,e0c0-f8ff:w,f0001-fffff:w"

# ============================================================
# Shell Enhancements
# ============================================================

# --- Starship Prompt ---
# Beautiful, minimal, and informative prompt
function set_win_title(){
    echo -ne "\033]0; $(basename "$PWD") \007"
}
precmd_functions+=(set_win_title)

eval "$(starship init zsh)"

# Transient prompt (like Powerlevel10k)
# After command execution, replace full prompt with just the character
zle-line-init() {
    emulate -L zsh

    [[ $CONTEXT == start ]] || return 0

    while true; do
        zle .recursive-edit
        local -i ret=$?
        [[ $ret == 0 && $KEYS == $'\4' ]] || break
        [[ -o ignore_eof ]] || exit 0
    done

    local saved_prompt=$PROMPT
    local saved_rprompt=$RPROMPT
    PROMPT='$(starship module character)'
    RPROMPT=''
    zle .reset-prompt
    PROMPT=$saved_prompt
    RPROMPT=$saved_rprompt

    if (( ret )); then
        zle .send-break
    else
        zle .accept-line
    fi
    return ret
}

zle -N zle-line-init

# --- Zoxide (Smart CD) ---
# Smarter cd that learns your most used directories
# Usage: z <partial-directory-name>
eval "$(zoxide init zsh)"
# Only apply cd="z" alias in interactive shells (your terminal)
# Non-interactive shells (scripts) keep cd as normal
[[ -o interactive ]] && alias cd="z"

# --- Zsh Autosuggestions ---
# Fish-like autosuggestions based on history
# Press → (right arrow) or End to accept suggestion
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# --- Zsh Syntax Highlighting ---
# Highlights commands as you type (must be at end of .zshrc)
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# --- FZF (Fuzzy Finder) ---
# Fuzzy finder for files, command history, and more
# Ctrl+R: search command history
# Ctrl+T: search files in current directory
# Alt+C: cd into a directory
eval "$(fzf --zsh)"

# --- Eza (Better ls) ---
# Modern replacement for ls with colors and icons
alias ls="eza --icons --git"
alias ll="eza --icons --git -l"
alias la="eza --icons --git -la"
alias lt="eza --icons --git --tree --level=2"

# --- Bat (Better cat) ---
# cat with syntax highlighting and Git integration
alias cat="bat"
alias catn="bat --style=plain"  # cat without line numbers/git gutter

# Added by Antigravity
export PATH="/Users/styreep/.antigravity/antigravity/bin:$PATH"

# bun completions
[ -s "/Users/styreep/.bun/_bun" ] && source "/Users/styreep/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Android SDK
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin

# ============================================================
# tmux - Power User Terminal Multiplexer
# ============================================================

alias tm="tmux"
alias tma="tmux attach -t"
alias tml="tmux list-sessions"
alias tmk="tmux kill-session -t"
alias tmka="tmux kill-server"

# Resume project session
# Usage: tr [path]
tr() {
    local project_path="${1:-$PWD}"
    local session_name="$(basename $project_path)"

    cd "$project_path" || return 1

    if tmux has-session -t "$session_name" 2>/dev/null; then
        tmux attach -t "$session_name"
    else
        echo "No session '$session_name'. Use 'tn' to create new."
    fi
}

# New project with dev layout
# Layout: Left (60%): Editor top + Console bottom | Right (40%): Claude Code
# Usage: tn [path]
tn() {
    local project_path="${1:-$PWD}"
    local session_name="$(basename $project_path)"

    cd "$project_path" || return 1

    # Kill existing session if any
    tmux kill-session -t "$session_name" 2>/dev/null

    # Create session with left pane (60%)
    tmux new-session -d -s "$session_name" -c "$project_path"

    # Split right for Claude Code (40%)
    tmux split-window -h -t "$session_name" -c "$project_path" -p 40

    # Split left pane vertically (editor top 80%, console bottom 20%)
    tmux select-pane -t "$session_name":1.1
    tmux split-window -v -t "$session_name" -c "$project_path" -p 20

    # Start Claude Code in right pane
    tmux send-keys -t "$session_name":1.3 "claude" Enter

    # Start yazi in top-left pane
    tmux send-keys -t "$session_name":1.1 "yazi" Enter

    # Focus on Claude Code pane
    tmux select-pane -t "$session_name":1.3

    tmux attach -t "$session_name"
}

# Project picker with fzf
tp() {
    local project=$(find ~/projects ~/cofoundy/projects -maxdepth 2 -type d -name ".git" 2>/dev/null | sed 's/\/.git$//' | fzf --prompt="Project: ")
    [[ -n "$project" ]] && tr "$project"
}

# New project picker with fzf
tnp() {
    local project=$(find ~/projects ~/cofoundy/projects -maxdepth 2 -type d -name ".git" 2>/dev/null | sed 's/\/.git$//' | fzf --prompt="New Project: ")
    [[ -n "$project" ]] && tn "$project"
}
