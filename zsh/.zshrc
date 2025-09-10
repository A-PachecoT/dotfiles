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
