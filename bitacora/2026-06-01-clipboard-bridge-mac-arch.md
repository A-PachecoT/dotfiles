# 2026-06-01 — Clipboard bridge Mac -> Arch

**Operador:** Codex

---

## Contexto

Andre trabaja desde macOS hacia Arch Linux via Eternal Terminal/tmux. El texto ya viajaba razonablemente por OSC52, pero las imagenes no: Claude Code y Codex corren en Arch, mientras la imagen real vive en el clipboard del mac. En sesiones headless, `xclip`/`wl-paste` fallaban con errores de X11/Wayland inaccesible.

El objetivo de la sesion fue ejecutar lo que habia quedado conversado con Claude Code: hacer que Claude Code se sienta nativo para pegar imagenes desde el mac, y arreglar tambien el caso inverso donde un agente en Arch quiere copiar texto al clipboard del mac.

---

## Que Paso

1. Se reconstruyo el hilo reciente de Claude Code desde `~/.claude/projects/-home-andre-dotfiles/ac02e527-5940-4b68-8e79-67c4d6bc85f7.jsonl`.
2. Se confirmo el diagnostico:
   - OSC52 sirve para texto, no para imagenes.
   - Claude Code puede interceptarse porque llama binarios externos (`xclip`/`wl-paste`).
   - Codex no se puede interceptar igual porque lee clipboard in-process; para imagenes necesita ruta de archivo por ahora.
3. Se agrego `scripts/mac-clipboard` como bridge unico hacia el mac via SSH:
   - `paste-image` usa `pngpaste -`.
   - `paste-text` usa `pbpaste`.
   - `copy-text` usa `pbcopy`.
   - Usa `ssh -F /dev/null` y default `styreep@100.73.150.52` para evitar un config SSH global roto en Arch.
4. Se actualizo `shared/zsh/tmux-workflow.zsh`:
   - `cl` paso de alias a funcion.
   - `cl` scopea `PATH` a `scripts/claude-clipboard-shims/` y limpia variables SSH para evitar el short-circuit de Claude Code.
   - Se agregaron helpers `clip-img`, `clip-copy`, `clip-paste`.
5. Se agregaron shims scoped para Claude Code:
   - `scripts/claude-clipboard-shims/xclip`
   - `scripts/claude-clipboard-shims/wl-paste`
   - `scripts/claude-clipboard-shims/wl-copy`
6. Se verifico el bridge:
   - `mac-clipboard copy-text` escribio al clipboard del mac.
   - El usuario confirmo que el texto `codex clipboard bridge test` aparecio en el mac.
   - `xclip` y `wl-copy` shims hicieron roundtrip de texto.
   - `paste-image` trajo un PNG valido desde el clipboard del mac.
   - Codex inspecciono la ultima imagen del clipboard: captura del header de OpenAI Codex v0.135.0 mostrando `model: gpt-5.5` y `directory: ~/dotfiles`.

---

## Aprendizaje

- Para Claude Code, el paste de imagen mas nativo posible sin soporte real del terminal es un shim scoped que redirige `xclip`/`wl-paste` al clipboard del mac bajo demanda.
- Para Codex, no hay fix nativo limpio hoy porque la lectura de clipboard ocurre dentro del proceso; un shim de binarios no lo intercepta.
- El bridge de clipboard debe vivir como primitiva reusable (`mac-clipboard`) y no como logica duplicada en aliases.
- Scopear shims al launcher evita contaminar el sistema y reduce el riesgo de romper apps locales que esperan `xclip`/`wl-copy` reales.

---

## Accion

- Creado `scripts/mac-clipboard`.
- Creado `scripts/claude-clipboard-shims/{xclip,wl-paste,wl-copy}`.
- Actualizado `shared/zsh/tmux-workflow.zsh` con `cl`, `clip-img`, `clip-copy`, `clip-paste`.
- Actualizada la memoria de Claude en `/home/andre/.claude/projects/-home-andre-dotfiles/memory/arch-remote-access.md`.
- Pendiente: lanzar una nueva shell y abrir Claude Code con `cl` para probar Cmd+V de imagen dentro de Claude Code interactivo.
- Pendiente: commit separado para los cambios de clipboard/bitacora, dejando fuera el lockfile de Neovim si no pertenece a esta sesion.
