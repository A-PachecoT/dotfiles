# Herdr trial + device mesh 4-way: ET mata a mosh en móvil

**Fecha:** 2026-07-14
**Estado:** trial activo (herdr en ambos workers, en paralelo a tmux; decisión de migración pendiente)

## Contexto

André preguntó si adoptar **Herdr** (multiplexer agent-native en Rust, v0.7.x)
en lugar del setup tmux custom. La evaluación escaló a: trial con keybinds
1:1, acceso desde el celular, y terminó en un **mesh SSH full entre los 4
dispositivos** (Mac, Arch, celu Redmi, tablet) sobre Tailscale, con herdr
corriendo en ambos workers.

## Qué pasó

### 1. Evaluación Herdr vs tmux custom

- Herdr NO es wrapper de tmux: multiplexer standalone en Rust (85%), motor
  VT de Ghostty vendored, PTY real por pane. Modelo `session > workspace >
  tab > pane`.
- Su capa agent-aware (detección de Claude Code idle/working/blocked + rollup
  jerárquico + native agent session restore tras reboot) reemplaza el
  Claude Pending Notification System custom (~7 scripts).
- Contras: pre-1.0, snapshot-on-stop (continuum cada 10min es más robusto a
  crash sucio), sin equivalente a hop (`Cmd+f`).
- Decisión: **trial en paralelo**, no migración big-bang. tmux sigue intacto.

### 2. Trial de keybinds — el truco prefix-less salió gratis

Ghostty ya traduce `cmd+X → \x02X` (= `ctrl+b`+X) y el prefix default de
Herdr es el mismo `ctrl+b` → los keybinds de tmux le llegan a Herdr sin tocar
Ghostty. Solo se remapearon acciones en `config.toml` (ahora
`shared/herdr/`, stowed en ambos workers). Ajuste semántico: `cmd+w`/`cmd+x`
cierran pane, `cmd+shift+w` cierra tab/proyecto (escalación shift=destructivo,
patrón macOS).

### 3. Acceso móvil — mosh rompe el touch, ET lo salva

- Termux (F-Droid) + key ed25519 por dispositivo + Tailscale.
- `mosh` conectaba pero **el tap-to-focus de Herdr moría**: mosh reinterpreta
  la pantalla en un virtual terminal y se come el mouse-tracking (los logs del
  server confirmaron: 0 eventos de mouse del cliente móvil).
- SSH puro (`ssh -t … herdr`) → touch revivió. **ET (Eternal Terminal) dio
  lo mejor de ambos**: passthrough fiel como SSH (touch ✓) + reconexión
  automática como mosh. etserver: brew services (Mac, :2022) + systemd (Arch).
- Gotcha PATH: mosh-server/herdr no se encontraban en shells no-interactivos
  → fix en `~/.zshenv` (ahora `macos/zsh/.zshenv` en el repo).

### 4. Mesh 4-way

- Matriz SSH 12/12 verificada: cada dispositivo entra a los otros 3.
- Workers (Mac `100.73.150.52`, Arch `100.84.249.22`) = cómputo; celu
  (`100.113.92.48`) y tablet (`100.108.156.30`) = terminales + endpoints
  termux-api (probado: notificación push al celu desde la Mac vía ssh).
- Aliases únicos en las 4 cajas: `h` = herdr Mac, `ha` = herdr Arch
  (`shared/zsh/mesh.zsh` en workers, `~/.bashrc` en Termux).
- Herdr instalado en Arch (0.7.3, installer oficial, server headless vía
  `setsid`).
- Ship al repo: `shared/herdr/`, `shared/zsh/mesh.zsh` +
  `linux conf.d/96-mesh.zsh`, `macos/zsh/.zshenv`,
  `scripts/termux-bootstrap.sh`, `docs/device-mesh.md`.

### 5. Ping-pong del .gitconfig — resuelto de raíz

El anti-patrón documentado en CLAUDE.md estaba ocurriendo en vivo: Arch
hardcodeó `/usr/bin/gh` en `shared/git/.gitconfig` mientras la Mac eliminaba
el bloque (fix del credential-loop de Obsidian). Solución: el credential
helper vive per-box en `~/.config/git/config` (XDG global, git lo lee junto
a `~/.gitconfig`, NO stowed) y el `shared/` queda portable. Auth verificado
en ambas cajas.

## Decisiones tomadas

- Herdr en trial paralelo, empresa = named session (mantiene el modelo
  AeroSpace ws=empresa); el nivel `workspace` de Herdr se ignora.
- ET como transporte estándar del mesh (no mosh, no ssh pelado).
- Key ed25519 dedicada por dispositivo, nunca compartida.
- Config git de credenciales: per-box XDG, jamás en `shared/`.

## Pendientes que se generaron

- Decidir migración tmux→herdr al cierre del trial (1-2 semanas): validar
  sidebar de agentes vs Claude Pending System, y fluidez prefix-less.
- Fase 2 si migra: AeroSpace routing por sesión herdr + retirar scripts
  del pending system.
- `sudo brew services start et` (auto-start real de etserver en boot Mac).
- Termux:Boot en celu/tablet (sshd tras reboot sin abrir la app).
- Batería "sin restricciones" para Termux+Tailscale en el celu (tablet ya).

## Aprendizaje

- mosh NO pasa mouse-tracking (virtual terminal propio); ET sí (Eternal TCP
  passthrough) y además reconecta solo — para TUIs mouse-first en móvil, ET.
- `et`/`ssh host comando` no cargan `.zshrc`: todo binario que deba
  resolverse remoto va en `.zshenv` (homebrew + `~/.local/bin`).
- El timeout vs refused distingue capas: refused = host vivo sin listener;
  timeout = red (en Android casi siempre Tailscale dormido/desconectado).
- `pkg install` interactivo de Termux se come las líneas pegadas después:
  bloques de setup móvil siempre en 2 pastes (install / configure).
- Los helpers de credenciales git son platform-specific por naturaleza:
  van en `~/.config/git/config` per-box, no en el `.gitconfig` stowed.
- `nohup cmd &` dentro de `ssh host '...'` muere con la sesión; `setsid`
  desacopla de verdad.
