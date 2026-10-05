# tk — la lista que se mantiene sola (SSOT)

> Task manager personal y AI-first de André. Vive en la barra (SketchyBar, en el lugar del widget de Spotify),
> captura con ⌃⌥T y cada tarea puede apuntar a un agente de herdr. Uso personal, no es un sistema de Cofoundy
> (por eso no está en `handbook/infrastructure/SYSTEMS.md`). MVP del 2026-10-05; candidato a OSS en la cuenta
> personal (A-PachecoT) cuando se estabilice.

## Qué problema resuelve

Lo dijo André el 2026-10-05: «hoy me dejaron varias tareas prio para hoy y dejé a un agente trabajando y por
context switching me olvidé de volver a ellos. Además ahora tengo como 60 sesiones de claude». Las listas
anteriores (Vikunja: 125 abiertas, casi todas muertas; BrainFlow; `/secretary`) murieron por tres causas que
él eligió: **nadie poda, no la veo y la prioridad es estática**. tk ataca las tres y agrega la cuarta: **volver al
agente** cuando termina.

## Principios

1. **La IA escribe campos y el código escribe el porqué.** La IA pone título, prioridad y fecha (`tk enrich`) y
   re-prioriza o archiva (`tk garden --ai`). El «porqué» que ves («vence hoy · p1 · tu agente terminó hace 12 min»)
   lo arma el código desde esos campos, así que siempre es verificable.
2. **Podar es archivar, nunca borrar.** Todo se puede deshacer con `tk restore <id>`; el popup avisa «podé N».
3. **La barra solo lee.** Pintar cuesta ~0,2 s (herdr por socket + fold); la IA corre por eventos (captura) y una
   vez al día (garden), nunca por repintado.
4. **El agente es un usuario de primera clase** (cantera L-008): CLI con `--json`, skill `/tk`, y el enlace al
   agente se ancla en el **id de la sesión de Claude** (no en el pane), así sobrevive aunque el pane se mueva y
   se puede reabrir con `claude --resume`.
5. **Un solo escritor, store append-only.** `events.jsonl` con `merge=union` en git: el Mac y el Arch escriben
   sin conflictos; el estado se deriva ordenando por `ts`.

## Flujo

```
⌃⌥T (Hammerspoon) ─┐                    ┌─> claude -p (haiku): título/prio/fecha   [tk enrich, async]
/tk (skill) ───────┼─> tk add ─> events.jsonl ──git pull/push──> Arch (y viceversa)
popup (clics) ─────┘                    │
                                        └─> tk sketchybar: fold + herdr agent list (+ ssh Arch, caché 60 s)
                                              ├─ rank: tu turno (agente idle/blocked) > elegida > vencida/hoy > p1..p3 > antigüedad
                                              ├─ trabajando (agente working) → aparte, «⏳»
                                              └─ pinta tk.anchor + popup; 1×/día dispara tk garden --ai
clic en la tarea ─> tk go: aerospace focus (ventana herdr-mac|herdr-arch) + herdr agent focus <pane>
                    (sin agente vivo: pestaña nueva con claude --resume; sin enlace: claude --session-id <uuid> "/goal …")
```

## Integraciones

| Con qué | Cómo | Dueño |
|---|---|---|
| herdr | `herdr agent list/focus`, `tab create`, `pane run`, `pane current` (socket local; Arch por `ssh andre-arch`) | herdr |
| AeroSpace | `list-windows` + `focus --window-id` sobre las ventanas tituladas `herdr-mac` / `herdr-arch` (las fija `scripts/dev-startup.sh`) | dotfiles |
| Claude Code | `claude -p --json-schema` (structured_output) con `--setting-sources ""` (sin hooks del usuario) | suscripción de André |
| Vikunja / calendario / celular | **fuera del v1** | — |

## Quién es dueño de qué

| Pieza | Archivo |
|---|---|
| CLI, store, ranking, IA, foco | `scripts/tk` (→ `~/.local/bin/tk`, en ambas cajas) |
| Tests | `scripts/tests/test_tk.py` (`uv run --with pytest pytest scripts/tests/test_tk.py`) |
| Barra y popup | `macos/sketchybar/.config/sketchybar/items/tk.sh` + `plugins/tk.sh` (wrapper con PATH) |
| Captura | `macos/hammerspoon/.hammerspoon/tk.lua` (⌃⌥T) |
| Skill para agentes | `shared/claude/skills/tk/SKILL.md` (→ `~/.claude/skills/tk`) |
| Datos | repo privado `A-PachecoT/tasks` en `~/tasks` (`events.jsonl`; `state.json` es derivado e ignorado) |
| Caché local | `~/.cache/tk/` (estados vistos de agentes, última poda, último pull) |

## Entradas

`tk --help` · ⌃⌥T · hover sobre la tarea en la barra · `/tk` dentro de Claude.

## Validación (2026-10-05)

- 6 smoke tests (fold, ranking, snooze/bump, «tu turno» vs trabajando, poda reversible, merge intercalado).
- En vivo: captura por Hammerspoon → la IA la dejó «Revisar el popup · p1 · vence mañana» en ~8 s; clics
  `now.next` / archive / `go` (enfocó el pane enlazado); git commit + push al repo de datos; el popup se vio en el
  monitor externo con «1 agente trabajando · 62 sesiones idle sin tarea».

## Roadmap

- **v1.1:** cerrar sesiones idle sin tarea desde el popup (hoy solo lista: `tk sessions`, o clic en el footer);
  aviso sonoro cuando el agente de la tarea de ahora termina.
- **v1.2:** contexto de calendario en el ranking; captura desde el celular (bot de Buzz/WhatsApp).
- **OSS:** extraer `tk` a un repo propio cuando el ciclo de uso diario lo valide (`/oss-plugin` está pensado para
  la org de Cofoundy; aquí va a la cuenta personal).
- **No está en el alcance:** las tareas de equipo (siguen en Vikunja); el sistema `claude-pending` está muerto
  (44 473 archivos `unknown_unknown` el 2026-10-05) y tk lo reemplaza para lo que corre en herdr.
