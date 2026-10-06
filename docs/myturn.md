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

- **Es** una cola de retorno: «estos agentes te esperan, en este orden». Lo secundario: una lista corta de
  pendientes sueltos (sin agente) que se poda sola.
- **No es** un gestor de proyectos ni de equipo (eso es Vikunja), ni un orquestador de agentes (eso es herdr y
  `/cto`), ni un lugar donde planificar. Si tienes que abrir myturn para *mantenerlo*, falló.

### El flujo, de punta a punta

1. **Lanzas un agente como siempre** (un pane de herdr, escribes el prompt). Un hook de Claude Code lo registra
   solo; el título es el que Claude Code ya le pone a la sesión. Cero ceremonia.
2. **Marcas lo que importa** con ⌥T → «★ prioridad: <agente enfocado>». Lo no marcado se rastrea en silencio y
   nunca te interrumpe.
3. **Te vas a otra cosa.** Cuando un agente prioritario termina o te pregunta algo (idle/blocked) y no lo has visto,
   entra a la cola **te esperan**, suena una vez y la barra se pone verde: `● 2 te esperan: Fix webhook Fovente`.
4. **⌥G te lleva al siguiente** que te espera (ventana de herdr + pane). Mirarlo cuenta como visto: sale de la
   cola hasta su próximo cambio de estado.
5. **Terminas**: ⌥T → «✓ hecha», o cierras el pane. Lo que muere solo (sin prioridad, idle >12 h o sesión cerrada)
   lo archiva el jardinero; todo es reversible.

### Principios

1. **La sesión es la unidad.** Una tarea con agente *es* su sesión de Claude (el id de sesión que herdr expone),
   no un ítem que alguien tiene que mantener enlazado. Las capturas sueltas (⌥T) son el caso secundario.
2. **Solo interrumpe lo que marcaste.** Prioridad = permiso para interrumpir. El resto existe pero calla.
3. **Visto apaga la alarma.** Un agente idle que ya miraste no es «te espera»; vuelve a serlo solo con una
   transición nueva (respondiste, trabajó, terminó otra vez).
4. **Teclado primero.** Dos teclas globales (⌥T paleta, ⌥G siguiente; ⌥N no, en US International-PC es la ñ); el popup de la barra es para mirar, no
   para operar.
5. **El código escribe el porqué; la IA, solo donde hay juicio.** Títulos: los de Claude Code. Estados: los de
   herdr. La IA (`claude -p`) queda para lo ambiguo: fechas y prioridad en capturas sueltas, poda y (v2) resumir
   qué hizo el agente que te espera.
6. **Nada se borra.** Podar = archivar con razón; `myturn restore`.
7. **Local-first, sin servidor.** Un repo git privado con un log append-only (`merge=union`) sincroniza el Mac y
   el Arch; herdr de la otra caja se lee por ssh.

## Diseño

### Estados de una tarea con agente

```
                  hook (1.er prompt)            prio marcada
  (sesión nueva) ───────────────────> rastreada ────────────> prioritaria
                                                                  │
         herdr: working ──────────────────────> trabajando  <─────┤
         herdr: idle/blocked  & no visto ─────> TE ESPERA  ───────┤  (sonido 1× por transición)
         herdr: idle/blocked  & visto ────────> en pausa  ────────┘
         sesión desaparece ───────────────────> agente cerrado (prio: queda en pendientes; sin prio: archivada)
```

- **Visto** = después de la última transición, el pane estuvo enfocado en herdr *y* la ventana de herdr al frente
  (muestreo cada 20 s), o llegaste por ⌥G / clic (inmediato).
- **Orden de la cola**: prioridad (1 antes que 2), luego quien espera hace más tiempo.

### Piezas

| Pieza | Archivo |
|---|---|
| CLI, store, estados, foco, poda | `scripts/tk` (→ `~/.local/bin/tk` en ambas cajas) |
| Hook de registro | `myturn track` en `UserPromptSubmit` (`shared/claude/settings.template.json`) |
| Barra y popup | `macos/sketchybar/.config/sketchybar/items/myturn.sh` + `plugins/myturn.sh` |
| Paleta ⌥T y salto ⌥G | `macos/hammerspoon/.hammerspoon/myturn.lua` |
| Skill para agentes | `shared/claude/skills/myturn/SKILL.md` |
| Datos | repo privado `A-PachecoT/tasks` en `~/tasks` (`events.jsonl`; `state.json` derivado) |
| Caché | `~/.cache/myturn/` (estados vistos, avisos dados, última poda) |
| Tests | `scripts/tests/test_myturn.py` |

### Integraciones

| Con qué | Cómo |
|---|---|
| herdr | `agent list` (estado, `focused`, `terminal_title`), `agent focus`, `tab create`, `pane run`, `pane current` |
| AeroSpace | `list-windows` / `focus --window-id` sobre las ventanas `herdr-mac` y `herdr-arch` |
| Claude Code | hook `UserPromptSubmit` (session_id + `HERDR_PANE_ID`); `claude -p --json-schema` para la IA |
| Vikunja, calendario, celular | fuera de alcance por ahora |

## Validación

- 2026-10-05, MVP v0 (lista con enlace manual): 6 smoke tests; captura → IA → git → popup verificados en vivo. Su
  revisión del flujo con André encontró los 5 huecos que motivaron esta versión (enlace manual, «tu turno»
  pegado, una sola tarea de ahora, aviso silencioso, sin teclado).

## Roadmap

- **v1 (esta):** registro automático por hook, cola «te esperan» con visto, ⌥G, sonido por transición, paleta ⌥T
  (prioridad / hecha sobre el agente enfocado), importación única de las sesiones existentes, poda de sesiones
  muertas.
- **v2:** la IA lee al agente que te espera (`herdr agent read`) y resume en el popup qué hizo y qué te pide.
- **v3:** captura desde el celular; contexto de calendario.
- **OSS:** repo propio con el nombre final, instalador sin dotfiles (Homebrew/uv), sin rutas de André.
