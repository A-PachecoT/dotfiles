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
