# Los `alt+` de AeroSpace mueren: un campo de contraseña se los comía

**Fecha:** 2026-07-09
**Estado:** resuelto (causa raíz encontrada por el usuario, no por el agente)

## Contexto

Los hotkeys `alt+1..9`, `alt+q`, `alt+w` de AeroSpace dejaban de funcionar
"después de un rato". `killall AeroSpace && open -a AeroSpace` los revivía, y
volvían a morir minutos después. En paralelo, el monitor VG27VQ lleva ~una
semana apagándose (macOS lo reporta `Online: Yes` a 120 Hz con la pantalla en
"sin señal"). Ambos síntomas empezaron la misma semana, lo que indujo a
buscar una causa común que no existía.

## Causa raíz

El plugin de git de **Obsidian** abría un prompt de contraseña. Ese campo
retenía el *first responder* del teclado **aunque el panel no estuviera
enfocado**, y se tragaba `Option`+`<tecla de carácter>` como **texto** — las
teclas literalmente se escribían dentro del campo de contraseña.

Eso explica la huella exacta que medimos:

| Combo | Produce carácter | ¿Vivía? |
|---|---|---|
| `Option+3`, `Option+q`, `Option+P` | sí (`£`, `œ`, `π`) | ❌ |
| `Option+Tab`, `Option+←` | no | ✅ |
| `Ctrl+P`, `Cmd+Espacio` | no lleva Option | ✅ |

Reiniciar AeroSpace lo "arreglaba" porque **le robaba el foco al panel**, no
porque re-registrara hotkeys. Por eso `aerospace reload-config` no bastaba
(no toca el foco) y `killall` sí. Ese detalle desconcertó al agente durante
toda la sesión.

## Qué se descartó (con evidencia)

| Hipótesis | Cómo murió |
|---|---|
| Secure Input | Raycast (`Cmd+Espacio`) abre con él en `True` |
| Karabiner / swap de modificadores | el Alt emite `alt` limpio; `cmd+8` nunca disparó |
| Teclado AULA | falla igual desde el teclado interno |
| superwhisper | cerrarlo no cambió nada |
| Layout `USInternational-PC` | funcionó meses con el mismo layout |
| Conflicto de registro Carbon | `⌥P` (que AeroSpace no reclama) también moría |

## Learnings

- **Un campo de texto con foco se traga los hotkeys `Option`+carácter, sin
  error ni log.** Si mueren *solo* las combos que producen carácter, busca un
  campo de texto/password abierto antes que un conflicto de hotkeys.
- **`SLSGetHotKey` devuelve `1002 = kCGErrorInvalidConnection`** para
  cualquier connection ajena: macOS **prohíbe** enumerar los hotkeys Carbon de
  otra app. No existe herramienta que los liste; hay que reconstruir el mapa
  desde las configs (`scripts/hotkey-inventory.py`).
- **Un `CGEventPost` sintético sí dispara hotkeys Carbon**, así que el
  diagnóstico se automatiza sin humano al teclado (`scripts/hotkey-canary.sh`).
- **Re-registrar un hotkey de Hammerspoon en cada ciclo produce falsos
  positivos** (carrera con su GC). El canario v1 reportó una muerte que no
  ocurrió; hay que registrar una sola vez.
- **Secure Input ciega los event taps pero no los hotkeys Carbon.** Un tap
  bajo Secure Input ve `flagsChanged` y ningún `keyDown` — confundir ambas
  capas cuesta horas.
- **Apps Electron (Discord, WhatsApp) mueren reteniendo Secure Input**,
  dejando el flag en `True` apuntando a un PID muerto. Se limpia con lock
  screen (`SACLockScreenImmediate`); `CGSession` ya no existe en macOS
  moderno.
- **El agente se aferró a hipótesis y sobre-afirmó tres veces.** El usuario
  aportó dos correcciones decisivas ("siempre usé International", "es el
  AULA, no el interno") y finalmente la causa raíz. Cuando el usuario
  contradice una hipótesis desde su experiencia, esa objeción **es evidencia**.

## Shipeado

- `scripts/hotkey-inventory.py` — mapa de hotkeys globales desde configs
  (symbolic hotkeys, `.aerospace.toml`, Hammerspoon, Raycast) + detección de
  conflictos. 83 hotkeys, 0 conflictos en este equipo.
- `scripts/hotkey-canary.sh` — detecta con evento sintético el instante en que
  muere el despacho de `Option`+carácter y vuelca forense (USB/HID, display,
  Secure Input, procesos nuevos).
- `scripts/dev-startup.sh` — **idempotente**. AeroSpace re-ejecuta
  `after-startup-command` en cada reinicio del WM, no solo en boot, y
  `open -na Ghostty` siempre abría ventana nueva: reiniciar AeroSpace
  duplicaba cada ventana y desordenaba los workspaces. Ahora salta las
  sesiones que ya tienen ventana y **no las mueve** (moverlas desharía un
  layout ya arreglado a mano). `--force` recupera la conducta anterior.

## Pendiente

- **Monitor VG27VQ**: sigue sin diagnosticar. macOS lo ve online mientras la
  pantalla dice "sin señal". `CLAUDE.md` documenta que iba por DisplayPort (no
  HDMI) y que la cadena Hub 1 → Hub 2 tiene problemas conocidos de
  energía/ancho de banda. Ya no se sospecha relación con los hotkeys.
- Quedaron **dos ventanas `arch-cof`** duplicadas por el bug de idempotencia.
