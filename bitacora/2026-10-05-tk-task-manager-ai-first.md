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
