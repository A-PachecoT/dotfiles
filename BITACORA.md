# Bitacora: dotfiles

**Creada:** 2026-06-01
**Tipo:** general
**Contexto:** Dotfiles multi-plataforma para macOS daily driver, Arch Linux daily driver y sandbox de desarrollo Linux remoto.

---

## Estado Actual

El repo ya tiene split `shared/`, `macos/`, `linux/` y scripts planos, pero macOS sigue siendo la implementacion mas completa.
Arch daily driver existe como capa HyDE/Hyprland parcial: falta bootstrap reproducible y paridad de UX personal.
El dev sandbox Mac -> Arch via ET/tmux ya tiene bridge de clipboard bidireccional: texto funciona por `mac-clipboard`, `clip-copy`, `clip-paste`, y shims scoped para Claude Code; imagenes funcionan nativamente en Claude Code via shims y por path en Codex via `clip-img`.
Yazi ya abre archivos de texto con `nvim` desde el launcher compartido `y()`, sin depender de `EDITOR` externo.
El box Arch quedó **endurecido contra OOM** (2026-07-04): `systemd-oomd` + caps de memoria en los 9 runners + idle-reap de `agent-browser`; el CI de las 3 landings migró a GitHub-hosted para desacoplar la salud del box de cada push del agente.
La Mac ya tiene **auto-resume de Claude tras reboot** (2026-07-04, `tmux-assistant-resurrect`, `@continuum-save-interval`=1min) y `dev-startup.sh` fue reescrito para **descubrimiento dinámico de sesiones tmux** (local vía snapshot de resurrect, remoto vía SSH al Arch box) con asignación estable de workspaces AeroSpace, reemplazando el modelo viejo de 4 sesiones hardcodeadas.
**Herdr en trial** (2026-07-14) en paralelo a tmux: config compartido en `shared/herdr/`, server en ambos workers, keybinds 1:1 vía el passthrough Ghostty existente. Decisión de migración pendiente (validar sidebar de agentes vs Claude Pending System).
**Device mesh 4-way activo** (2026-07-14): SSH full-mesh sobre Tailscale entre Mac, Arch, celu y tablet (matriz 12/12, key por dispositivo). Transporte estándar: **ET** (touch ✓ + reconexión ✓; mosh rompe el mouse). Aliases únicos `h`/`ha` en las 4 cajas. Ver `docs/device-mesh.md`.
Siguiente foco: cerrar el trial de Herdr, mantener fixes cross-platform en `shared/` y empaquetar health checks/setup replicable para el dev sandbox.

---

## Reglas Extraidas

- **Separar Arch daily driver de dev sandbox evita mezclar UX Hyprland con requisitos headless/remotos.** - source: [roadmap](bitacora/2026-06-01-roadmap-arch-linux-dev-sandbox.md)
- **Todo script compartido debe degradar por plataforma antes de llamarse desde tmux/zsh compartido.** - source: [roadmap](bitacora/2026-06-01-roadmap-arch-linux-dev-sandbox.md)
- **El sandbox replicable necesita health check ejecutable, no solo documentacion.** - source: [roadmap](bitacora/2026-06-01-roadmap-arch-linux-dev-sandbox.md)
- **Los defaults de herramientas TUI compartidas deben fijarse en el launcher shared cuando shells remotos pueden traer variables host-specific.** - source: [yazi nvim shared launcher](bitacora/2026-06-01-yazi-nvim-shared-launcher.md)
- **Para clipboard remoto, preferir shims scoped al proceso antes que reemplazar binarios globales.** - source: [clipboard bridge](bitacora/2026-06-01-clipboard-bridge-mac-arch.md)
- **Codex necesita flujo por archivo para imagenes hasta que exponga un hook de clipboard externo.** - source: [clipboard bridge](bitacora/2026-06-01-clipboard-bridge-mac-arch.md)
- **Sobre tmux+ET+Ghostty el transporte aguanta gráficos Kitty de placement directo y texto, pero NO unicode-placeholders ni sixel.** - source: [yazi image preview remoto](bitacora/2026-06-16-yazi-image-preview-remote.md)
- **Un previewer que sondea el terminal (`chafa` abre `/dev/tty`) compite con el TUI padre por el stdin; desactivar el sondeo (`--probe=off`) evita que respuestas-escape se cuelen como teclas.** - source: [yazi image preview remoto](bitacora/2026-06-16-yazi-image-preview-remote.md)
- **`agent-browser` persiste el browser indefinidamente salvo que se setee `AGENT_BROWSER_IDLE_TIMEOUT_MS`; en runs autónomas largas los browsers se fugan y agotan RAM.** - source: [OOM freeze hardening](bitacora/2026-07-04-oom-freeze-hardening.md)
- **En el box headless, `systemd-oomd` (PSI/cgroup-aware) es obligatorio: el OOM-killer del kernel llega tarde en cargas anon-heavy y produce livelock.** - source: [OOM freeze hardening](bitacora/2026-07-04-oom-freeze-hardening.md)
- **Atribuir un OOM por el cgroup del victim (`task_memcg`) separa al leaker real de la víctima antes de culpar al proceso equivocado.** - source: [OOM freeze hardening](bitacora/2026-07-04-oom-freeze-hardening.md)
- **CI self-hosted acopla la salud del hardware a cada push del agente; migrar a hosted lo desacopla (cuando el billing lo permite).** - source: [OOM freeze hardening](bitacora/2026-07-04-oom-freeze-hardening.md)
- **Un guardián por CPU no cubre leaks por RAM, y un unit symlinkeado sin `enable --now` es no-op (`chrome-guardian`).** - source: [OOM freeze hardening](bitacora/2026-07-04-oom-freeze-hardening.md)
- **`aerospace move-node-to-workspace` sin `--window-id` actúa sobre la ventana con foco actual, no la recién creada — es una carrera real, no teórica.** - source: [tmux dynamic session restore](bitacora/2026-07-04-dynamic-tmux-session-restore.md)
- **Nunca llamar un binario con IPC propio (ej. `aerospace`) dentro de un `while read` alimentado por pipe: puede drenarle el stdin al loop sin error visible.** - source: [tmux dynamic session restore](bitacora/2026-07-04-dynamic-tmux-session-restore.md)
- **Un conteo de reintentos no reemplaza un timeout real: si la llamada puede colgarse indefinidamente (aerospace↔SketchyBar deadlock), hace falta matar por PID tras un plazo, no solo reintentar.** - source: [tmux dynamic session restore](bitacora/2026-07-04-dynamic-tmux-session-restore.md)
- **Ante señal ambigua de posible pérdida de datos en una máquina con actividad concurrente real, parar y preguntar es más rápido y correcto que seguir investigando en soledad.** - source: [tmux dynamic session restore](bitacora/2026-07-04-dynamic-tmux-session-restore.md)
- **Si mueren solo los hotkeys `Option`+tecla-que-produce-carácter (y sobreviven `Option+Tab`/`Ctrl+x`), el culpable es un campo de texto con el foco del teclado, no un conflicto de hotkeys.** - source: [alt hotkeys muertos](bitacora/2026-07-09-alt-hotkeys-dead-obsidian-password-field.md)
- **macOS prohíbe enumerar los hotkeys Carbon de otra app (`SLSGetHotKey` → `1002 kCGErrorInvalidConnection`); el mapa hay que reconstruirlo desde las configs.** - source: [alt hotkeys muertos](bitacora/2026-07-09-alt-hotkeys-dead-obsidian-password-field.md)
- **Secure Input ciega los event taps (ven `flagsChanged`, nunca `keyDown`) pero NO bloquea los hotkeys Carbon; confundir ambas capas cuesta horas.** - source: [alt hotkeys muertos](bitacora/2026-07-09-alt-hotkeys-dead-obsidian-password-field.md)
- **AeroSpace re-ejecuta `after-startup-command` en cada reinicio del WM, no solo en boot: todo script de arranque que lance ventanas debe ser idempotente.** - source: [alt hotkeys muertos](bitacora/2026-07-09-alt-hotkeys-dead-obsidian-password-field.md)
- **Cuando el usuario contradice una hipótesis desde su experiencia ("siempre lo usé así"), esa objeción es evidencia, no ruido.** - source: [alt hotkeys muertos](bitacora/2026-07-09-alt-hotkeys-dead-obsidian-password-field.md)
- **mosh no pasa mouse-tracking (virtual terminal propio); para TUIs mouse-first en remoto/móvil usar ET: passthrough fiel + reconexión automática.** - source: [herdr trial + mesh](bitacora/2026-07-14-herdr-trial-device-mesh.md)
- **Todo binario que deba resolverse en shells no-interactivos (`ssh host cmd`, `et -c`) va en `.zshenv`, no en `.zshrc`.** - source: [herdr trial + mesh](bitacora/2026-07-14-herdr-trial-device-mesh.md)
- **Credential helpers de git son platform-specific: van per-box en `~/.config/git/config` (XDG, no stowed), jamás en el `.gitconfig` de `shared/`.** - source: [herdr trial + mesh](bitacora/2026-07-14-herdr-trial-device-mesh.md)
- **`connection refused` = host vivo sin listener; `timeout` = capa de red (en Android: Tailscale dormido — batería sin restricciones para Termux Y Tailscale).** - source: [herdr trial + mesh](bitacora/2026-07-14-herdr-trial-device-mesh.md)
- **El `pkg install` de Termux se come las líneas pegadas después: los bloques de setup móvil van siempre en 2 pastes (install / configure).** - source: [herdr trial + mesh](bitacora/2026-07-14-herdr-trial-device-mesh.md)
- **`nohup … &` dentro de `ssh host '…'` muere con la sesión; usar `setsid` para desacoplar de verdad.** - source: [herdr trial + mesh](bitacora/2026-07-14-herdr-trial-device-mesh.md)

---

## Entries

| Fecha | Titulo | Resumen |
|-------|--------|---------|
| 2026-06-01 | [Clipboard bridge Mac -> Arch](bitacora/2026-06-01-clipboard-bridge-mac-arch.md) | Implementa bridge de clipboard por SSH, shims scoped para Claude Code y helpers manuales para texto/imagenes. |
| 2026-06-01 | [Yazi nvim shared launcher](bitacora/2026-06-01-yazi-nvim-shared-launcher.md) | Fija `nvim` para `yazi` desde `shared/zsh/tmux-workflow.zsh` y pushea el fix DRY a `main`. |
| 2026-06-01 | [Roadmap Arch Linux + dev sandbox](bitacora/2026-06-01-roadmap-arch-linux-dev-sandbox.md) | Divide el trabajo en Arch daily driver y sandbox Linux replicable, con prioridades para multiples sesiones. |
| 2026-06-16 | [Yazi image preview remoto](bitacora/2026-06-16-yazi-image-preview-remote.md) | Previewer chafa (sextantes) + visor on-demand Kitty (`i`) para que las imágenes se vean sobre tmux+ET+Ghostty; fija el modal "Find next:" con `chafa --probe=off`. |
| 2026-07-04 | [OOM freeze hardening](bitacora/2026-07-04-oom-freeze-hardening.md) | Box se congeló ~3am por livelock OOM (CTO nocturno fugó browsers headless + CI en cada push). Fixes: systemd-oomd, MemoryMax en runners, idle-reap de agent-browser, y migración de 3 landings a GitHub-hosted. |
| 2026-07-04 | [tmux dynamic session restore](bitacora/2026-07-04-dynamic-tmux-session-restore.md) | Instala `tmux-assistant-resurrect` en la Mac (auto-resume de Claude tras reboot, merge aditivo validado) y reescribe `dev-startup.sh` para descubrimiento dinámico de sesiones (local + Arch remoto) con workspaces AeroSpace estables. Rehearsal en vivo encontró y arregló 3 bugs reales (carrera de foco, pipe que come stdin, deadlock aerospace↔SketchyBar). |
| 2026-07-09 | [Alt hotkeys muertos: campo de contraseña de Obsidian](bitacora/2026-07-09-alt-hotkeys-dead-obsidian-password-field.md) | Los `alt+` de AeroSpace morían porque un prompt de contraseña de Obsidian retenía el foco del teclado y se tragaba `Option`+carácter como texto. Se descartaron 6 hipótesis con evidencia (Secure Input, Karabiner, teclado AULA, superwhisper, layout, conflicto Carbon). Ship: `hotkey-inventory.py`, `hotkey-canary.sh`, y `dev-startup.sh` idempotente. |
| 2026-07-14 | [Herdr trial + device mesh 4-way](bitacora/2026-07-14-herdr-trial-device-mesh.md) | Evaluación Herdr vs tmux → trial paralelo con keybinds 1:1 (gratis vía el passthrough Ghostty). Touch móvil moría con mosh (no pasa mouse-tracking); ET lo resuelve + reconecta solo. Mesh SSH 12/12 entre Mac/Arch/celu/tablet sobre Tailscale, herdr en ambos workers, aliases `h`/`ha` únicos, y fix de raíz al ping-pong del `.gitconfig` (credential helper per-box en XDG). Ship: `shared/herdr/`, `mesh.zsh`, `.zshenv`, `termux-bootstrap.sh`, `docs/device-mesh.md`. |
