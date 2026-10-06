---
name: myturn
description: >
  André's personal agent-return queue (`myturn` CLI, alias `tk`; shown in his SketchyBar). Every Claude
  session inside herdr is registered automatically; this skill is for marking the CURRENT session as a
  priority (so André is pulled back here when you finish), closing it, or capturing a loose to-do.
  Triggers: "/myturn", "/tk", "esto es prioridad", "márcalo prioritario", "avísame cuando termines",
  "anótalo en myturn", "agrégalo a mis pendientes", "qué me espera", "marca la tarea como hecha".
  NOT for Cofoundy team tasks (Vikunja) or delegating to Hermes (hermes-delegate).
---

# myturn — tus agentes te esperan

SSOT: `~/dotfiles/docs/myturn.md`. CLI: `myturn --help`.

## Qué hacer según el pedido

| André dice | Corre |
|---|---|
| «esto es prioridad» / «avísame cuando termines» / te deja trabajando en algo del día | `myturn prio 1 --id $(myturn ls --json \| …)` no hace falta: corre `myturn prio 1` — prioriza el agente enfocado en herdr (esta sesión cuando André te habla). `myturn prio 0` = quitar. André lo hace él mismo con ⌥T |
| «anota X» / «agrégalo a mis pendientes» (algo que no es esta sesión) | `myturn add --raw "X"` — la IA saca fecha y prioridad en segundo plano. Si él dio prioridad o fecha, pásalas: `myturn add "X" --prio 1 --due 2026-10-06` |
| «qué me espera» / «qué tengo» | `myturn ls` |
| «listo, ciérrala» | `myturn done` (esta sesión) o `myturn done --id <id>` — solo cuando André lo confirma; terminar tu turno NO cierra la tarea |

## Reglas

- No hace falta registrar la sesión: el hook `UserPromptSubmit` (`myturn track`) ya lo hizo. Lo único que agrega valor es la **prioridad** — sin ella, myturn nunca interrumpe a André por esta sesión.
- `myturn prio` sin `--id` actúa sobre el agente **enfocado** en herdr, que es esta sesión cuando André te está hablando.
- No edites `~/tasks/events.jsonl` a mano (append-only, sincronizado por git entre el Mac y el Arch). Para corregir: `myturn archive <id>` / `myturn restore <id>`.
- No inventes prioridad ni fecha que André no dijo.
