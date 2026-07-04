# 2026-07-04 — tmux-assistant-resurrect en Mac + boot dinámico de sesiones

**Operador:** André (+ Claude)

---

## Contexto

Dos pedidos encadenados en la misma sesión: (1) replicar en la Mac el plugin
`timvw/tmux-assistant-resurrect` ya validado en el box Arch (auto-`--resume`
de Claude tras un reboot, vía hook `SessionStart`); (2) el `dev-startup.sh`
existente solo abría 4 sesiones tmux hardcodeadas (`cofoundy`, `bilio`,
`personal`, `notes`), cada una a un workspace fijo de AeroSpace — pero André
ya corre más sesiones que eso (`aeda`, `portfolio`, `thesis` observadas
vivas), y esas nunca se abrían al bootear aunque `tmux-resurrect` las tuviera
guardadas.

---

## Qué Pasó

### 1. Plugin `tmux-assistant-resurrect`

- Clonado a `~/.tmux/plugins/tmux-assistant-resurrect`, cargado vía
  `tmux source-file` en un socket `-L matest` aislado (no se tocó la sesión
  real).
- Merge a `~/.claude/settings.json` confirmado **100% aditivo**: solo se
  agregaron bloques `SessionStart`/`SessionEnd`, cero borrados — los hooks
  previos (`claude-notify` en `Stop`/`Notification`) intactos. `diff` entre
  backup y post-instalación lo confirma.
- Smoke test end-to-end con contenido real (no una sesión vacía): `save` →
  `kill-server` → `restore` relanzó `claude --resume <id-exacto>` y la
  conversación previa reapareció intacta.
- `@continuum-save-interval` bajado de `10` a `1` minuto (SSOT
  `shared/tmux/.tmux.conf`, afecta Mac y Arch) — 10 min dejaba una ventana
  de pérdida demasiado ancha para paneles/session-ids nuevos ante un crash.

### 2. Rediseño de `dev-startup.sh` (descubrimiento dinámico)

Spec completa: `docs/superpowers/specs/2026-07-04-dynamic-tmux-session-restore-design.md`.
Plan: `docs/superpowers/plans/2026-07-04-dynamic-tmux-session-restore.md`.

- **Fijos:** 1=Comet, 2=cofoundy, 8=Bitwarden (ahora tiled, no floating),
  9=Obsidian+notes.
- **Variable pool `{3,4,5,6,7,10}`:** todo lo demás (bilio, personal, y
  cualquier sesión nueva/local, más las sesiones activas del Arch box vía
  SSH) se descubre en cada boot y se asigna vía un mapa "sticky"
  (`~/.local/state/dotfiles/dev-startup-workspace-map.txt`, machine-local)
  que recuerda la asignación previa por nombre y solo usa slots nuevos para
  sesiones nunca vistas. Si sobran sesiones, se apilan (tiling) en vez de
  perderse en silencio.
- Nuevos scripts: `resurrect-session-names.sh` (lee el snapshot de
  resurrect), `arch-session-names.sh` (SSH con timeout de 3s al Arch box,
  nunca bloquea si está offline), `workspace-sticky-map.sh` (la lógica de
  asignación estable).
- `.aerospace.toml`: Bitwarden pinneado a WS8 tiled (separado del popup de
  extensión del navegador, que sigue floating), reglas estáticas de título
  `bilio→3`/`personal→4` eliminadas (competían con la asignación dinámica),
  regla `cursor→5` eliminada (workspace 5 pasa al pool variable).
- `personal` (la sesión tmux, no el workspace) queda fuera del set fijo —
  se solapaba con `notes` para Brainflow/Obsidian. André confirmó que se
  retirará más adelante (no en esta sesión — es la sesión donde estábamos
  conversando, no se podía matar en caliente).

### 3. Bugs reales encontrados en el rehearsal en vivo (no en dry-run)

El plan explícitamente pedía correr `dev-startup.sh` de verdad (no solo
`--dry-run`) antes de dar luz verde al reboot. Encontró 3 bugs que el
dry-run nunca hubiera revelado:

1. **Carrera de foco:** `aerospace move-node-to-workspace <n>` sin
   `--window-id` actúa sobre "la ventana con foco actual" — con trabajo real
   en curso en otra ventana, movió esa ventana equivocada en vez de la recién
   creada. Fix: `--window-id` explícito, resuelto por polling de título
   exacto (`aerospace list-windows --all --format ...`).
2. **Pipe que se come el stdin del loop:** `echo "$assignments" | while read
   ...; do aerospace ...; done` — llamar `aerospace` dentro de un `while
   read` alimentado por pipe le drena el stdin al loop entero, cortándolo
   después de la primera iteración. Reproducido aislado en 3 líneas. Fix:
   juntar todo a arrays primero (sin comandos externos en ese loop), iterar
   después con un loop indexado sin pipes de por medio.
3. **`aerospace` se cuelga bajo contención:** confirmado en vivo que
   `aerospace list-windows --all` puede colgarse indefinidamente — coincide
   con el deadlock aerospace↔SketchyBar ya documentado en
   `docs/audio-priority-system.md`. Un conteo fijo de reintentos alrededor de
   una llamada bloqueante no alcanza si la llamada nunca retorna. Fix:
   `run_with_timeout` casero (macOS no trae `timeout`/`gtimeout` de
   fábrica) que backgroundea + mata por PID si excede el límite, envolviendo
   toda llamada a `aerospace`; polling reducido de 30 a 5 intentos para
   bajar el volumen total de llamadas.

### 4. Susto de sesiones "perdidas" (falsa alarma)

Durante el rehearsal, `aeda`, `thesis`, `bilio` y `portfolio` desaparecieron
de `tmux ls`. Se paró toda ejecución y se preguntó directamente a André antes
de asumir nada — confirmó que fue él mismo, en paralelo, cerrando/consolidando
esas sesiones (una de ellas, "brand", se creó con `tmux new-session` plano,
no con el patrón `-A` del script, confirmando que no fue el script quien la
creó). Nada que arreglar; validó la regla de "parar y preguntar" en vez de
seguir asumiendo sobre una máquina con actividad concurrente real.

---

## Aprendizaje

- `aerospace move-node-to-workspace` sin `--window-id` es inherentemente una
  carrera contra cualquier cosa que cambie el foco — nunca asumir "la última
  ventana abierta tiene el foco" en un script que abre varias ventanas en
  secuencia rápida.
- Nunca llamar un binario externo (especialmente uno con IPC propio, como
  `aerospace`) dentro del cuerpo de un `while read` alimentado por un pipe —
  puede drenarle el stdin al loop sin ningún error visible.
- Un conteo de reintentos no es un timeout: si la llamada individual puede
  colgarse indefinidamente, hace falta un timeout real por-llamada (macOS no
  trae `timeout(1)`, hay que armarlo a mano con `& + kill -0 polling`).
- El deadlock aerospace↔SketchyBar (ya documentado) no es solo un riesgo de
  UI — cualquier script que llame `aerospace` en un loop apretado (como un
  dev-startup con 8 sesiones) lo puede disparar; hay que tratar cada llamada
  a `aerospace` como potencialmente bloqueante, no como una syscall barata.
- Ante una señal ambigua de posible pérdida de datos del usuario en una
  máquina con actividad concurrente real, parar y preguntar directamente es
  más rápido y correcto que seguir investigando en soledad — la explicación
  real (actividad paralela genuina del usuario) era invisible sin preguntar.
- El rehearsal en vivo (no solo `--dry-run`) es lo que encontró los 3 bugs
  reales — el diseño aprobado y el dry-run nunca los hubieran revelado.

---

## Acción

- `~/.tmux/plugins/tmux-assistant-resurrect` clonado e instalado (machine-local).
- `shared/tmux/.tmux.conf`: `@continuum-save-interval` 10→1 (commit `0dcb598`).
- `docs/superpowers/specs/2026-07-04-dynamic-tmux-session-restore-design.md` (commit `4b0aaa1`).
- `docs/superpowers/plans/2026-07-04-dynamic-tmux-session-restore.md` (commit `6a10f0f`).
- `scripts/resurrect-session-names.sh` (commit `1cb5616`).
- `scripts/arch-session-names.sh` (commit `977ef41`).
- `scripts/workspace-sticky-map.sh` (commit `60dcd6b`).
- `scripts/dev-startup.sh` reescrito, incluyendo los 3 fixes post-rehearsal
  (`--window-id`, arrays en vez de pipe, `run_with_timeout`) — commits
  `f838f96` + fixes posteriores en la misma sesión.
- `macos/aerospace/.aerospace.toml`: Bitwarden→WS8 tiled, reglas
  bilio/personal/cursor eliminadas (commit `567c768`).
- Validado con rehearsal real end-to-end: fijos correctos, dinámicos
  correctos y estables entre corridas, exhaustion del pool logueado y
  apilado sin pérdida silenciosa.
