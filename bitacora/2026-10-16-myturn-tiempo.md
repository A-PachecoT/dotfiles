# myturn: tiempo — programadas, HOY y fechas como hablas

**Fecha:** 2026-10-16 · **Issue:** A-PachecoT/dotfiles#2 · **SSOT:** `docs/myturn.md` §Tiempo

## Contexto
André: «lo que quiero es time awareness for tasks… think about user flow, improve it… it should also work for both
Obsidian and the plugin itself». El issue #2 lo concretaba: las esperas por terceros (aprobación de TikTok/Meta,
respuesta de un cliente) ocupan la lista sin poder hacerse, y el día que tocan myturn no avisaba (`due` solo ordenaba).

## Qué shipeó
- **Dos fechas:** `start` (cuándo aparece; oculta hasta entonces) y `due` (plazo). Con hora opcional.
- **Parser determinístico en español** (`parse_when`): «el 30», «mañana 9:00», «lun», «en 2 h», «la próxima semana»,
  «a las 3» (= 15:00) → aparece; «antes del vie», «para el 30», «hoy» → vence. Deja como texto lo que no es fecha
  («macro mar», «el 30%», «mié 14-oct» ya pasada).
- **Panel:** vista previa bajo «Nueva tarea» (`aparece el vie 30/10 · «Revisar TikTok»`), ◷ en cada fila (posponer,
  plazo, «ya», «sin fecha»; si no entiende, rojo y no guarda), secciones TE ESPERAN / HOY / MIS TAREAS /
  PROGRAMADAS (plegada, `p`), refresco cada 20 s mientras está abierto.
- **Barra:** HOY en amarillo por encima de «trabajando»; vencida en rojo. **Aviso** 1× al llegar («Hoy toca» /
  «Toca ahora») y la mañana en que vence algo que no tocaste hoy.
- **CLI:** `add --desde/--due/--parse`, `when`, `parse`, `ls --todas`. Jardinero: no archiva programadas.
- **Obsidian:** 🛫 de ida y vuelta (⏳ también), `## Programadas` en Tareas.md, frases en líneas nuevas del daily,
  `starts before tomorrow` en el template, en `daily_prep.py` (Hermes, commit `89253756`) y en la nota de hoy; el
  morning-brief sabe de `urgency` y `later`.

## Validación
44 tests + ruff. En vivo: tarea «en 2 min» → oculta en `ls`, visible en `ls --todas` → a las 19:01 sonó una vez, barra
`● Prueba de Claude… · toca hoy 19:01` amarilla, primera en `ls`, y el espejo del Arch la subió con `🛫 2026-10-16`.
Panel: preview y ◷ en el webview real vía `eval`; diseño con harness + `agent-browser`.

## Decisiones
- Fecha sin marca = **aparece** (es un recordatorio: lo que dice el issue con «revisar el 30»); «hoy» a secas = plazo.
- Un solo parser (Python); el panel le pregunta al CLI mientras escribes (~100 ms), no hay copia en JS.
- El panel parsea al agregar (`--parse`); un agente que llama `add` no: usa `--desde/--due` explícitos.
- Obsidian no tiene horas: misma fecha en 🛫 conserva la hora guardada.

## Learnings
- **Entre fecha y hora exige un separador:** con `\s*` opcional, «11:00» se leía como día «1» + hora «1:00».
- **Una abreviatura suelta no es fecha** («macro mar presencial»): solo cuenta con «el», número u hora.
- **Para ver un panel webview de Hammerspoon sin interrumpir:** harness HTML con stub de `webkit.messageHandlers` +
  `agent-browser`; `screencapture` no lo mostró y Chrome `--headless` se colgó con Chrome abierto.
