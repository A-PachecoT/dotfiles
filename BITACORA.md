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
Siguiente foco: mantener fixes cross-platform en `shared/` y empaquetar health checks/setup replicable para el dev sandbox.
Hay cambios sin commit en `shared/nvim/.config/nvim/lazy-lock.json`; el bridge clipboard queda listo para commit separado.

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

---

## Entries

| Fecha | Titulo | Resumen |
|-------|--------|---------|
| 2026-06-01 | [Clipboard bridge Mac -> Arch](bitacora/2026-06-01-clipboard-bridge-mac-arch.md) | Implementa bridge de clipboard por SSH, shims scoped para Claude Code y helpers manuales para texto/imagenes. |
| 2026-06-01 | [Yazi nvim shared launcher](bitacora/2026-06-01-yazi-nvim-shared-launcher.md) | Fija `nvim` para `yazi` desde `shared/zsh/tmux-workflow.zsh` y pushea el fix DRY a `main`. |
| 2026-06-01 | [Roadmap Arch Linux + dev sandbox](bitacora/2026-06-01-roadmap-arch-linux-dev-sandbox.md) | Divide el trabajo en Arch daily driver y sandbox Linux replicable, con prioridades para multiples sesiones. |
| 2026-06-16 | [Yazi image preview remoto](bitacora/2026-06-16-yazi-image-preview-remote.md) | Previewer chafa (sextantes) + visor on-demand Kitty (`i`) para que las imágenes se vean sobre tmux+ET+Ghostty; fija el modal "Find next:" con `chafa --probe=off`. |
