---
name: tk
description: >
  André's personal AI-first task list (`tk` CLI, store in ~/tasks, shown in his SketchyBar). Use to
  capture a task, link the CURRENT herdr agent to a task so André is pulled back here when it finishes,
  or close/list tasks. Triggers: "/tk", "anótalo en tk", "agrégalo a mis tareas", "enlaza esta sesión a
  la tarea", "tk link", "qué tengo en tk", "marca la tarea como hecha", "esto es prioridad de hoy".
  NOT for Cofoundy team tasks (those are Vikunja) or for delegating to Hermes (hermes-delegate).
---

# tk — la lista que se mantiene sola

SSOT: `~/dotfiles/docs/tk.md`. CLI: `tk --help`. Every command prints plain text; add `--json` where offered.

## Qué hacer según el pedido

| André dice | Corre |
|---|---|
| «anota X» / «agrega X a mis tareas» | `tk add --raw "X"` — la IA le pone título, prioridad y fecha en segundo plano. Si él dio prioridad o fecha explícita, pásalas: `tk add "X" --prio 1 --due 2026-10-06` |
| «esto es lo que estoy haciendo» / «enlaza esta sesión» / te deja trabajando en una tarea prioritaria | `tk add "X" --prio 1 --link-here` (nueva) o `tk link <id>` (existente; sin id = la de ahora). Enlaza el pane de herdr de ESTA sesión |
| «qué tengo» | `tk ls` |
| «listo, hecha» | `tk done <id>` — solo cuando André lo confirma; terminar tu turno NO cierra la tarea |

## Reglas

- **Enlazar es el valor.** Si André te deja trabajando en algo que figura en tk (o te pide algo prioritario), enlázalo: cuando quedes idle o bloqueado, la barra le muestra «tu agente terminó hace N min» y un clic lo trae a este pane.
- `--link-here` / `tk link` solo funcionan dentro de herdr (`HERDR_PANE_ID` presente). Fuera de herdr, captura sin enlace.
- No borres ni edites `~/tasks/events.jsonl` a mano: es append-only y lo sincroniza git entre el Mac y el Arch. Para corregir: `tk archive <id>` / `tk restore <id>` (reversible).
- No inventes prioridad ni fecha que André no dijo; para eso está `--raw`.
