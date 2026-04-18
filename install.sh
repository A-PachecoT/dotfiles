#!/usr/bin/env bash
# Platform-aware dotfiles installer (GNU Stow)
#
# Structure:
#   shared/   → installed on every platform
#   macos/    → installed on Darwin
#   linux/    → installed on Linux (including WSL)
#   windows/  → reserved (WSL uses linux/, native support TBD)
#
# Usage: ./install.sh [install|unstow|restow|list|jupyter|claude|help]

set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# ── Output helpers ──────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# ── Platform detection ──────────────────────────────────────
detect_platform() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux)
            # WSL treated as linux for now; native Windows path reserved
            echo "linux"
            ;;
        MSYS*|MINGW*|CYGWIN*)
            echo "windows/native"
            ;;
        *)
            error "Unsupported OS: $(uname -s)"
            exit 1
            ;;
    esac
}

is_wsl() {
    grep -qiE "microsoft|wsl" /proc/version 2>/dev/null
}

# ── Preflight ───────────────────────────────────────────────
require_stow() {
    if ! command -v stow &>/dev/null; then
        error "GNU Stow not installed"
        case "$(uname -s)" in
            Darwin) info "Install: brew install stow" ;;
            Linux)  info "Install: sudo pacman -S stow   (or apt/dnf equivalent)" ;;
        esac
        exit 1
    fi
}

# ── Package discovery ───────────────────────────────────────
# Lists package directories under a group (shared, macos, linux, windows/wsl).
list_packages() {
    local group=$1
    local dir="$DOTFILES/$group"
    [[ -d "$dir" ]] || return 0
    find "$dir" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | sort
}

# ── Stow operations ─────────────────────────────────────────
stow_pkg() {
    local action=$1  # --stow, --delete, --restow
    local group=$2
    local pkg=$3

    # Skip if the package dir has no stowable contents (e.g., only .gitkeep)
    local content_count
    content_count=$(find "$DOTFILES/$group/$pkg" -mindepth 1 ! -name '.gitkeep' ! -name 'README.md' ! -name '.stow-local-ignore' 2>/dev/null | wc -l)
    if [[ "$content_count" -eq 0 ]]; then
        info "Skipping $group/$pkg (empty placeholder)"
        return 0
    fi

    if stow --dir="$DOTFILES/$group" --target="$HOME" --no-folding "$action" "$pkg" 2>&1; then
        success "$action $group/$pkg"
    else
        warning "Stow conflict on $group/$pkg — resolve manually or use --adopt"
        return 1
    fi
}

for_all_packages() {
    local action=$1
    local platform
    platform=$(detect_platform)
    info "Platform: $platform$(is_wsl && echo ' (WSL)')"

    info "── shared/ ──"
    while IFS= read -r pkg; do
        stow_pkg "$action" shared "$pkg" || true
    done < <(list_packages shared)

    info "── $platform/ ──"
    while IFS= read -r pkg; do
        stow_pkg "$action" "$platform" "$pkg" || true
    done < <(list_packages "$platform")
}

install_dotfiles() { require_stow; for_all_packages --stow; success "Install complete"; }
unstow_dotfiles() { require_stow; for_all_packages --delete; success "Unstow complete"; }
restow_dotfiles() { require_stow; for_all_packages --restow; success "Restow complete"; }

list_all() {
    local platform
    platform=$(detect_platform)
    echo "Shared packages:"
    list_packages shared | sed 's/^/  /'
    echo ""
    echo "$platform packages:"
    list_packages "$platform" | sed 's/^/  /'
}

# ── Jupyter env (optional extra) ────────────────────────────
setup_jupyter() {
    info "Setting up global Jupyter environment..."
    if ! command -v uv &>/dev/null; then
        warning "uv not installed. Install: curl -LsSf https://astral.sh/uv/install.sh | sh"
        return 1
    fi

    local jupyter_env="$HOME/.jupyter-env"
    if [[ -d "$jupyter_env" ]]; then
        info "Jupyter env exists at $jupyter_env"
        read -r -p "Recreate? (y/N): " reply
        [[ "$reply" =~ ^[Yy]$ ]] || { info "Skipping"; return 0; }
        rm -rf "$jupyter_env"
    fi

    cd "$HOME" && uv venv "$jupyter_env"
    uv pip install --python "$jupyter_env/bin/python" \
        ipykernel jupyter jupyterlab \
        pandas numpy matplotlib seaborn scikit-learn
    "$jupyter_env/bin/python" -m ipykernel install --user \
        --name=jupyter-global --display-name="Python (Global Jupyter)"
    success "Jupyter ready. Activate: source ~/.jupyter-env/bin/activate"
}

# ── Claude Code hooks ───────────────────────────────────────
setup_claude_hooks() {
    info "Setting up Claude Code hooks..."

    local template="$DOTFILES/shared/claude/settings.template.json"
    local claude_dir="$HOME/.claude"
    local settings="$claude_dir/settings.json"

    if [[ ! -f "$template" ]]; then
        error "Template not found: $template"
        return 1
    fi

    mkdir -p "$claude_dir" "$HOME/.claude-pending"

    # Substitute __DOTFILES__ placeholder with actual absolute path
    local hooks_config
    hooks_config=$(sed "s|__DOTFILES__|$DOTFILES|g" "$template")

    if [[ -f "$settings" ]]; then
        info "Merging hooks into existing settings.json..."
        if command -v jq &>/dev/null; then
            local new_hooks
            new_hooks=$(echo "$hooks_config" | jq '.hooks')
            jq --argjson hooks "$new_hooks" '.hooks = $hooks' "$settings" > "$settings.tmp"
            mv "$settings.tmp" "$settings"
            success "Hooks merged"
        else
            warning "jq missing — using python fallback"
            cp "$settings" "$settings.backup"
            python3 <<EOF
import json
with open("$settings") as f: existing = json.load(f)
existing["hooks"] = json.loads('''$hooks_config''')["hooks"]
with open("$settings", "w") as f: json.dump(existing, f, indent=2)
EOF
            success "Hooks updated (backup: settings.json.backup)"
        fi
    else
        info "Creating new settings.json with hooks..."
        if command -v jq &>/dev/null; then
            echo "$hooks_config" | jq '.' > "$settings"
        else
            echo "$hooks_config" > "$settings"
        fi
        success "Created settings.json"
    fi

    info "Restart Claude Code to apply hooks"
}

# ── Usage ───────────────────────────────────────────────────
usage() {
    cat <<EOF
Usage: $0 [command]

Commands:
  install   Stow shared/* + {platform}/* (default)
  unstow    Remove all symlinks
  restow    Reinstall symlinks (useful after pulls)
  list      Show packages that would be stowed on this platform
  jupyter   Create global Jupyter env at ~/.jupyter-env
  claude    Configure Claude Code hooks from shared/claude/
  help      Show this help

Platform detected: $(detect_platform)$(is_wsl && echo ' (WSL)')
Dotfiles root: $DOTFILES
EOF
}

# ── Main ────────────────────────────────────────────────────
case "${1:-install}" in
    install)  install_dotfiles ;;
    unstow)   unstow_dotfiles ;;
    restow)   restow_dotfiles ;;
    list)     list_all ;;
    jupyter)  setup_jupyter ;;
    claude)   setup_claude_hooks ;;
    help|-h|--help) usage ;;
    *)
        error "Unknown command: $1"
        usage
        exit 1
        ;;
esac
