#!/usr/bin/env bash
# ssot-sync — SessionStart hook: keep the two symlinked CLAUDE.md "brains" fresh.
#
# ~/.claude/CLAUDE.md        → ~/dotfiles/shared/claude/CLAUDE.md
# ~/cofoundy/CLAUDE.md       → ~/cofoundy/plugins/cofoundy-toolkit/templates/workspace-CLAUDE.md
#
# Agents treat those files as NORMAL files. This hook closes the sync loop so no
# agent needs to know about pull: every session starts by fast-forwarding both
# SSOT repos (fail-soft: offline/dirty/slow → silent no-op). The push half is
# taught inside each file's header + covered by the git-autonomy session-close
# default; we only WARN here when local SSOT edits are sitting uncommitted.
# Quiet on no-op by design — hook output lands in the session context.

for repo in "$HOME/dotfiles" "$HOME/cofoundy/plugins/cofoundy-toolkit"; do
  [ -d "$repo/.git" ] || continue
  timeout 8 git -C "$repo" pull --ff-only --autostash -q >/dev/null 2>&1 || true
  dirty=$(git -C "$repo" status --porcelain -- shared/claude/CLAUDE.md templates/workspace-CLAUDE.md 2>/dev/null)
  if [ -n "$dirty" ]; then
    echo "ssot-sync: $(basename "$repo") tiene ediciones SIN COMMITEAR en el CLAUDE.md SSOT — commit+push (auto-OK por git-autonomy) o la otra máquina nunca las verá."
  fi
done
exit 0
