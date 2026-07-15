# Device Mesh — los 4 dispositivos como colegas

> Establecido 2026-07-14. SSH full-mesh sobre Tailscale entre las 4 cajas de
> André. **Workers** (donde corre el cómputo): Mac + Arch. **Terminales de
> acceso**: celu + tablet (Termux).

## Topología

| Dispositivo | Tailscale IP | OS | Rol | sshd |
|---|---|---|---|---|
| Mac (`mac`) | `100.73.150.52` | macOS | worker — herdr, agentes, dev | :22 (Remote Login) |
| Arch (`arch`/`razer`) | `100.84.249.22` | Arch Linux | worker — herdr, Hermes agents | :22 (systemd) |
| Celu (`celu`/`redmi`) | `100.113.92.48` | Android/Termux | terminal + endpoint termux-api | :8022 |
| Tablet (`tablet`/`tab`) | `100.108.156.30` | Android/Termux | terminal + endpoint termux-api | :8022 |

Matriz 12/12 verificada 2026-07-14: cada dispositivo entra por SSH a los
otros tres. Auth por key ed25519 **dedicada por dispositivo** (revocables
individualmente). Todo dentro del tailnet (WireGuard); nada expuesto a
internet.

## Cómo entrar a herdr desde cualquier caja

Misma memoria muscular en las 4:

| Alias | Hace | Definido en |
|---|---|---|
| `h` | herdr de la **Mac** | `shared/zsh/mesh.zsh` (workers) / `~/.bashrc` (Termux) |
| `ha` | herdr del **Arch** | ídem |

Local → binario directo; remoto → `et <worker> -c herdr`.

## Transporte: ET, no mosh (decisión clave)

- **mosh NO pasa el mouse/touch** — reinterpreta la pantalla en un virtual
  terminal y se come el mouse-tracking. En el celu el tap-to-focus de herdr
  moría con mosh y revivió con SSH puro (validado 2026-07-14).
- **ET (Eternal Terminal)** usa una capa "Eternal TCP": passthrough fiel
  como SSH (touch ✓) + reconexión automática como mosh. Lo mejor de ambos.
- etserver: Mac vía `brew services` (puerto 2022), Arch vía systemd.

## Persistencia de sesiones

La persistencia real la da **el server de herdr** (no el transporte): si se
cae la conexión, reattachear devuelve todo tal cual. Ojo: herdr **no
sobrevive reboot del host** con procesos vivos — reconstruye layout/cwd y
Claude Code resume su propia conversación (native agent session restore).

## Reglas de operación

- **Key nueva = dispositivo nuevo**: correr `scripts/termux-bootstrap.sh`
  (Android) y autorizar su pubkey en ambos workers. Nunca copiar keys entre
  dispositivos.
- **Android mata procesos**: Termux Y Tailscale necesitan batería "Sin
  restricciones" en cada dispositivo Android. Sin eso el mesh se cae al
  apagarse la pantalla.
- **PATH no-interactivo**: `et`/`ssh <host> comando` no cargan `.zshrc`.
  Homebrew y `~/.local/bin` viven en `.zshenv` (Mac: `macos/zsh/.zshenv`).
  Síntoma clásico: `command not found: mosh-server|herdr` al conectar.
- **etserver en la Mac tras reboot**: `brew services start et` corre como
  user; para auto-start real de sistema: `sudo brew services start et`.

## Troubleshooting rápido

| Síntoma | Causa probable | Fix |
|---|---|---|
| `Connection refused :8022` | sshd de Termux no corre | abrir Termux (autostart en `.bashrc`) o `sshd` |
| `Operation timed out` a un Android | Tailscale desconectado/dormido | app Tailscale → Connect; batería sin restricciones |
| `Permission denied (publickey)` | pubkey no autorizada en el destino | append a `~/.ssh/authorized_keys` del destino |
| touch no funciona en herdr móvil | conectaste con mosh | usar `h`/`ha` (van por ET) |
| `command not found` al conectar | PATH no-interactivo | ver `.zshenv` (arriba) |
