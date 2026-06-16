# Yazi image preview sobre tmux + Eternal Terminal + Ghostty

**Fecha:** 2026-06-16
**Tipo:** fix + feature (shared/yazi)

## Contexto

Los previews de imágenes (PNG) no se veían en yazi corriendo en la Arch headless,
visualizada desde macOS Ghostty a través de Eternal Terminal (ET) + tmux. El
panel quedaba en blanco y a veces filtraba `+++++` en una esquina.

## Diagnóstico (de afuera hacia adentro)

1. `allow-passthrough on` ya estaba en tmux — no era eso.
2. Faltaba el fallback `chafa`/`ueberzugpp` (no instalados) → al no negociar
   gráficos, no había nada que pintar.
3. Tests directos sobre la cadena `tmux → ET → Ghostty`:
   - Kitty **placement directo** (`a=T` al cursor, envuelto en passthrough): ✅
     funciona, incluso payloads multi-chunk grandes.
   - Kitty **unicode placeholders** (lo que yazi usa para Ghostty): ❌ — las
     celdas-placeholder (U+10EEEE + diacríticos + color que codifican el image
     id) se corrompen en tránsito; ET las mutila.
   - Sixel: ❌. chafa **símbolos** (texto coloreado): ✅.
4. Fuente en yazi: `adapters.rs:33  B::Ghostty => vec![A::Kgp]` cablea Ghostty a
   unicode-placeholders, y `emulator.rs:58 from_csi(resp).or(env)` hace que la
   respuesta XTVERSION (`ghostty`) gane sobre cualquier override por env → no se
   puede forzar otro adaptador por configuración.

## Qué shipeó

- **`shared/yazi/.config/yazi/plugins/chafa.yazi/`** — previewer custom que
  renderiza con chafa (`--symbols=sextant+block+quad+half+space`). Solo actúa en
  sesiones remotas (SSH/ET); local difiere al previewer nativo `image`.
- **`shared/yazi/.config/yazi/plugins/imgview.yazi/`** — visor on-demand (tecla
  `i`): `ui.hide()` + `view.py` que pinta la imagen full-res vía Kitty directo
  (método probado), cualquier tecla regresa.
- **`yazi.toml`**: `[plugin] prepend_previewers` → `image/* = chafa`.
- **`keymap.toml`**: tecla `i` → `plugin imgview`.
- Instalados en la Arch (no stow): `chafa`, `ffmpegthumbnailer`. Documentado como
  dependencia runtime en `chafa.yazi/README.md`.

## Bug colateral resuelto: modal "Find next:" al scrollear

`/` es la tecla por defecto de `find --smart` ("Find next:"). chafa por defecto
sondeaba el terminal (`ESC]11;?` bg-color); la respuesta
`ESC]11;rgb:1a1a/1b1b/2626` mete `/` que, en la carrera por el tty, yazi leía
como tecla. Fix: `--probe=off --passthrough=none` en el previewer.

## Validación

- `luac -p` en ambos plugins, `python -m py_compile` en `view.py`: OK.
- chafa con flags finales: rc 0, output válido.
- Captura con `script` confirmó: default chafa escribe 6 queries al tty; con
  `--probe=off --passthrough=none`, cero.
- André confirmó en su terminal real: preview chafa visible, `i` abre imagen
  pixel-perfect y regresa, scroll ya no abre "Find next:".

## Learnings

- Sobre tmux + ET + Ghostty: el transporte aguanta **gráficos Kitty de placement
  directo** y **texto**, pero **NO** unicode-placeholders ni sixel. La frontera
  es "¿depende de celdas de texto especiales (diacríticos/color) que el
  multiplexor+ET preservan mal?".
- yazi identifica la marca del emulador por XTVERSION en runtime, así que los
  trucos de `TERM`/env de la doc no sirven cuando Ghostty se anuncia.
- Cualquier previewer que abra `/dev/tty` para sondear (chafa) compite con el TUI
  padre por el stdin; desactivar el sondeo evita que respuestas-escape se cuelen
  como teclas.
