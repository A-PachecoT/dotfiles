# 2026-10-09 — myturn: panel por teclado

## Contexto
André: «cuando le doy a alt + t yo quiero que se focusee en el panel y que si le doy n se pone en crear nueva task
y si le doy f se pone a buscar y que pueda hacer navegación con hjkl enter/space y que cuando le dé escape vuelva al
aerospace panel donde me quedé». Antes ⌥T enfocaba el campo «Nueva tarea» y Esc solo ocultaba el panel (el foco
quedaba en Hammerspoon, sin ventana).

## Qué shipeó
- `myturn-panel.html`: modo lista (ningún campo enfocado) con fila elegida (`j`/`k`) y columna elegida (`h`/`l`:
  título, prioridad, acción, ✓, ✕); `Enter`/`Espacio` ejecuta el botón (o edita el título). `n` → «Nueva tarea»,
  `f` → «Buscar» (filtro por título sin tildes). En un campo, `Esc` vuelve a la lista; en la lista, cierra.
  La selección se guarda por id, así sobrevive a los renders y, si la fila se cierra, queda la que tomó su lugar.
- `myturn.lua`: `show()` guarda `hs.window.frontmostWindow()` antes de mostrar; `hide(true)` (Esc o ⌥T) vuelve a
  ella con `aerospace focus --window-id` (fallback `win:focus()`). Perder el foco por un clic afuera solo cierra.
- SSOT `docs/myturn.md` §Teclado del panel; CLAUDE.md del repo.

## Validación
En vivo en el Mac: hjkl, búsqueda con y sin resultados, `n`, edición con Enter y Esc, todo con eventos de teclado
sintéticos vía `require("myturn").eval`; teclas físicas (`hs.eventtap.keyStroke`) mueven la selección; Esc físico
envía `close` y el frente vuelve de Hammerspoon a Ghostty.

## Learnings
- `hs.eventtap.keyStroke({"alt"},"t")` no dispara un hotkey del propio Hammerspoon: para probar, `require("myturn").show()`.
- Las teclas físicas sintetizadas llegan después de que `hs -c` vuelve: un `eval` inmediato lee el estado anterior.
  Para la lógica, mejor `KeyboardEvent` sintético dentro del webview (determinista).
- Después: `/` también busca y `gg`/`G` van a la primera/última fila.
- Bug encontrado en uso: Esc dejaba el foco en Hammerspoon. AeroSpace no ve el panel (borderless, popUpMenu), cree
  que la ventana previa sigue enfocada y `aerospace focus` es no-op. Fix: `app:activate()` de la app previa y luego
  AeroSpace. Medido: vuelve en <0,15 s.
- Bug inducido por las pruebas: ⌥T muerto. Un `hs -c` cortado por `alarm 4` deja `print` redirigido a un puerto IPC
  muerto; la carga perezosa de `hs.*` imprime y revienta el callback del hotkey. Fix: precargar las extensiones en
  `myturn.lua` + reinicio limpio de Hammerspoon.
- Probar abriendo el panel lo pone en la pantalla de André: un clic suyo durante la prueba es una acción real.
