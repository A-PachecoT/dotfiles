#!/bin/bash
# Bootstrap a fresh macOS machine with full dotfiles setup
# Usage: git clone <repo> ~/dotfiles && cd ~/dotfiles && ./bootstrap.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }
step()    { echo -e "\n${BOLD}━━━ $1 ━━━${NC}"; }

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Step 1: Xcode CLT ──────────────────────────────────────
step "1/7 Xcode Command Line Tools"
if xcode-select -p &>/dev/null; then
    success "Already installed"
else
    info "Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "Press enter after installation completes..."
    read -r
fi

# ── Step 2: Homebrew ────────────────────────────────────────
step "2/7 Homebrew"
if command -v brew &>/dev/null; then
    success "Already installed"
else
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ── Step 3: Brew packages ──────────────────────────────────
step "3/7 Brew packages (Brewfile)"
info "Installing packages, casks, and fonts..."
brew bundle install --file="$DOTFILES_DIR/Brewfile" --no-lock
success "All packages installed"

# ── Step 4: Stow symlinks ──────────────────────────────────
step "4/7 Symlinks (GNU Stow)"
cd "$DOTFILES_DIR"
./install.sh install
success "All configs symlinked"

# ── Step 5: tmux plugins ───────────────────────────────────
step "5/7 tmux plugins"
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ -d "$TPM_DIR" ]]; then
    success "TPM already installed"
else
    info "Installing TPM (Tmux Plugin Manager)..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    success "TPM installed"
fi
info "Installing tmux plugins..."
"$TPM_DIR/bin/install_plugins" || warning "Run Ctrl+b I inside tmux to install plugins"

# ── Step 6: GitHub auth + secrets ───────────────────────────
step "6/7 GitHub auth + secrets"
if gh auth status &>/dev/null; then
    success "GitHub CLI authenticated"
else
    info "Authenticating GitHub CLI..."
    gh auth login
fi

if [[ -f "$HOME/.zshrc.local" ]]; then
    success "Secrets already provisioned (~/.zshrc.local exists)"
else
    info "Fetching secrets from private repo..."
    "$DOTFILES_DIR/setup/secrets-setup.sh" || warning "Secrets setup failed — run setup/secrets-setup.sh later"
fi

# ── Step 7: Health check ───────────────────────────────────
step "7/7 Health check"

CHECKS=0
PASS=0

check() {
    CHECKS=$((CHECKS + 1))
    if command -v "$1" &>/dev/null; then
        success "$1"
        PASS=$((PASS + 1))
    else
        error "$1 not found"
    fi
}

check_file() {
    CHECKS=$((CHECKS + 1))
    if [[ -e "$1" ]]; then
        success "$2"
        PASS=$((PASS + 1))
    else
        error "$2 not found ($1)"
    fi
}

# Core tools
check aerospace
check sketchybar
check ghostty
check tmux
check nvim
check yazi

# Shell enhancements
check starship
check zoxide
check fzf
check eza
check bat

# Dev tools
check git
check gh
check node

# Symlinks
check_file "$HOME/.aerospace.toml" "aerospace symlink"
check_file "$HOME/.config/sketchybar" "sketchybar symlink"
check_file "$HOME/.config/ghostty" "ghostty symlink"
check_file "$HOME/.config/nvim" "nvim symlink"
check_file "$HOME/.tmux.conf" "tmux symlink"
check_file "$HOME/.zshrc" "zshrc symlink"
check_file "$HOME/.gitconfig" "gitconfig symlink"

# Fonts
check_file "$HOME/Library/Fonts/sketchybar-app-font.ttf" "sketchybar-app-font"

# Secrets
check_file "$HOME/.zshrc.local" "secrets (.zshrc.local)"

echo ""
if [[ $PASS -eq $CHECKS ]]; then
    success "All $CHECKS checks passed!"
else
    warning "$PASS/$CHECKS checks passed"
fi

# ── Done ────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}Bootstrap complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Restart your Mac (login items: AeroSpace, SketchyBar, HammerSpoon)"
echo "  2. Open Ghostty — tmux sessions will be created by dev-startup.sh"
echo "  3. In any tmux window: tw . → coding in 5 seconds"
echo ""
echo "Optional:"
echo "  ./install.sh jupyter   — Global Jupyter environment"
echo "  ./install.sh claude    — Claude Code notification hooks"
