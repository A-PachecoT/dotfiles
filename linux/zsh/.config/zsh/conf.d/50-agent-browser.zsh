# Shim: el contenido real vive en shared/zsh/agent-browser.zsh (lo sourcean
# también macos/zsh/.zshrc). Ver ahí el porqué del idle timeout.
[[ -f "$HOME/dotfiles/shared/zsh/agent-browser.zsh" ]] && source "$HOME/dotfiles/shared/zsh/agent-browser.zsh"
