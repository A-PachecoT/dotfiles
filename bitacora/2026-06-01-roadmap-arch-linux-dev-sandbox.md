# 2026-06-01 - Roadmap Arch Linux + dev sandbox

**Operador:** Codex

---

## Contexto

El usuario pidio revisar brutalmente que features de macOS faltaban migrar a Arch Linux. Luego separo dos lineas de trabajo:

1. Arch Linux como daily driver.
2. Linux/Arch como dev sandbox handoffeable, replicando el flujo de desarrollo que hoy funciona desde macOS.

No habia bitacora previa del repo. La memoria durable local tampoco tenia rollout history util; solo indicaba estado bootstrap vacio.

---

## Que Paso

Se audito el repo actual sin modificar las configs funcionales. Hallazgos principales:

- `macos/` contiene la implementacion mas madura: AeroSpace, SketchyBar, Hammerspoon, Brewfile y bootstrap.
- `linux/` contiene una capa HyDE/Hyprland parcial: Hyprland prefs, Waybar, Dunst, Kitty y zsh HyDE.
- `shared/` contiene la base real reutilizable: tmux, zsh workflow, yazi, nvim, git, starship, zellij, Claude settings.
- Varios scripts compartidos todavia asumen macOS: `claude-notify`, `claude-jump`, `smart-open.sh` y partes de `.tmux.conf`.
- El flujo Mac -> Arch dev sandbox ya tiene piezas: Eternal Terminal setup, `etc`, OSC52, tmux, `cl`, clipboard shims y `mac-clipboard`.
- Ese flujo todavia no esta empaquetado como sandbox reproducible: falta bootstrap, health check, backends por plataforma y documentacion operativa.

### Roadmap A - Dev sandbox Linux handoffeable

Prioridad alta porque desbloquea trabajo remoto/multi-sesion sin depender de recordar estado manual.

| Orden | Tarea | Resultado esperado | Estado |
|---:|---|---|:---:|
| 1 | Crear `install.sh sandbox` o `linux/dev-sandbox-bootstrap.sh` | Instala dependencias server: ET, tmux, yazi, nvim, fzf, rg, fd, bat, eza, zoxide, jq, git-delta, node, Claude/Codex prereqs, TPM | Pendiente |
| 2 | Crear `scripts/dev-sandbox-health` | Verifica ET server, terminfo, tmux, TPM plugins, Claude hooks, clipboard text/image, OSC52, `tw .`, `cl` | Pendiente |
| 3 | Separar backends por plataforma | `notify`, `workspace-switch`, `clipboard`, `open-url/open-file` con macOS, Linux GUI y headless | Pendiente |
| 4 | Hacer `claude-notify` portable | macOS usa `say/afplay/sketchybar`; Linux usa `notify-send/paplay` o tmux-only; headless no bloquea | Pendiente |
| 5 | Hacer `claude-jump` portable | macOS usa AeroSpace; Hyprland usa `hyprctl`; headless usa solo `tmux switch-client` | Pendiente |
| 6 | Hacer `smart-open.sh` portable | Reemplazar `pbcopy/open` por backend clipboard/open; yazi sigue siendo destino preferido | Pendiente |
| 7 | Crear startup tmux puro | Crea/restaura sesiones `cofoundy`, `bilio`, `personal`, `notes` sin Ghostty/AeroSpace | Pendiente |
| 8 | Documentar cliente macOS | ET client, Tailscale/SSH, `CLIP_REMOTE`, `pngpaste`, reverse SSH assumptions, troubleshooting | Pendiente |

### Roadmap B - Arch Linux daily driver

Prioridad media; importante para vivir en Arch, pero no bloquea el sandbox headless.

| Orden | Tarea | Resultado esperado | Estado |
|---:|---|---|:---:|
| 1 | Crear bootstrap Arch daily | Pacman/yay deps, fonts, HyDE adjuncts, clipboard tools, Waybar/Dunst/Kitty prereqs | Pendiente |
| 2 | Completar Hyprland keybindings personales | Paridad con AeroSpace: focus/move/resize/workspaces/launchers/reload/work-session | Pendiente |
| 3 | Portar workspace routing | Reglas Hyprland para browser, terminal, obsidian, cursor, chat apps y sesiones tmux | Pendiente |
| 4 | Waybar custom modules | Claude pending, active session, work-session, theme/status, audio/mic state | Pendiente |
| 5 | Reemplazar Hammerspoon features | PipeWire/WirePlumber audio priority, mic mute, screenshot workflow, PDF workflow, sleep/wake hooks | Pendiente |
| 6 | Terminal parity | Decidir Kitty vs Ghostty en Linux y replicar keybinds de tmux/window workflow | Pendiente |
| 7 | Corregir scripts referenciados que faltan | `temp-up.sh`, `temp-down.sh`, `brightness-up.sh`, `brightness-down.sh` o remover binds | Pendiente |

### Criterio de exito

Dev sandbox queda "handoffeable" cuando una maquina Linux limpia puede correr un comando bootstrap, pasar `dev-sandbox-health`, abrir/adjuntar tmux sessions, ejecutar Claude/Codex, copiar/pegar texto e imagen desde el cliente Mac, y navegar pending Claudes sin depender de AeroSpace.

Arch daily driver queda "usable" cuando `./install.sh install` + bootstrap deja Hyprland/Waybar/terminal/notificaciones/clipboard con los bindings y workflows personales principales sin depender de estado HyDE no versionado.

---

## Aprendizaje

- Separar Arch daily driver de dev sandbox evita mezclar UX Hyprland con requisitos headless/remotos.
- Todo script compartido debe degradar por plataforma antes de llamarse desde tmux/zsh compartido.
- El sandbox replicable necesita health check ejecutable, no solo documentacion.

---

## Accion

- Se creo `BITACORA.md` como brain del repo.
- Se creo esta primera entrada con el roadmap operativo.
- Se registro la regla de mantenimiento de bitacora en `CLAUDE.md`.
