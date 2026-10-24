# 2026-10-23 · Zen como ventana de herdr

## Contexto
André buscaba un browser con atajos para todo, UI configurable y buen manejo de RAM. Comparamos Helium, Brave, Comet, Thorium, Vivaldi, SigmaOS y qutebrowser: nada supera a Zen (Firefox) para su caso, que ya trae Bitwarden y Video Speed Controller. Lo que faltaba era manejarlo con las teclas de herdr.

## Qué se shippeó
- `macos/hammerspoon/.hammerspoon/zen-keys.lua`: hotkeys activos solo con Zen enfocado (bundle `app.zen-browser.zen`). ⌘j/⌘k tab siguiente/anterior (con repeat), ⌘h/⌘l workspace anterior/siguiente, ⌘d split vacío a la derecha, ⌘⇧d split horizontal. Traducen a los atajos nativos de Zen.
- Perfil de Zen (fuera de dotfiles, backup `zen-keyboard-shortcuts.json.bak-2026-10-23`): barra de URL ⌘l → ⌘e, find-selection apagado, split horizontal ⌘⌥h → ⌘⌃⌥h.

## Decisiones
- Hammerspoon y no un mod de Zen (Sine/userChrome): Zen 1.23 no tiene acción remapeable de «siguiente tab» ni de «enfocar panel del split», y Hammerspoon funciona incluso con la barra de URL enfocada, sin parchear el `.app`.
- ⌘c/⌘x/⌘z se quedan como copiar/cortar/deshacer; nuevo tab sigue en ⌘t.
- Sleeping tabs: Zen ya los descarga (`zen.tab-unloader.timeout-minutes`, default 10) y Firefox con `browser.tabs.unloadOnLowMemory`.

## Validación
- Hammerspoon cargó el módulo («🧘 Zen herdr keys ready»); hotkeys habilitados solo con Zen al frente (outside=0, inZen>0, back=0).
- Ctrl+PageDown/PageUp sintéticos cambian de tab en Zen. El ⌘j físico no se puede probar desde una sesión: Hammerspoon no atrapa sus propios eventos sintéticos.

## Learnings
- `~/.hammerspoon` está stoweado archivo por archivo: un módulo nuevo necesita su symlink (o `./install.sh restow`) o el `require` rompe TODO el init.lua (audio, myturn incluidos).
- `hs -c 'hs.reload()'` cuelga el CLI: usar `hs -c 'hs.timer.doAfter(0.5, hs.reload)'`.
- Zen lee `zen-keyboard-shortcuts.json` al arrancar: los cambios aplican tras reiniciar Zen.

## Addendum: spaces y containers (mismo día)
- Comet → Zen como browser principal (AeroSpace WS1 por `app-id`, `alt-q`, arranque).
- Dos spaces, cada uno con su container: **Personal** (ex-Home, container Personal, Essential: Gmail) y **Cofoundy** (container Work, Essentials: Calendario, Coresponde, Gmail, WorkAdventure `office.cofoundy.dev`). Bilio ya no es space (no sigue activo).
- Ruteo de space: todo URL con `cofoundy.dev` abre en Cofoundy (`zen-space-routing.jsonlz4`). `user.js`: `zen.workspaces.force-container-workspace=true`.
- Pin de tab ⌘⇧d → ⌘⇧e (⌘⇧d es split horizontal en `zen-keys.lua`).
- Learning: los Essentials son por container (`zen.workspaces.separate-essentials` = true por defecto); un space con container solo muestra los Essentials de ese container. Pineado ≠ Essential.
- Learning: la sesión de Zen (`zen-sessions.jsonlz4`, mozlz4 = `mozLz40\0` + lz4 block con tamaño) se puede editar con Zen cerrado; backup en `<perfil>/claude-backup-2026-10-23/`.
