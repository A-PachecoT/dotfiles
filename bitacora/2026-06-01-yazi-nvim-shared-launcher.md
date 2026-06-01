# 2026-06-01 - Yazi nvim shared launcher

**Operador:** Codex

---

## Contexto

El usuario reporto que en el setup Arch/mac `yazi` no entraba a `nvim` al presionar Enter sobre un archivo. El objetivo era corregirlo de forma DRY y sincronizable entre macOS y Arch, sin duplicar configuracion por plataforma.

Estado inicial observado:

- `shared/yazi/.config/yazi/yazi.toml` ya tenia la regla `edit = '$EDITOR "$@"'`.
- `~/.config/yazi/yazi.toml` y `keymap.toml` estaban symlinked hacia `shared/yazi`.
- En el shell actual, `EDITOR=code` y `VISUAL` estaba vacio.
- `yazi` y `nvim` existen en Arch.

---

## Que Paso

Se confirmo que el repo sigue la arquitectura `shared/` + plataforma:

- `shared/yazi` es la fuente unica para Yazi en macOS y Linux.
- `shared/zsh/tmux-workflow.zsh` contiene el launcher `y()`, usado por el workflow tmux/yazi compartido.
- `linux/zsh/.config/zsh/conf.d/99-tmux-workflow.zsh` carga ese workflow compartido en HyDE/Arch.
- `macos/zsh/.zshrc` tambien carga ese workflow compartido.

El fallo no estaba en `yazi.toml`: la regla de texto ya apuntaba a `$EDITOR`. El problema practico era que el entorno podia llegar con `EDITOR=code`, especialmente en sesiones remotas o shells heredados.

Se aplico un fix minimo en `shared/zsh/tmux-workflow.zsh`: el launcher `y()` ahora ejecuta `yazi` con `EDITOR` y `VISUAL` seteados a `${YAZI_EDITOR:-nvim}` solo para ese proceso.

```zsh
EDITOR="${YAZI_EDITOR:-nvim}" VISUAL="${YAZI_EDITOR:-nvim}" yazi "$@" --cwd-file="$tmp" --client-id "${client_id:-$$}"
```

Esto conserva un escape hatch (`YAZI_EDITOR`) sin depender del `EDITOR` global del host.

Validacion ejecutada:

```bash
zsh -n shared/zsh/tmux-workflow.zsh
```

Luego se hizo commit y push solo del fix de Yazi, aislando cambios locales no relacionados.

Commit publicado:

```text
12d8589 Force nvim for yazi launcher
```

---

## Aprendizaje

- Los defaults de herramientas TUI compartidas deben fijarse en el launcher shared cuando shells remotos pueden traer variables host-specific.
- Si `yazi.toml` ya esta bien, revisar primero el entorno heredado por `yazi` antes de duplicar reglas de openers.
- Para cambios pequenos en un archivo sucio, stagear solo el hunk necesario evita arrastrar trabajo local no relacionado.

---

## Accion

- Se actualizo `shared/zsh/tmux-workflow.zsh` para forzar `nvim` dentro del launcher `y()`.
- Se valido sintaxis con `zsh -n`.
- Se commiteo y pusheo `12d8589 Force nvim for yazi launcher` a `origin/main`.
- Se actualizo esta bitacora y el brain `BITACORA.md`.
