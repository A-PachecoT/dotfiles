---
name: hermes-delegate
description: >
  Delegate a task from Claude Code (Mac) to a Hermes agent on the Arch box
  (Atlas=personal/calendario/obsidian, Quipu=contabilidad, Temis=legal,
  Chaski=delivery, Mercurio=growth) via the shared hermes kanban board.
  Triggers: "delega a", "mándale la tarea a Quipu/Atlas/Temis/Chaski/Mercurio",
  "que lo haga el agente de", "delegate to hermes", "envíale esto al contador",
  "pídeselo a Atlas".
---

# Hermes Delegate — Claude Code → Hermes agents task bridge

Send work to a domain agent instead of executing the skill locally. The bus is
hermes' **kanban board** (root-shared SQLite at `~/.hermes/kanban.db` on the
Arch box): every gateway runs an embedded dispatcher that ticks ~60s, claims
`ready` tasks atomically, and spawns the assignee profile in an isolated
scratch workspace.

**Validated E2E 2026-07-09** (Mac → SSH → kanban → Atlas → Brainflow edit →
Syncthing back to Mac, task `t_94deee2d`). Cross-profile precedent: Temis →
Quipu 2026-07-07 (`t_128427c0`).

## When to delegate vs run locally

| Situation | Do |
|---|---|
| Task belongs to a domain agent's boundary (contabilidad → Quipu, legal watch → Temis, obsidian/calendar → Atlas, delivery chase → Chaski, growth → Mercurio) | **Delegate** |
| Needs interactive back-and-forth with the user right now | Run locally |
| Scheduled for a future date/time | NOT kanban (it runs ASAP). Use hermes cron on the box, or a calendar event (morning-brief reads calendar) |
| Result needed synchronously inside this session's next step | Run locally, or delegate + `run_in_background` until-loop on `kanban show` |
| Irreversible / client-facing send | Delegate only if the agent's own human-gates cover it; otherwise keep local with operator review |

## Create a task

```bash
ssh andre-arch 'PATH=/home/andre/hermes-agent/.venv/bin:$PATH; hermes kanban create \
  "<título corto>" \
  --body "<spec cerrada — ver reglas abajo>" \
  --assignee <profile> \
  --created-by claude-code-mac \
  --max-runtime 15m \
  --idempotency-key "<dominio>:<slug>:<YYYY-MM-DD>" \
  --json'
```

Valid assignees (= profiles on disk; verify with `hermes kanban assignees`):
`default` (Atlas) · `quipu` · `legal` (Temis) · `delivery` (Chaski) · `growth` (Mercurio).

## Check status / get result

```bash
ssh andre-arch 'PATH=/home/andre/hermes-agent/.venv/bin:$PATH; hermes kanban show <task_id>'
# status: ready → (claimed/spawned) → done | failed | blocked
# "Latest summary:" is the agent's result. Events + runs give the audit trail.
```

To wait without polling chat-side: `run_in_background` Bash with
`until ssh ... | grep -qE "status:\s+(done|failed|blocked)"; do sleep 20; done`.

## Body spec rules (the model on the other side is cheap — deepseek-class)

1. **Closed spec, issue-standard style**: single action, explicit DoD, "NO hagas
   nada más", failure instruction ("si X no existe, repórtalo y no crees nada").
2. **Global commands, absolute paths.** Cheap loop models fumble long paths and
   sandboxed `$HOME` (worker runs with `HOME=<profile>/home`). Reference CLIs by
   their global wrapper name when one exists.
3. **Idempotency-key always** — same contract as deals `delivery_log[]`:
   `{dominio}:{context-slug}:{YYYY-MM-DD}`. Re-running returns the existing id
   instead of duplicating.
4. **Deliver-to-Andre**: if the user should get the result on Telegram, say so
   in the body ("al terminar, envía el resumen a Andre por Telegram").

## Footguns (inherited from cantera playbook — do NOT relearn)

- **NEVER `hermes -p <name> -z "..."` one-shots** while that profile's gateway
  runs — deadlocks on `state.db` (playbook footgun #13). `hermes kanban ...`
  subcommands are safe (plain CLI, no agent loop).
- Kanban executes **ASAP**, it is not a scheduler.
- Assignee must be a **profile on disk**; `default` = Atlas (legacy home).
- Don't edit `~/.hermes/cron/jobs.json` by hand — live daemon owns it. Use
  `hermes cron create -p <profile>` on the box if a scheduled job is needed.
- SSH host is `andre-arch` (BatchMode works). The venv is shared across all
  agents — never update it as a side effect.

## SSOT

- Box-side anatomy + footguns: `~/cofoundy/products/cantera/playbook/building-agents/hermes-agents.md`
- Registry of live agents: `~/cofoundy/handbook/infrastructure/SYSTEMS.md` § Hermes Agents
