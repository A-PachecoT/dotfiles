#!/usr/bin/env bash
# ssot-sync — mantiene frescos los "cerebros" CLAUDE.md symlinkeados.
#
#   pull (SessionStart) — ff-only de dotfiles + toolkit; avisa si hay SSOT
#                          sin commitear O commiteado sin pushear.
#   push (PostToolUse)  — mitad IRT: si shared/claude/* está dirty en dotfiles,
#                          commit+push inmediato (scoped, nunca toca otros files).
#
# El template del workspace (toolkit) tiene su PROPIO push team-wide
# (sync-pattern-library.sh watchlist); acá solo el repo personal dotfiles.
# Los agentes tratan los archivos como normales: el loop es infra.

MODE="${1:-pull}"
DOTS="$HOME/dotfiles"

# timeout portable: usa timeout/gtimeout si existen; en macOS sin coreutils
# degrada a correr sin límite (mejor que fallar con 127 y no pushear/pullear).
if command -v timeout >/dev/null 2>&1; then _to(){ timeout "$@"; }
elif command -v gtimeout >/dev/null 2>&1; then _to(){ gtimeout "$@"; }
else _to(){ shift; "$@"; }
fi

case "$MODE" in
  pull)
    for repo in "$DOTS" "$HOME/cofoundy/plugins/cofoundy-toolkit"; do
      [ -d "$repo/.git" ] || continue
      _to 8 git -C "$repo" pull --ff-only --autostash -q >/dev/null 2>&1 || true
      dirty=$(git -C "$repo" status --porcelain -- shared/claude templates/workspace-CLAUDE.md 2>/dev/null)
      ahead=$(git -C "$repo" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
      if [ -n "$dirty" ] || [ "${ahead:-0}" -gt 0 ]; then
        echo "ssot-sync: $(basename "$repo") tiene SSOT sin sincronizar (dirty o commiteado-sin-push) — commit+push (auto-OK por git-autonomy) o la otra máquina no lo verá."
      fi
    done
    ;;
  push)
    cd "$DOTS" 2>/dev/null || exit 0
    [ "$(git rev-parse --abbrev-ref HEAD 2>/dev/null)" = "main" ] || exit 0
    if git status --porcelain -- shared/claude 2>/dev/null | grep -q .; then
      git add -- shared/claude 2>/dev/null
      git commit -q -m "ssot: auto-sync shared/claude from $(hostname -s) $(date '+%F %H:%M')" -- shared/claude 2>/dev/null
    fi
    ahead=$(git rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
    [ "${ahead:-0}" -eq 0 ] && exit 0
    pushed=0
    if _to 15 git push -q 2>/dev/null; then
      pushed=1
    elif _to 10 git pull --rebase --autostash -q 2>/dev/null; then
      _to 15 git push -q 2>/dev/null && pushed=1 || echo "ssot-sync: push de dotfiles falló (¿offline?) — queda local, se reintenta"
    else
      git rebase --abort 2>/dev/null
      echo "ssot-sync: CONFLICTO en dotfiles shared/claude — dos máquinas editaron lo mismo; resolvé con git pull --rebase en ~/dotfiles"
    fi
    # fan-out event-driven: si pusheamos, avisar al otro worker (pull+reload herdr)
    # en background, best-effort. Peer offline lo agarra el SessionStart pull.
    if [ "$pushed" -eq 1 ] && [ -x "$DOTS/scripts/mesh-fanout.sh" ]; then
      nohup "$DOTS/scripts/mesh-fanout.sh" >/dev/null 2>&1 &
    fi
    ;;
esac
exit 0
