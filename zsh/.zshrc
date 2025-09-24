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
