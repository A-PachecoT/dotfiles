#!/usr/bin/env bash
# mesh-update (alias `mu`) — fan-out del mesh: pull dotfiles + reload herdr en
# AMBOS workers (Mac + Arch) de un solo comando. Corré desde cualquiera de los dos.
# Idempotente. Deja las dos cajas a la última con los keybinds de herdr LIVE.
#
# Por qué existe: el auto-pull del SessionStart es per-device y lazy, y el
# `herdr server reload-config` es manual. Esto cierra el loop cross-mesh.
# celu/tablet son solo terminales (sin server herdr) → no entran acá; jalan su
# ~/.bashrc por su cuenta. Ver docs/device-mesh.md.
set -uo pipefail

MESH_MAC="styreep@100.73.150.52"    # Tailscale
MESH_ARCH="andre@100.84.249.22"     # Tailscale
# IdentityAgent=none → ignora cualquier ssh-agent y usa las keys ed25519 directo.
# Blinda contra el cuelgue Arch→Mac por SSH_AUTH_SOCK ET-forwarded vivo-pero-mudo
# (ver clipboard-bridge en CLAUDE.md). Las keys del mesh son passphraseless.
SSH_OPTS=(-o ConnectTimeout=8 -o BatchMode=yes -o IdentityAgent=none)

# Lógica que corre EN una caja (local o vía ssh): fast-forward + reload herdr si
# hay server. Heredoc quoted → nada se expande acá; todo corre en la caja destino.
read -r -d '' REMOTE_CMD <<'EOSH' || true
  cd "$HOME/dotfiles" 2>/dev/null || { echo "  x no existe ~/dotfiles"; exit 0; }
  git pull --ff-only --autostash -q >/dev/null 2>&1 \
    || echo "  ! pull no fast-forward (divergencia) — resolvé con: git -C ~/dotfiles pull --rebase"
  echo "  $(git log --oneline -1)"
  # reload sin adivinar si hay server: intentamos y el exit code decide.
  if "$HOME/.local/bin/herdr" server reload-config >/dev/null 2>&1; then
    echo "  herdr: reloaded (keybinds live)"
  else
    echo "  herdr: sin server corriendo (nada que recargar)"
  fi
EOSH

case "$(uname -s)" in
  Darwin) SELF="Mac";  REMOTE_HOST="$MESH_ARCH"; REMOTE_NAME="Arch" ;;
  Linux)  SELF="Arch"; REMOTE_HOST="$MESH_MAC";  REMOTE_NAME="Mac"  ;;
  *)      echo "mesh-update: OS no soportado ($(uname -s))"; exit 1 ;;
esac

echo "mesh-update · desde $SELF → actualiza Mac + Arch"

# 1. push commits locales sin pushear, así el remoto los ve (auto-OK dotfiles).
if [ "$(git -C "$HOME/dotfiles" rev-parse --abbrev-ref HEAD 2>/dev/null)" = "main" ]; then
  ahead=$(git -C "$HOME/dotfiles" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
  if [ "${ahead:-0}" -gt 0 ]; then
    if git -C "$HOME/dotfiles" push -q 2>/dev/null; then
      echo "· push local: $ahead commit(s) → origin/main"
    else
      echo "· ! push local falló (¿offline / rechazado?) — el remoto puede quedar atrás"
    fi
  fi
fi

# 2. self (local)
echo "[$SELF] (local)"
bash <<< "$REMOTE_CMD"

# 3. remoto (ssh one-shot; el script se alimenta por stdin → sin quoting hell)
echo "[$REMOTE_NAME] ($REMOTE_HOST)"
if ! ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" bash <<< "$REMOTE_CMD"; then
  echo "  x ssh falló — host caído o Tailscale dormido"
fi

echo "mesh-update · listo"
