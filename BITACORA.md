# Bitacora: dotfiles

**Creada:** 2026-06-01
**Tipo:** general
**Contexto:** Dotfiles multi-plataforma para macOS daily driver, Arch Linux daily driver y sandbox de desarrollo Linux remoto.

---

## Estado Actual

El repo ya tiene split `shared/`, `macos/`, `linux/` y scripts planos, pero macOS sigue siendo la implementacion mas completa.
Arch daily driver existe como capa HyDE/Hyprland parcial: falta bootstrap reproducible y paridad de UX personal.
El dev sandbox Linux existe como flujo Mac -> Arch via ET/tmux/clipboard bridge, pero no esta empaquetado como setup replicable.
Yazi ya abre archivos de texto con `nvim` desde el launcher compartido `y()`, sin depender de `EDITOR` externo.
Siguiente foco: mantener fixes cross-platform en `shared/` y estabilizar el dev sandbox handoffeable.
Hay cambios no relacionados sin commit en `shared/nvim/.config/nvim/lazy-lock.json`, `shared/zsh/tmux-workflow.zsh`, `scripts/claude-clipboard-shims/` y `scripts/mac-clipboard`.

---

## Reglas Extraidas

- **Separar Arch daily driver de dev sandbox evita mezclar UX Hyprland con requisitos headless/remotos.** - source: [roadmap](bitacora/2026-06-01-roadmap-arch-linux-dev-sandbox.md)
- **Todo script compartido debe degradar por plataforma antes de llamarse desde tmux/zsh compartido.** - source: [roadmap](bitacora/2026-06-01-roadmap-arch-linux-dev-sandbox.md)
- **El sandbox replicable necesita health check ejecutable, no solo documentacion.** - source: [roadmap](bitacora/2026-06-01-roadmap-arch-linux-dev-sandbox.md)
- **Los defaults de herramientas TUI compartidas deben fijarse en el launcher shared cuando shells remotos pueden traer variables host-specific.** - source: [yazi nvim shared launcher](bitacora/2026-06-01-yazi-nvim-shared-launcher.md)

---

## Entries

| Fecha | Titulo | Resumen |
|-------|--------|---------|
| 2026-06-01 | [Yazi nvim shared launcher](bitacora/2026-06-01-yazi-nvim-shared-launcher.md) | Fija `nvim` para `yazi` desde `shared/zsh/tmux-workflow.zsh` y pushea el fix DRY a `main`. |
| 2026-06-01 | [Roadmap Arch Linux + dev sandbox](bitacora/2026-06-01-roadmap-arch-linux-dev-sandbox.md) | Divide el trabajo en Arch daily driver y sandbox Linux replicable, con prioridades para multiples sesiones. |
