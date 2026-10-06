---
name: myturn
description: >
  André's task list + agent tracker (`myturn` CLI, alias `tk`; lives in his SketchyBar widget). Use when André
  pastes «Ayúdame con esta tarea: … corre `myturn link <id>`» (link THIS session to that task first), when he says
  «esto es prioridad», «avísame cuando termines», «anótalo en myturn», «agrégalo a mis tareas», or «/myturn».
  NOT for Cofoundy team tasks (Vikunja) or delegating to Hermes (hermes-delegate).
---

# myturn — tus tareas y quién trabaja en ellas

SSOT: `~/dotfiles/docs/myturn.md`. André opera todo desde el widget de la barra; el CLI es para ti.

| Situación | Corre |
|---|---|
| André te pega «Ayúdame con esta tarea: «X». Antes de empezar, corre `myturn link tXXXX`…» | `myturn link tXXXX` **antes de empezar** — enlaza ESTA sesión a la tarea; desde ahí André ve en la barra cuándo terminas o le preguntas algo |
| «esto es prioridad» / «avísame cuando termines» y no hay tarea | `myturn add "<título corto>" --prio 1` y luego `myturn link <id que imprime>` |
| «anota X» / «agrégalo a mis tareas» (otra cosa, no esta sesión) | `myturn add "X"` (con `--prio 1` si dijo que es urgente) |
| «qué tengo» | `myturn ls` |
| «listo, ciérrala» (solo si André lo confirma) | `myturn done <id>` |

Reglas: terminar tu turno NO cierra la tarea (André la cierra con ✓). No edites `~/tasks/events.jsonl` a mano.
No inventes prioridad ni fecha que André no dijo.
