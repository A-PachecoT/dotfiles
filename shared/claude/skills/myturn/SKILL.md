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
| **cumpliste la tarea** y verificaste el efecto (en prod y probado, mensaje enviado, archivo publicado) | `myturn done <id>` **tú, sin esperar a André**, y díselo en una línea: «cerré t3c7ee4 (DNI): en prod, verificado». También las que no enlazaste pero creaste o cumpliste en esta sesión |
| a medias, esperando a un tercero («cuando Silvana mande X»), o la tarea es una decisión o acción de André | no la cierres: `myturn when <id> …` si depende de una fecha, y di qué falta |

Reglas: terminar tu turno no es cumplir la tarea; cumplirla sí la cierra, y la cierras tú (es reversible: `myturn restore <id>`). Nunca le digas a André «ciérrala tú» de algo que ya cumpliste. No edites `~/tasks/events.jsonl` a mano.
No inventes prioridad ni fecha que André no dijo.
