# myturn — visión y diseño (SSOT)

> Nombre: **myturn** («mi turno»; elegido con la skill `naming` el 2026-10-05, tras descartar metáforas — André: «debe ser fácil de recordar»). `tk` queda como alias del CLI.
> Proyecto personal de André, pensado para publicarse como OSS en su cuenta (A-PachecoT) para la comunidad de
> power users de Claude Code. No es un sistema de Cofoundy (por eso no está en `handbook/infrastructure/SYSTEMS.md`).

## Visión

**Trabajas con una flota de agentes; myturn se encarga de que nunca dejes a uno esperándote sin saberlo.**

El cuello de botella ya no es lo que tardan los agentes sino tu atención: lanzas cinco Claude en paralelo, te vas a
otra cosa y el que terminaba la tarea prioritaria del día se queda idle una hora. myturn vive en la barra del sistema,
sabe qué agente trabaja en qué y cuál de ellos te está esperando, y te lleva a él con una tecla.

En palabras de André (2026-10-05): *«hoy me dejaron varias tareas prio para hoy y dejé a un agente trabajando y
por context switching me olvidé de volver a ellos. Además ahora tengo como 60 sesiones de claude.»*

### Qué es y qué no es

- **Es** tu lista de tareas *y* quién trabaja en cada una. Todo se opera desde el widget de la barra (André,
  2026-10-06: *«tiene que ser todo vía UI desde el mismo widget»*): anotar, editar, cambiar prioridad, copiar la
  tarea para un Claude, ir al agente, cerrar.
- **No es** un gestor de proyectos ni de equipo (eso es Vikunja), ni un orquestador de agentes (eso es herdr y
  `/cto`). Si tienes que *mantenerlo*, falló.

### El flujo, de punta a punta

1. **Anotas** en el widget: clic en la barra (o ⌥T) → `n` → escribes → Enter. Opcional: `!1`/`!2` antes de agregar.
2. **Se la das a un Claude**: botón «Copiar para Claude» → lo pegas en cualquier sesión. El texto le pide correr
   `myturn link <id>`, y desde ahí esa sesión *es* el agente de la tarea.
3. **Te vas a otra cosa.** Cuando el agente termina o te pregunta algo y no lo has visto, la tarea sube a **TE
   ESPERAN**, suena una vez y la barra se pone verde: `● Cotización Ecoverde · te espera`.
4. **Vuelves**: botón «Ir · te espera» en el widget, o ⌥G desde cualquier lado. Mirarlo cuenta como visto.
5. **Cierras**: ✓ (hecha) o ✕ (archivar, reversible). Doble clic en el título lo edita; clic en `!` rota la
   prioridad (— → !1 → !2 → —).

Las sesiones de Claude que abres sin tarea igual las registra el hook (`myturn track`), en silencio: no aparecen
en el widget, solo existen para que el enlace sea instantáneo y para que el jardinero las pode.

### Principios

1. **Todo desde el widget.** El CLI y la skill existen para el panel y para los agentes, no para André.
2. **La tarea es tuya; el agente se engancha a ella.** El enlace lo hace el agente (`myturn link`), con el texto
   que copiaste: cero pasos manuales de vinculación.
3. **Visto apaga la alarma.** Un agente idle que ya miraste no «te espera»; vuelve a hacerlo con una transición
   nueva (respondiste, trabajó, terminó otra vez).
4. **Cada botón dice lo que hace.** «Ir al agente», «Reabrir agente», «Copiar para Claude», ✓, ✕. Nada de menús
   mixtos ni teclas con significado oculto: ⌥T abre el widget, ⌥G va al que te espera (⌥N no: en US
   International-PC es la ñ).
5. **El código escribe el estado; la IA solo donde hay juicio.** Estados: los de herdr. Títulos: los tuyos (o los
   de Claude Code para sesiones sin tarea). La IA (`claude -p`) queda para la poda y (v2) resumir qué hizo el
   agente que te espera.
6. **Nada se borra.** Podar = archivar con razón; `myturn restore`.
7. **Local-first, sin servidor.** Un repo git privado con un log append-only (`merge=union`) sincroniza el Mac y
   el Arch; herdr de la otra caja se lee por ssh.

## Diseño

### Obsidian (desde 2026-10-06)

André: *«necesito que el task manager esté sincronizado con Obsidian; el sistema anterior era Obsidian pero me
costaba tenerlo updated»*. La causa medida: `daily_prep.py` (Hermes) copiaba cada mañana todo `- [ ]` no marcado,
incluidos eventos 📅 de días pasados, así que nada expiraba nunca.

- **myturn es la única casa; Obsidian es un espejo vivo.** `05. System/myturn/Tareas.md` lo reescribe el timer
  `myturn-obsidian` del Arch cada minuto (único escritor, respeta `~/.local/bin/vault-write-gate.py`, escritura
  atómica para Syncthing). Formato del plugin Tasks: `- [ ] Título ⏫ 📅 2026-10-09 [agente:: te espera] ^t1a2b3`.
- **El daily note muestra la lista viva** con una consulta ```tasks``` (`path includes 05. System/myturn/Tareas`)
  bajo la línea GOAL; la pone el template (`05. System/Templates/Daily by name.md` y el de `daily_prep.py`).
- **Ida y vuelta.** En `Tareas.md`: `[x]` cierra, editar texto/⏫/🔼/📅 actualiza, `- [ ] …` sin `^id` crea (se
  compara contra la última escritura, así una edición del widget no se pierde). En el `### To-do` del daily note:
  cada `- [ ] …` tuyo que no sea 📅 ni placeholder entra a myturn (los accionables de reunión como «Reu X: …») y la
  línea queda `- [>] … → myturn`: no se borra nada y no se cuenta doble. Lo que daily_prep copió de ayer se marca,
  no se duplica.
- **daily_prep ya no arrastra** eventos 📅 ni `- [ ] —` vacíos. Reuniones, eventos y journaling siguen siendo de
  Hermione (`daily_note_events.py`).
- **El morning-brief** lee `myturn ls --json` (Step 3b) para «Tus tareas» y la prioridad del día.
- Latencia medida: widget → Obsidian del Mac 50 s; `[x]` en Obsidian → cerrada en myturn ~100 s.


### Teclado del panel (desde 2026-10-09)

André: *«cuando le doy a alt + t quiero que se focusee en el panel y que si le doy n se pone en crear nueva task y si
le doy f se pone a buscar y que pueda hacer navegación con hjkl enter/space y que cuando le dé escape vuelva al
aerospace panel donde me quedé»*.

- ⌥T abre en **modo lista** (ningún campo enfocado), con la primera fila elegida en su botón de acción.
- `j`/`k` (o flechas) cambian de fila; `h`/`l` de columna: título · prioridad · acción · ✓ · ✕. `Enter`/`Espacio`
  la ejecuta (en el título, edita). Lo mismo que hace el clic, sin atajos ocultos.
- `n` enfoca «Nueva tarea»; `f` o `/` abre «Buscar» (filtra por título, sin tildes ni mayúsculas; `Enter` vuelve a la
  lista con el filtro, `Esc` lo limpia). En un campo, `Esc` vuelve a la lista.
- En la lista, `Esc` (o ⌥T otra vez) cierra y te devuelve a la ventana donde estabas (`aerospace focus
  --window-id`, tomada con `hs.window.frontmostWindow()` antes de mostrar el panel). Perder el foco por un clic
  afuera solo cierra.

### Estados de una tarea

```
  anotada en el widget ──> sin agente («Copiar para Claude»)
                                 │  el agente corre `myturn link <id>`
                                 ▼
         herdr: working ─────────────────────> trabajando…        (gris)
         herdr: idle/blocked  & no visto ────> TE ESPERA          (verde, sonido 1× por transición)
         herdr: idle/blocked  & visto ───────> ya lo viste        (blanco)
         la sesión desaparece ───────────────> agente cerrado     («Reabrir agente» = claude --resume)
  ✓ hecha · ✕ archivada (reversible)
```

- **Visto** = después de la última transición, el pane estuvo enfocado en herdr *y* la ventana de herdr al frente
  (muestreo cada 20 s), o llegaste por ⌥G / «Ir al agente» (inmediato).
- **Orden**: primero las que te esperan (la que espera hace más tiempo arriba), luego por prioridad, fecha y
  antigüedad.

### Piezas

| Pieza | Archivo |
|---|---|
| CLI, store, estados, foco, poda | `scripts/tk` (→ `~/.local/bin/tk` en ambas cajas) |
| Hook de registro | `myturn track` en `UserPromptSubmit` (`shared/claude/settings.template.json`) |
| Barra (etiqueta + clic abre el panel) | `macos/sketchybar/.config/sketchybar/items/myturn.sh` + `plugins/myturn.sh` |
| Panel del widget (clic / ⌥T) y salto ⌥G | `macos/hammerspoon/.hammerspoon/myturn.lua` + `myturn-panel.html` (webview: sketchybar no tiene campos de texto) |
| Skill para agentes | `shared/claude/skills/myturn/SKILL.md` |
| Espejo en Obsidian | `myturn obsidian` + `linux/myturn/.config/systemd/user/myturn-obsidian.{service,timer}` (Arch, cada minuto) |
| Datos | repo privado `A-PachecoT/tasks` en `~/tasks` (`events.jsonl`; `state.json` derivado) |
| Caché | `~/.cache/myturn/` (estados vistos, avisos dados, última poda) |
| Tests | `scripts/tests/test_myturn.py` |

### Integraciones

| Con qué | Cómo |
|---|---|
| herdr | `agent list` (estado, `focused`, `terminal_title`), `agent focus`, `tab create`, `pane run`, `pane current` |
| AeroSpace | `list-windows` / `focus --window-id` sobre las ventanas `herdr-mac` y `herdr-arch` |
| Claude Code | hook `UserPromptSubmit` (session_id + `HERDR_PANE_ID`); `claude -p --json-schema` para la IA |
| Obsidian (BrainFlow) | `Tareas.md` espejo + consulta ```tasks``` en el daily note + importación de `- [ ]` del To-do; `daily_prep.py` y morning-brief (Hermes) parcheados |
| Vikunja, calendario, celular | fuera de alcance por ahora |

## Mantener myturn

Todo cambio sigue este loop; cierra con los tests en verde, commit + push de dotfiles y la bitácora.

| Tocas | Verifica / despliega |
|---|---|
| `scripts/myturn` | `uv run --with pytest pytest scripts/tests/` y `ruff check --select E,F,I,B --line-length 120 scripts/myturn` (gates: córrelos solos, sin pipes). Mac: nada más (el symlink ya apunta al repo). Arch: `ssh andre-arch 'cd ~/dotfiles && git pull --rebase'` |
| La barra (`items/myturn.sh`, `plugins/myturn.sh`) | `sketchybar --reload`. Archivo nuevo en el paquete → `cd ~/dotfiles/macos && stow -R -t ~ sketchybar` (los links son por archivo) |
| El panel (`myturn.lua`, `myturn-panel.html`) | recarga Hammerspoon **en segundo plano**: `(perl -e 'alarm 4; exec @ARGV' hs -c 'hs.reload()' >/dev/null 2>&1 &)` — un `hs -c 'hs.reload()'` normal se cuelga. Abrir: `open -g hammerspoon://myturn-panel`. Probar sin clics: `hs -c 'require("myturn").eval([[document.title]])'` → resultado en `~/.cache/myturn/panel.log` |
| El sync con Obsidian | en el Arch: `myturn obsidian` (una pasada, imprime qué hizo); `journalctl --user -u myturn-obsidian -n 20`; `systemctl --user list-timers myturn-obsidian.timer` |
| El hook | `echo '{"session_id":"x"}' \| myturn track` no debe imprimir nada |
| Hermes (`daily_prep.py`, morning-brief) | están en `~/.hermes` del Arch (repo git propio); un cambio ahí se commitea allá y se anota en el pitfall 2026-10-06 del morning-brief |

**Dónde mirar cuando algo no cuadra:** `myturn ls` (estado real), `~/tasks/state.json` (lo último que vio la barra),
`~/.cache/myturn/seen.json` (transiciones y «visto» por sesión), `~/.cache/myturn/panel.log` (mensajes y errores del
panel), `~/.cache/myturn/obsidian-last.json` (lo último escrito en Tareas.md).

**Invariantes que no se rompen:** el store es append-only y se deriva ordenando por `ts`; solo el Arch escribe
`Tareas.md`; nada se borra (archivar/`[>]`); el hook no imprime; la UI no muestra las sesiones que el hook registró sin
tarea.


## Validación

- 2026-10-05, MVP v0 (lista con enlace manual): 6 smoke tests; captura → IA → git → popup verificados en vivo. Su
  revisión del flujo con André encontró los 5 huecos que motivaron esta versión (enlace manual, «tu turno»
  pegado, una sola tarea de ahora, aviso silencioso, sin teclado).

- 2026-10-05, v1: 12 smoke tests (visto/pausa/nueva transición, foco sin ventana al frente no cuenta, sin prio
  nunca interrumpe, orden de la cola, agente cerrado → pendientes, hook registra 1× y descarta sesiones ajenas,
  hook fuera de herdr = no-op, hook nunca rompe, poda de sesiones, merge intercalado) + ruff. En vivo: el hook no
  imprime nada; `import` registró 66 sesiones en el Mac y 16 en el Arch; un agente idle priorizado entró a
  «te espera», sonó una vez (`notified`) y la popup lo mostró en el monitor externo.

- 2026-10-06, v1.2 (panel): 13 smoke tests + ruff. En vivo, en el panel: agregar (con y sin prioridad), rotar
  prioridad, editar con doble clic, «Copiar para Claude» (portapapeles verificado) y ✓; se abre por URL
  `hammerspoon://myturn-panel` y toma el foco. Gotchas: un número de JS llega a Lua como `1.0` (usa
  `string.format("%d")`); el foco hay que pedirlo con un timer después de `show()`; `print` dentro de un callback
  de `evaluateJavaScript` lanzado desde `hs -c` revienta el IPC.

- 2026-10-06, Obsidian: 17 smoke tests (importar del daily con padre de reunión, idempotencia y sin duplicar lo
  copiado de ayer; ida y vuelta de Tareas.md con [x]/edición/línea nueva; la edición del widget gana sobre una
  línea sin tocar; gate ocupado = no escribe). En vivo: primera pasada importó 8 pendientes del To-do (y rescató
  «Melissa», que una edición manual de Hermione había borrado de la nota de hoy); ciclo widget → Obsidian → [x] →
  myturn verificado en el Mac.

- 2026-10-09, panel lento y sin scroll: con 23 tareas el panel medía 1210 px en una pantalla de 1080 (`overflow:
  hidden`, lo de abajo quedaba fuera); y cada clic recalculaba con ssh al Arch, hasta 6 s por llamada cuando la red
  tarda, sin cachear el fallo. Ahora el panel topa con la pantalla y la lista scrollea; lo remoto se sirve del caché
  y se renueva en segundo plano (`_agents`; >10 min = la otra caja no responde; `go` sí lee en el acto); los botones
  cambian la UI al instante; el webview se crea al cargar Hammerspoon. 18 smoke tests + ruff; medido en vivo. Luego, el congelamiento real de ~1 s era
  `panel:hswindow():focus()` (accesibilidad, 1,6 s medidos): ahora `hs.focus()` + `show()`; y hay skeleton + barra de
  carga. Prueba de foco: `hs.eventtap.keyStrokes` y leer el input (`document.hasFocus()` miente).

- 2026-10-09, teclado del panel: en vivo, la lógica de hjkl/n/f/edición/Esc con eventos de teclado sintéticos
  (`require("myturn").eval`), las teclas físicas (`hs.eventtap.keyStroke`) mueven la selección, y Esc devuelve el
  foco de Hammerspoon a Ghostty. Gotcha: `hs.eventtap.keyStroke({"alt"},"t")` no dispara el hotkey del propio
  Hammerspoon (prueba con `require("myturn").show()`); y las teclas físicas llegan con retraso respecto del `eval`.

## Roadmap

- **v1:** registro automático por hook, cola con visto, ⌥G, sonido por transición, importación única de las
  sesiones existentes, poda de sesiones muertas.
- **v1.2 (esta, 2026-10-06):** el widget es la UI completa (panel webview): anotar, editar, prioridad, copiar para
  Claude + `myturn link`, ir/reabrir agente, ✓/✕. ⌥T abre el widget.
  2026-10-05 noche: André no entendía la paleta ⌥T ni los clics («no entiendo nada») — mezclaba captura,
  acciones sobre un agente invisible y la lista; con seis estados de jerga. Se redujo a un concepto, una tecla
  por acción y un clic que siempre hace lo mismo (mockup aprobado por él).
- **v2:** la IA lee al agente que te espera (`herdr agent read`) y resume en el popup qué hizo y qué te pide.
- **v3:** captura desde el celular; contexto de calendario.
- **OSS:** repo propio con el nombre final, instalador sin dotfiles (Homebrew/uv), sin rutas de André.
