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
eval "$(starship init zsh)"

# --- Zoxide (Smart CD) ---
# Smarter cd that learns your most used directories
# Usage: z <partial-directory-name>
eval "$(zoxide init zsh)"
alias cd="z"  # Replace cd with z for smart navigation

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
