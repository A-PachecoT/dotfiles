---
name: myturn
description: >
  André's task list + agent tracker (`myturn` CLI, alias `tk`; lives in his SketchyBar widget). Use when André
  pastes «Ayúdame con esta tarea: … corre `myturn link <id>`» (link THIS session to that task first), when he says
  «esto es prioridad», «avísame cuando termines», «anótalo en myturn», «agrégalo a mis tareas»,
  «recuérdamelo el 30» / «el lunes vuelvo a esto», or «/myturn».
  NOT for Cofoundy team tasks (Vikunja) or delegating to Hermes (hermes-delegate).
---

# myturn — tus tareas y quién trabaja en ellas

SSOT: `~/dotfiles/docs/myturn.md`. André opera todo desde el widget de la barra; el CLI es para ti.

| Situación | Corre |
|---|---|
| André te pega «Ayúdame con esta tarea: «X». Antes de empezar, corre `myturn link tXXXX`…» | `myturn link tXXXX` **antes de empezar** — enlaza ESTA sesión a la tarea; desde ahí André ve en la barra cuándo terminas o le preguntas algo |
| «esto es prioridad» / «avísame cuando termines» y no hay tarea | `myturn add "<título corto>" --prio 1` y luego `myturn link <id que imprime>` |
| «anota X» / «agrégalo a mis tareas» (otra cosa, no esta sesión) | `myturn add "X"` (con `--prio 1` si dijo que es urgente) |
| «recuérdamelo el 30» / «esto lo veo cuando responda X» (hoy no se puede hacer nada) | `myturn add "X" --desde "el 30"` — no aparece hasta ese día (acepta `mañana 9:00`, `lun`, `en 3 días`); ese día sube a HOY y le suena |
| «es para el viernes» / un plazo | `myturn add "X" --due "antes del vie"` — sigue visible y avisa ese día |
| posponer o fechar una que ya existe | `myturn when <id> "el 30"` (`"antes del vie"` plazo, `"ya"` la trae, `"sin fecha"` limpia) |
| «qué tengo» | `myturn ls` (las programadas: `myturn ls --todas`) |
| «mapea mis sesiones con mis tareas» / esta tarea la lleva otro Claude ya abierto | `myturn link <id> --pane <pane> --host <mac\|arch>` — enlaza desde afuera (pane de `herdr agent list`); si ese Claude ya terminó, queda visto |
| «listo, ciérrala» (solo si André lo confirma) | `myturn done <id>` |

Reglas: terminar tu turno NO cierra la tarea (André la cierra con ✓). No edites `~/tasks/events.jsonl` a mano.
No inventes prioridad ni fecha que André no dijo.
