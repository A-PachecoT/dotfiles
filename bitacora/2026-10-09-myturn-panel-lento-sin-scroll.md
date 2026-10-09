# 2026-10-09 — myturn: panel lento y sin scroll

**Contexto.** André: «mi myturn demora mucho en responder cuando le doy click, hasta se cuelga creo, y no puedo scrollear entre mis tasks».

**Causas (medidas).**
- Sin scroll: con 23 tareas la tarjeta medía 1210 px en el VG27VQ (1080 px) y `html, body { overflow: hidden }`; el webview crecía más allá de la pantalla y lo de abajo quedaba inalcanzable.
- Lentitud: cada clic corre el CLI dos veces (acción + `panel`), y ambas recalculan con `ssh andre-arch herdr agent list` cuando el caché remoto pasó de 60 s. En frío medí 0,28 s, pero con la red lenta o el Arch sin responder cada llamada esperaba hasta 6 s y el fallo no se cacheaba: todos los clics pagaban el timeout.
- El primer clic tras recargar Hammerspoon además creaba el webview (cargaba la extensión).

**Qué shipeó.**
- Panel topado a la pantalla (`maxH`), tarjeta flex con `#list` scrolleable.
- `herdr_agents` remoto sirve el caché y renueva en segundo plano (`myturn _agents <host>`, como mucho cada 20 s); un caché de >10 min cuenta como «no responde»; `go` lee en el acto para no reabrir un agente que solo falta en el caché.
- UI optimista: ✓/✕, prioridad y edición cambian al instante; el render del CLI corrige después.
- Webview precargado al cargar Hammerspoon.

**Validación.** 18 smoke tests (nuevo: `test_remote_agents_never_wait_for_ssh`) + ruff. En vivo: panel 1024 px, lista 926 px visibles de 1124, scroll al fondo con el pie visible (captura).

## Segunda vuelta (mismo día): el congelamiento de ~1 s

André: «sigue colgándose… pasó por 1 segundo, ¿no hay mejor UI/UX como skeletons?». Instrumenté el clic en Hammerspoon: url → show 6 ms, `myturn panel` ~100 ms, **`panel:hswindow():focus()` 1 625 ms** (accesibilidad, bloquea el hilo de Hammerspoon y con él el panel). Se reemplazó por `hs.focus()` + `show()` 50 ms después (la activación es asíncrona; ya activa, `show()` la vuelve ventana clave). Verificado escribiendo con `hs.eventtap.keyStrokes`: 3/3 llegan al campo. Ojo: `document.hasFocus()` da `false` aunque el teclado sí llega; no sirve como prueba.

UX: barra fina animada arriba mientras el CLI responde, skeleton (4 filas con shimmer) si todavía no hay datos, y la tarea nueva aparece al instante como «guardando…».
