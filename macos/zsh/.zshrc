# Homebrew setup for Apple Silicon
eval "$(/opt/homebrew/bin/brew shellenv)"

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"

# Rust/Cargo
export PATH="$HOME/.cargo/bin:$PATH"

# Machine-local secrets and overrides (not in git)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Default editor (neovim with LazyVim)
export EDITOR="nvim"
export VISUAL="nvim"

# Claude CLI
export PATH="$HOME/.local/bin:$PATH"

# Note: tmux auto-attach handled by dev-startup.sh (AeroSpace startup)

alias l="ls -la"
alias proj="cd ~/projects"
alias cu="cursor ."  # cl moved to shared/zsh/tmux-workflow.zsh
alias python="python3"
alias py="python3"
alias vim="nvim"
alias vi="nvim"
alias nv="nvim"
export PATH="$HOME/Library/TinyTeX/bin/universal-darwin:$PATH"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
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

# --- Yazi (File Manager) ---
# y() moved to shared/zsh/tmux-workflow.zsh (sourced below)

# Added by Antigravity
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

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
# pdf - Open PDF in floating Ghostty window (bypasses tmux for tdf)
# ============================================================
pdf() {
    [[ -z "$1" ]] && { echo "uso: pdf <archivo.pdf>"; return 1; }
    [[ ! -f "$1" ]] && { echo "no existe: $1"; return 1; }
    open -na Ghostty --args --title="pdf-viewer" -e tdf "$(realpath "$1")"
}

# ============================================================
# tmux - Power User Terminal Multiplexer
# ============================================================
# Architecture:
#   - AeroSpace workspace = Company (cofoundy, bilio, personal, notes)
#   - tmux session = Company (one per workspace)
#   - tmux window = Project (switch with Cmd+1-9)
#   - Dev layout = yazi + console + claude
#
# cl, y, tm, tw, ts, tp, th live in the PORTABLE workflow file (shared by Linux):
source "$HOME/dotfiles/shared/zsh/tmux-workflow.zsh"

# Vi mode for the command line (Esc -> NORMAL). Shared with Linux.
source "$HOME/dotfiles/shared/zsh/vi-mode.zsh"
export PATH="$(brew --prefix)/opt/openjdk@25/bin:$PATH"

# Added by Antigravity
export PATH="/Users/styreep/.antigravity/antigravity/bin:$PATH"

# AWS SSO quick login (Cofoundy founders) — added 2026-05-20
alias aws-login='aws sso login --sso-session cofoundy'

# Codex CLI
alias co=codex
