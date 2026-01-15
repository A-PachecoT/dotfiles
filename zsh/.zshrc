# Homebrew setup for Apple Silicon
eval "$(/opt/homebrew/bin/brew shellenv)"

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"

# Default editor (neovim with LazyVim)
export EDITOR="nvim"
export VISUAL="nvim"

# Claude CLI
export PATH="/Users/styreep/.local/bin:$PATH"

# Note: tmux auto-attach handled by dev-startup.sh (AeroSpace startup)

alias l="ls -la"
alias proj="cd ~/projects"
alias cl="claude --dangerously-skip-permissions"
alias cu="cursor ."
alias python="python3"
alias py="python3"
alias vim="nvim"
alias vi="nvim"
alias nv="nvim"
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
# Architecture:
#   - AeroSpace workspace = Company (cofoundy, bilio, personal, notes)
#   - tmux session = Company (one per workspace)
#   - tmux window = Project (switch with Cmd+1-9)
#   - Dev layout = yazi + console + claude

alias tm="tmux"
alias tma="tmux attach -t"
alias tml="tmux list-sessions"
alias tmk="tmux kill-session -t"
alias tmka="tmux kill-server"

# tw - Setup dev layout in CURRENT window (most used command)
# Layout: Left 60% (yazi 80% + console 20%) | Right 40% (Claude Code)
# Usage: tw [path]  or just  tw .
tw() {
    [[ -z "$TMUX" ]] && { echo "Not in tmux. Open Ghostty first."; return 1; }

    local path="${1:-$PWD}"
    [[ "$path" == "." ]] && path="$PWD"
    [[ -d "$path" ]] || { echo "Invalid path"; return 1; }
    path="$(cd "$path" 2>/dev/null && /bin/pwd)"
    local name="${path##*/}"

    command cd "$path"
    /opt/homebrew/bin/tmux rename-window "$name"
    /opt/homebrew/bin/tmux split-window -h -c "$path" -p 40
    /opt/homebrew/bin/tmux select-pane -t 1
    /opt/homebrew/bin/tmux split-window -v -c "$path" -p 20
    /opt/homebrew/bin/tmux send-keys -t 3 "cl -c" Enter
    /opt/homebrew/bin/tmux send-keys -t 1 "yazi" Enter
    /opt/homebrew/bin/tmux select-pane -t 3
}

# ts - Switch to session (create if needed)
# Usage: ts cofoundy  or  ts bilio  or  ts personal
ts() {
    local session="${1:-dev}"
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

# tp - Project picker → setup in current session
# Usage: tp
tp() {
    [[ -z "$TMUX" ]] && { echo "Not in tmux. Open Ghostty first."; return 1; }

    local project=$(find ~/projects ~/cofoundy/projects ~/cofoundy/packages ~/dotfiles -maxdepth 2 -type d -name ".git" 2>/dev/null | \
        sed 's/\/.git$//' | \
        fzf --prompt="Project: " --preview 'ls -la {}')
    [[ -n "$project" ]] && { tmux new-window -c "$project" && tw "$project"; }
}
