# herdr: una sola ventana con máquinas (Arch y hq) y myturn que salta entre ellas

**Fecha:** 2026-10-17 · **SSOT:** `docs/myturn.md` §Una sola ventana de herdr con máquinas · `docs/device-mesh.md`

## Contexto
André ya maneja todo desde el Ghostty del workspace 2: herdr permite agregar máquinas y el Arch ya estaba. Pidió
que `h` también tenga hq, que deje de abrirse `ha` en el workspace 3 y que se actualice el herdr de hq. Además,
«ir a Claude» desde myturn no lo llevaba a un agente del Arch: `go` buscaba la ventana `herdr-arch`, que ya no existe.

## Qué shipeó
- **hq:** herdr 0.7.3 → 0.9.5 con `herdr update --handoff`; sus 2 Claude de basalt siguieron vivos.
  `herdr machine add andre@100.106.190.15 --label hq` en la Mac; arch y hq, `reachable`.
- **Arranque:** dev-startup ya no abre `ha` y AeroSpace ya no rutea `herdr-arch`. Si `h` se abrió a mano, no se
  duplica, porque `ui.window_title` ahora es `herdr · {hostname} · {workspace}`. `mu` también actualiza hq.
- **myturn `go`:** `agent focus` en la caja del agente, más foco en la ventana de `h`. Si `h` muestra otra máquina,
  Hammerspoon teclea el navegador de herdr (`prefix+g`, `/id`, ↓ calculadas, Enter) vía `hammerspoon://myturn-goto`.
- **Visto:** la máquina que ves sale de `selected` en `herdr machine list --json`.

## Validación
- 46 tests (2 nuevos: `navigator_downs` calca el filtro del navegador; frontmost = máquina elegida) + ruff.
- En vivo: con `h` mostrando el Arch, `myturn go td35884` dejó en pantalla el pane de Jorge (captura de la ventana).
- El salto entre máquinas con teclas pasó de Arch a Local, pero cayó en `wE0:p1` en vez de `wF0:p1`. André estaba
  usando herdr en ese momento, así que no es concluyente.
- André lo probó desde el panel («este no me manda a la sesión que corresponde»): el log muestra `herdrGoto` enviado
  y la máquina sin cambiar. Causa: `hs.eventtap.keyStrokes` manda texto con keycode 0 y Ghostty traduce por keycode,
  así que la búsqueda llegaba como «aaaaaa» (`a` = «todos» en el navegador) y Enter se quedaba en la fila actual.
  Fix: cada carácter con `keyStroke` y su tecla real (`:` = shift+`;`).

## Learnings
- herdr no tiene CLI para cambiar la máquina que muestra el cliente. `--machine` solo enruta comandos. La máquina
  elegida sí queda en el catálogo: `herdr machine list --json` → `selected`.
- El título de la ventana de herdr no dice qué máquina ves: lo escribe el server que mandó el último mensaje.
- `open -na Ghostty` desde un pane de herdr hereda `HERDR_*` → «nested herdr is disabled». Y `HERDR_SESSION` no
  gana sobre `HERDR_SOCKET_PATH`: dos workspaces de prueba cayeron en la sesión real (los cerré).
- Probar teclas sintéticas en la ventana que André usa no da resultados confiables y lo interrumpe; hace falta una
  ventana aparte, en un momento en que él no esté usando la Mac.
- **Para teclear en Ghostty desde Hammerspoon, usar `keyStroke` tecla por tecla, nunca `keyStrokes`.**
- Recargar Hammerspoon con `hs -c 'hs.reload()'` se cuelga (ya estaba en el SSOT). Para avisarle desde un script, usar
  `open -g hammerspoon://…`, no `hs -c`.
