#!/usr/bin/env bash
# Bootstrap a headless Ubuntu/Debian box with the server profile.
# Usage: git clone https://github.com/A-PachecoT/dotfiles ~/dotfiles && ~/dotfiles/server/bootstrap-ubuntu.sh
#
# Package list derived from the configs it serves:
#   zsh (linux/zsh + server/zsh) → zsh zsh-autosuggestions zsh-syntax-highlighting zoxide fzf eza + powerlevel10k
#   tmux (.tmux.conf: tpm, resurrect, fingers, smart-open) → tmux git xclip
#   nvim (LazyVim) → neovim ripgrep fd-find gcc/make (treesitter) unzip curl nodejs npm
#   yazi (shared/yazi, tmux-workflow `y`/`tw`) → not in apt: GitHub release binary
#   stow jq → install.sh itself
# Idempotent. Makes zsh the login shell: cl/y/z, the prompt and the mesh aliases only exist in zsh.
set -euo pipefail
DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
info() { printf '\033[0;34m[INFO]\033[0m %s\n' "$1"; }
ok()   { printf '\033[0;32m[OK]\033[0m %s\n' "$1"; }

APT_PKGS=(
  zsh zsh-autosuggestions zsh-syntax-highlighting
  tmux neovim git curl unzip build-essential stow jq
  ripgrep fd-find fzf zoxide eza bat btop xclip
  nodejs npm python3
)
info "apt: ${APT_PKGS[*]}"
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${APT_PKGS[@]}"
ok "apt packages"

mkdir -p "$HOME/.local/bin" "$HOME/.local/share"
command -v fd  >/dev/null || ln -sfn "$(command -v fdfind)" "$HOME/.local/bin/fd"
command -v bat >/dev/null || ln -sfn "$(command -v batcat)" "$HOME/.local/bin/bat"

P10K="$HOME/.local/share/powerlevel10k"
[[ -d "$P10K/.git" ]] || git clone -q --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K"
ok "powerlevel10k"

if ! command -v yazi >/dev/null; then
  tmp=$(mktemp -d)
  curl -fsSL -o "$tmp/yazi.zip" \
    "https://github.com/sxyazi/yazi/releases/latest/download/yazi-$(uname -m)-unknown-linux-gnu.zip"
  unzip -q "$tmp/yazi.zip" -d "$tmp"
  install -m755 "$tmp"/yazi-*/yazi "$tmp"/yazi-*/ya "$HOME/.local/bin/"
  rm -rf "$tmp"
fi
ok "yazi $(yazi --version 2>/dev/null | head -1)"

[[ -d "$HOME/.tmux/plugins/tpm" ]] || git clone -q https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
ok "tpm (install plugins: prefix + I, or ~/.tmux/plugins/tpm/bin/install_plugins)"

# `ssh hq 'claude …'` runs a NON-interactive bash, and Ubuntu's ~/.bashrc returns
# before anything else is read — so ~/.local/bin (claude, uv, yazi) is off PATH.
# Put it on the first line, above that guard. Idempotent.
MARK='# dotfiles(server): ~/.local/bin for non-interactive ssh'
if ! grep -qF "$MARK" "$HOME/.bashrc" 2>/dev/null; then
  printf '%s\ncase ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac\n' "$MARK" \
    | cat - "$HOME/.bashrc" > "$HOME/.bashrc.tmp" && mv "$HOME/.bashrc.tmp" "$HOME/.bashrc"
fi
ok "~/.local/bin on PATH for non-interactive ssh"

"$DOTFILES/install.sh" server

ZSH_BIN="$(command -v zsh)"
if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$ZSH_BIN" ]]; then
  sudo chsh -s "$ZSH_BIN" "$USER"
fi
ok "login shell $ZSH_BIN (new logins; current shells keep bash until you reconnect)"
