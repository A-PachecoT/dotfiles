# Herdr workspaces + Navigator vim + auto-sync event-driven del mesh

**Fecha:** 2026-07-15
**Estado:** trial herdr sigue activo; la capa de propagación cross-mesh quedó automatizada
**Continúa de:** [Herdr trial + device mesh 4-way](2026-07-14-herdr-trial-device-mesh.md)

## Contexto

André no sabía cómo abrir "spaces nuevos" en herdr. Eso destapó que la capa
`workspace` (el 4to nivel del modelo `session > workspace > tab > pane`) estaba
deshabilitada a propósito en el trial. Habilitarla escaló a: navegación vim del
Navigator, un fix de ping-pong, y finalmente a **automatizar la propagación de
config entre los workers del mesh** (el gap que quedó abierto el 14).

## Qué pasó

### 1. Capa workspace habilitada — familia `cmd+shift`

Modelo mental: `session=empresa (AeroSpace) > workspace (nuevo) > tab=proyecto
(cmd+1-9) > pane (cmd+hjkl)`. El workspace agrupa proyectos dentro de una empresa.

- `cmd+shift+c` → nuevo workspace (espejo de `cmd+c` = nuevo tab)
- `cmd+shift+g` → picker de workspaces
- `cmd+shift+n` / `cmd+shift+p` → next / prev workspace
- **Sin índice directo** (`cmd+shift+1..9`): `cmd+shift+3/4/5` son screenshots de
  macOS y el OS los intercepta antes de Ghostty. Nav por picker.
- `close_workspace` quedó sin binding (`prefix+shift+d` lo usa `split_horizontal`).

Ghostty (client-side) traduce `cmd+shift+X → \x02X`; herdr (host) mapea la acción.
Como Arch es headless, la traducción vive solo en la Ghostty de la Mac; Arch solo
necesita el `config.toml` + reload.

### 2. `cmd+p` → Navigator (fuzzy jumper vim-native)

La respuesta a "navegar con j/k" no era el picker sino el **Navigator** de herdr
(`goto`), que ya soporta `j/k` (mover), `h/l` (nivel ws↔tab↔pane), `/` (buscar),
`Enter` (saltar) y `b/w/i/d/a` (filtrar por estado de agente). Estaba solo en
`ctrl+b g` sin shortcut cmd. `cmd+g` estaba ocupado por `navigate_search:next` de
Ghostty → se eligió `cmd+p` (libre, mnemónico "palette" tipo VS Code). Es el viejo `tp`.

### 3. Ping-pong incipiente cortado: `onboarding = false`

herdr auto-escribe `onboarding = false` al tope del `config.toml` (symlink al
repo) al descartar el onboarding. En Arch dejaba el repo dirty y bloqueaba el
pull. Es flag universal (no platform-specific) → se trackeó en `shared/` para que
ambas cajas lo tengan y herdr no reescriba. Mismo patrón que el `.gitconfig`.

### 4. `mesh-update` (`mu`) — fan-out manual

Un comando desde cualquier worker: pushea commits locales, hace fast-forward y
recarga herdr en Mac + Arch. `IdentityAgent=none` para inmunizar el leg Arch→Mac
contra el cuelgue por `SSH_AUTH_SOCK` ET-forwarded vivo-pero-mudo. celu/tablet
fuera (sin server herdr). Validado: propagación, reload, idempotencia, dogfood.

### 5. Propagación event-driven push-triggered (saca al humano)

`mu` seguía siendo trigger manual. Se enganchó `mesh-fanout.sh` al modo `push` de
`ssot-sync.sh` (que corre en **PostToolUse**): tras un push exitoso, dispara en
background un nudge al peer worker (`ssh → pull --ff-only + herdr reload`). Al
editar config vía Claude, la otra caja se actualiza sola. Peer offline / push
fuera de Claude → lo agarra el `SessionStart` pull. `mu` queda como escape hatch.

Elección de arquitectura de André: **push-triggered** sobre timer/daemon
(instantáneo, sin polling; el trade-off aceptado es que solo dispara desde el
flujo Claude).

### 6. FIX de fondo: `timeout` no existe en macOS sin coreutils

Al cablear el fan-out se descubrió que `ssot-sync` estaba **roto en la Mac**:
`timeout` no está en el PATH → `timeout 15 git push` fallaba con 127. Efecto: el
push nunca ocurría (caía al branch de error e imprimía un "CONFLICTO" espurio) y
el **pull del SessionStart tampoco jalaba** (lo tragaba el `|| true`). Fix: shim
`_to` que usa `timeout`/`gtimeout` si existen y degrada a correr sin límite si no.
Bonus: el auto-pull de arranque en la Mac, que estaba muerto, revivió.

## Decisiones tomadas

- Workspace layer = familia `cmd+shift`, nav por picker (sin índice por colisión
  con screenshots macOS).
- Navigator en `cmd+p` (no `cmd+g`, ocupado por Ghostty search).
- `onboarding=false` trackeado en `shared/` (flag universal, no per-box).
- Propagación **event-driven push-triggered**, no polling/timer.
- `IdentityAgent=none` como transporte estándar de los scripts de fan-out.

## Pendientes que se generaron

- Sigue pendiente la decisión de migración tmux→herdr al cierre del trial.
- Si algún día se quiere cubrir pushes fuera de Claude sin esperar al
  SessionStart: agregar el timer systemd/launchd (opción descartada hoy) como red.
- Evaluar DRY entre `mesh-update.sh` y `mesh-fanout.sh` (comparten el snippet
  remoto pull+reload).

## Aprendizaje

- La traducción `cmd→prefix` de un multiplexer con passthrough vive en el terminal
  CLIENTE, no en el host; un host headless solo necesita el config de acciones + reload.
- `cmd+shift+3/4/5` son screenshots de macOS y el OS los come antes que cualquier
  app — inutilizables como keybinds de terminal.
- `timeout` no existe en macOS sin coreutils: cualquier script `shared/` que lo use
  falla con 127 en la Mac. Shim que degrade a correr-sin-límite, o `gtimeout`.
- Propagación cross-device sin humano: como GitHub no puede entrar al tailnet, o
  polleás (timer) o el que pushea avisa a los peers (event-driven). El segundo es
  instantáneo pero solo cubre el flujo que dispara el hook.
- Un config auto-escrito por una tool (herdr `onboarding=false`) sobre un symlink
  al repo ensucia git en cada caja; trackearlo (si es universal) corta el ping-pong.
