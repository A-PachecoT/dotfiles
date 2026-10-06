# 2026-10-05 — tk: task manager AI-first en la barra, enlazado a herdr

## Contexto
André pidió un widget de SketchyBar «tipo el de Spotify» que fuera un task manager AI-first, para uso personal (posible OSS en su cuenta). Problemas que eligió: no sabe qué hacer ahora, lo que dice se pierde y la lista se pudre (causas raíz: nadie poda, no la ve, la prioridad es estática). A mitad del diseño agregó lo central: «me dejaron varias tareas prio para hoy, dejé a un agente trabajando y por context switching me olvidé de volver; tengo como 60 sesiones de claude». Diseño con /system-design + /options; él pidió MVP sin pulir y que reemplace al widget de Spotify.

## Qué se shipeó
- `scripts/tk`: CLI (uv, sin deps). Store append-only `~/tasks/events.jsonl` (repo privado `A-PachecoT/tasks`, `merge=union`), ranking con porqué escrito por el código, `enrich` con `claude -p --json-schema`, `garden` (poda reversible + triage IA 1×/día), `go` (AeroSpace + `herdr agent focus`, o reabre con `--resume` / abre con `--session-id` + `/goal`).
- SketchyBar: `items/tk.sh` + `plugins/tk.sh` en el centro, en lugar de Spotify (que queda en el repo sin cargarse).
- Hammerspoon `tk.lua`: ⌃⌥T abre un chooser para capturar o saltar a una tarea.
- Skill `/tk` (`shared/claude/skills/tk`) para que los agentes capturen y se enlacen.
- SSOT: `docs/tk.md`.

## Validación
6 smoke tests + ruff. En vivo: captura vía Hammerspoon → la IA la dejó «Revisar el popup · p1 · vence mañana» (~8 s); clics, archive y `go` funcionan; popup visto en el monitor externo; ida y vuelta Mac ⇄ Arch por git; el Arch lee el estado del agente del Mac por ssh. `tk now` tarda 0,19 s.

## Decisiones
- Enlace anclado en el id de la sesión de Claude (= `agent_session` de herdr), no en el pane.
- La IA escribe campos y el código, el porqué (verificable). Podar = archivar.
- Personal → fuera de `SYSTEMS.md` de Cofoundy; Vikunja, calendario y celular fuera del v1.

## Learnings
- `claude -p` headless necesita `USER` en el entorno (con `env -i` sin `USER` falla con `api_error`); `--setting-sources ""` evita los hooks del usuario y `--json-schema` devuelve `structured_output`.
- Los items de sketchybar están stoweados archivo por archivo: un archivo nuevo necesita `stow -R`. Además, sketchybar y Hammerspoon arrancan con PATH mínimo, así que el shebang `env uv` falla sin un wrapper que exporte el PATH.
- `mouse.exited.global` cierra la popup apenas se abre si el mouse no está encima: para capturarla en pruebas, screenshot inmediato y en el display correcto (`screencapture -D 2`).
- `~/.claude-pending/` tenía 44 473 archivos `unknown_unknown`: ese sistema está muerto; tk lo reemplaza para herdr.

## v1 — myturn (misma sesión)
- André revisó el flujo del MVP: «no creo que hayas pensado bien el user flow». El dry run expuso 5 huecos: nadie enlaza a mano, «tu turno» se queda pegado, una sola «tarea de ahora» no calza con 5 agentes en paralelo, avisa en silencio y no hay teclado.
- Rediseño: la unidad es la sesión de herdr. El hook `myturn track` registra cada agente con el título que Claude Code ya pone (Haiku descartado para títulos: era trabajo duplicado). Solo interrumpe lo priorizado; «visto» = pane enfocado con la ventana de herdr al frente después de la última transición; sonido 1× por transición; ⌥T paleta, ⌥G salto.
- Nombre con la skill `naming`: 5 scouts por territorio de metáfora (crook, wilco, stint, bellhop…). André: «no tienen nada que ver, debe ser fácil de recordar» → literal: **myturn**.
- Learnings: `pypi.org/project/<x>/` devuelve 200 para cualquier nombre (protección anti-bots); usa `/pypi/<x>/json`. En US International-PC ⌥N es la ñ: ojo con los hotkeys de Option. `terminal_title_stripped` de herdr NO quita el glifo de estado de Claude Code (✳/◐). Para descartar un `claude -p` que corre dentro de un pane, el hook compara su `session_id` con el `agent_session` del pane en herdr.

## v1.2 + Obsidian (2026-10-06)
- Panel: el widget es toda la UI (webview de Hammerspoon): anotar, editar, prioridad, «Copiar para Claude» → `myturn link <id>`, ir/reabrir agente, ✓/✕.
- Obsidian: myturn es la única casa; `05. System/myturn/Tareas.md` es un espejo vivo (timer del Arch, gate + atómico); el daily note lo muestra con una consulta del plugin Tasks; lo que André anota como `- [ ]` en el To-do se importa y queda `- [>] … → myturn`. `daily_prep.py` ya no arrastra 📅 ni `- [ ] —`; el morning-brief lee myturn.
- Hallazgos: la migración de Hermione borró «Melissa» de la nota de hoy (no la reproduce el script; fue una edición manual) — myturn la rescató de la nota de ayer. Gotchas: número JS → Lua llega como `1.0`; `pypi.org/project/` siempre 200; `hs -c 'hs.reload()'` se cuelga (lanzarlo en segundo plano con alarm).
