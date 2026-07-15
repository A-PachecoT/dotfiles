#!/usr/bin/env bash
# mesh-fanout — nudge event-driven al OTRO worker: jalá origin/main + recargá herdr.
# Lo llama `ssot-sync push` tras un push exitoso (propagación sin correr `mu`).
# Best-effort y no bloqueante: si el peer está offline, falla silencioso y el
# SessionStart pull lo agarra al despertar. celu/tablet quedan fuera (sin herdr).
# IdentityAgent=none → inmune al cuelgue Arch→Mac por SSH_AUTH_SOCK ET muerto.
set -uo pipefail

MESH_MAC="styreep@100.73.150.52"    # Tailscale
MESH_ARCH="andre@100.84.249.22"     # Tailscale

case "$(uname -s)" in
  Darwin) PEER="$MESH_ARCH" ;;
  Linux)  PEER="$MESH_MAC" ;;
  *)      exit 0 ;;
esac

ssh -o ConnectTimeout=6 -o BatchMode=yes -o IdentityAgent=none "$PEER" bash <<'EOSH' >/dev/null 2>&1 || true
  cd "$HOME/dotfiles" 2>/dev/null || exit 0
  git pull --ff-only --autostash -q >/dev/null 2>&1 || exit 0
  "$HOME/.local/bin/herdr" server reload-config >/dev/null 2>&1 || true
EOSH
