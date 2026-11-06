# Lag de teclado: Karabiner fuera, hidutil adentro (2026-11-05)

**Síntoma.** Las teclas llegaban tarde y se repetían solas («holaaaaaa», «cccccc»), en el teclado 2.4G y también en el del MacBook. El CPU estaba normal.

**Diagnóstico.**
- Una letra repetida significa que el key-up llegó tarde y el autorepeat se disparó. Si pasa en los dos teclados, el problema está en lo que intercepta a ambos: es software, no la radio del 2.4G.
- No eran la RAM ni los 38 Claude: `memory_pressure` daba 51 % libre. Tampoco Wispr Flow: lo maté con `pkill -9` y siguió pasando. Hammerspoon tampoco: su único event tap de teclado es el de `pdf-vim`, y solo con un PDF al frente.
- Al hacer `launchctl bootout` de los agentes de Karabiner (Core-Service-rev2 y Console-User-Server), el teclado volvió a responder al instante. En `/var/log/karabiner/core_service.log` el `receiver` del daemon se cerraba y reabría cada 1 a 5 minutos.

**Fix.** Karabiner solo hacía Caps↔Esc (global) y ⌘↔⌥ izquierdos en el teclado 2.4G, que se presenta como `0x5ac/0x24f`. Ahora lo hace `macos/hammerspoon/.hammerspoon/keyremap.lua` con `hidutil`, que remapea en el driver: sin daemon ni event tap. El módulo reaplica el mapeo con `hs.usb.watcher` y al despertar, porque un mapeo por dispositivo se pierde si el receptor se reconecta. El `--set` global va antes que el `--matching`, porque si no lo pisa.

Karabiner queda instalado pero apagado: `launchctl disable gui/501/org.pqrs.service.agent.{Karabiner-Core-Service-rev2,Karabiner-Console-User-Server,Karabiner-Menu}`. Para revertir: `launchctl enable` de los mismos labels, abrir Karabiner-Elements y borrar el `require("keyremap")`.

**Verificá:** `hidutil property --matching '{"ProductID":591,"VendorID":1452}' --get UserKeyMapping` debe mostrar 4 mapeos.
