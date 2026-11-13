# Agent teams en la Herdr app: tmux falso (2026-11-13)

**Problema.** `cl` lanza claude con `--teammate-mode tmux`, pero en una terminal de herdr-core no hay tmux: los teammates de agent teams corrían escondidos dentro del líder, sin panel y sin aviso. André evaluó herdmates (caioniehues/herdmates) para esto, pero ese plugin habla con el TUI viejo (herdr ≥0.7.4 `herdr pane`), del que salimos el 2026-11-12.

**Fix.** `scripts/hc-tmux/tmux`: un tmux falso en Python que `cl` pone primero en el PATH (con `TMUX=hc-tmux,0,0`, `TMUX_PANE=%0`) solo si hay `HC_TERMINAL_ID` + `HC_TERMINAL_SOCKET` + `herdr-app`, y no hay TUI ni tmux real. Traduce: `split-window` → `herdr-app do pane.split` (el primero a la derecha del líder, los demás hacia abajo: emula `main-vertical`), `respawn-pane` → arranca el teammate (el split con `cat` es un placeholder), `kill-pane` → `pane.close`, `send-keys`/`capture-pane` → `hc send|keys|read`; estilos, layout y resize son no-op. Un verbo desconocido sale 1 y queda en el log. El mapa de verbos salió de la investigación de herdmates.

**Hallazgos.**
- `pane.split` **enfoca el panel nuevo** si la pestaña está a la vista; Claude pide `-d`, así que el shim devuelve el foco al panel anterior.
- Claude 2.1.325 pide `-h` también entre teammates (el tercero) y luego `select-layout main-vertical`; sin layouts en la app, el shim fuerza «abajo» para todo lo que no parte del líder.
- La app no deja fijar el tamaño al partir: queda 50/50 en vez de 30/70.
- `herdr-app shot` da el último frame dibujado: si la ventana no está a la vista, sale una captura vieja.

**Verificá:** `uv run --with pytest pytest scripts/tests/test_hc_tmux.py` (11 casos, con un `herdr-app`/`hc` falsos) y el log por líder en `~/.local/state/hc-tmux/<terminal>-<epoch>.log`. Corrida real: 3 equipos (2 y 3 teammates, haiku) se abrieron, respondieron y se cerraron como paneles; estado final `{'%1': right %0, '%2': down %1, '%3': down %1}`.

## Después: upstream y el «working» eterno

- Pedido nativo a herdr (en vez de publicar `hc-tmux` como repo propio): herdrdev/herdr-core#272. El feedback in-app no sale desde un build de fuente.
- **El líder queda «working» en Herdr mientras el equipo vive**, aunque todos estén idle. No es el shim: Claude Code emite el estado por OSC 7501 (`app=claude-code`) y cuenta los teammates de panel como trabajo; a los `in_process_teammate` idle sí los excluye. Probado: con el teammate vivo `hc get` → `working`; tras apagarlo → `done`. Reportado: anthropics/claude-code#109722. Workaround: que el líder apague el equipo al terminar.
