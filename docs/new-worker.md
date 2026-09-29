# Sumar un worker al mesh

> Un **worker** es una caja más donde corren agentes Claude Code de André (hoy: Mac, Arch,
> `hq`). Un comando lo arma desde una caja que ya está armada, y lo que no se puede
> automatizar (logins y secretos) sale al final como lista de pasos humanos.
> Establecido 2026-09-29 con `hq` (cofoundy-hq) como caso de prueba. Mesh: `docs/device-mesh.md`.

```bash
~/dotfiles/scripts/new-worker.sh <ssh-host> <alias> --dry-run   # qué haría
~/dotfiles/scripts/new-worker.sh <ssh-host> <alias>             # lo hace
```

Córrelo **desde la Arch** (herdr se copia binario a binario y tiene que coincidir SO/arquitectura;
desde la Mac ese paso falla con un mensaje claro). Necesita bash ≥ 4 (en la Mac: `brew install bash`).
Exit: `0` = todo lo automatizable está hecho · `2` = faltan clones privados porque el worker aún no
tiene `gh auth` (haz ese paso humano y re-córrelo) · `1` = algo falló.

## Dos capas, un comando

| Capa | Qué es | De dónde sale |
|---|---|---|
| **dotfiles** (la caja) | paquetes, perfil `server` de `install.sh`, herdr, Eternal Terminal, swap + systemd-oomd, alias del mesh | este repo: `install.sh`, `server/bootstrap-ubuntu.sh`, `shared/zsh/mesh.zsh` |
| **Cofoundy** (el workspace) | `~/cofoundy` con sus repos, el symlink de `~/cofoundy/CLAUDE.md`, marketplaces y plugins de Claude Code, settings, secretos | lo que tenga **la caja fuente**; los secretos, por `ensure-keys.sh` del toolkit |

`/workspace-setup` es el onboarding Cofoundy **de una persona** (tier, cuenta de Vaultwarden, repos
según su acceso). `new-worker.sh` no lo reemplaza: **clona el estado de la caja fuente de André** a
otra caja suya. Lo único que ambos comparten es la ruta de secretos (`ensure-keys.sh`), y esa queda
siempre como paso humano: el script nunca ve, pasa por argv ni imprime un secreto.

## Antes (humano, una vez)

Ubuntu instalado (Server basta), un usuario con tu key en `authorized_keys`, `sudo` sin password
(`echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$USER`) y Tailscale arriba
(`sudo tailscale up`). Una entrada en `~/.ssh/config` de la caja fuente ayuda (`Host hq`). El
preflight aborta sin cambiar nada si falta cualquiera de estas.

## El orden y cómo se verifica cada paso

| Paso | Qué hace | Verificación por efecto |
|---|---|---|
| a · preflight | ssh sin prompt, SO, sudo, IP de Tailscale | aborta si no es Ubuntu, si ssh o sudo piden algo, o si no hay IP `100.x` |
| b · dotfiles | clone https, `bootstrap-ubuntu.sh`, `./install.sh server`; restaura `shared/git/.gitconfig` si gh lo ensució | dpkg de los 22 paquetes + `stow -n` sin links pendientes; `ssh <host> 'echo $PATH'` **no interactivo** contiene `~/.local/bin` |
| c · herdr | copia `~/.local/bin/herdr` si falta o es más viejo | `herdr --version` en el worker = el local |
| d · ET | PPA `jgmath2000/et`, `et.service`, terminfo `xterm-ghostty` | puerto 2022 alcanzable **desde la caja fuente** |
| e · memoria | swapfile hasta que swap ≥ RAM (en fstab) + systemd-oomd con los drop-ins de hq | `systemctl show`: `-.slice` `ManagedOOMSwap=kill`, `user@UID` presión `kill` con límite ≠ 0 |
| f · herramientas | Claude Code (installer oficial), `gh` (repo cli.github.com fijado a 1001), `bw` (npm en `~/.local`) + `bw config server` | `--version` de cada uno; `bw config server` = `https://vault.cofoundy.dev` |
| g · workspace | credential helper per-box, clones https de los repos de la fuente, `~/cofoundy/CLAUDE.md`, `./install.sh claude`, marketplaces, plugins, settings no secretos + `autoMemoryEnabled: false` | N/N repos, marketplaces y plugins; hooks renderizados = los de `settings.json`; `~/.herdr/CLAUDE.md` enlazado |
| h · mesh | `MESH_<ALIAS>` + `alias <alias>="et $MESH_… -c herdr"` en Darwin y Linux, y en `termux-bootstrap.sh`; commit + push | `zsh -n mesh.zsh`; aborta si el alias ya es de otra caja |
| i · pasos humanos | lista solo los que faltan, medidos en el worker | `gh auth status`, `~/.claude/.credentials.json`, cantidad de claves en `env`, `bw status`, `claude mcp list` |

Qué se copia de la fuente y qué no: los repos son los **clones reales** (`.git` directorio) de
`~/cofoundy` a profundidad ≤ 3, sin `.staging` ni worktrees (un `.git` archivo es trabajo en vuelo
de esa caja). Los plugins son los instalados **y** declarados en `enabledPlugins` (así uno retirado,
como `cofoundy-docs`, que sigue en el cache de la Arch, no se propaga). De `settings.json` viaja una
allowlist de claves, y del `env` solo lo que no huele a credencial; los hooks y los secretos del
worker se conservan.

**Al terminar:** haz los pasos humanos, re-corre el script (tiene que dar `0 cambio(s)` y exit 0) y
agrega la fila del worker a la tabla de topología de `docs/device-mesh.md`. Si la caja es compartida
con el equipo, su runbook va al handbook (como `cofoundy-hq.md`).

## Pasos humanos (el script imprime los comandos exactos)

1. **GitHub:** `gh auth login -h github.com -p https -w`, y a «Authenticate Git with your GitHub
   credentials?» responde **No**: el helper ya está en `~/.config/git/config`.
2. **Claude Code:** `claude` → `/login`.
3. **Secretos:** `CLAUDE_ENV_FILE=$(mktemp) bash <ensure-keys.sh del cache>`. Necesita el paso 1:
   lee la credencial del provisioner desde GitHub y deja las claves en el `env` de `settings.json`.
4. **Bitwarden personal** (escrituras al vault), **después** del 3, porque `ensure-keys.sh` hace
   `bw logout` al terminar: `bw login andre@cofoundy.dev` y `export BW_SESSION="$(bw unlock --raw)"`.
5. **MCP de la caja:** `claude` → `/mcp` (en hq: `basalt` y `figma`). Los conectores «claude.ai …»
   son de la cuenta, no de la caja: se autorizan en claude.ai y el script no los cuenta.

## Trampas medidas

- **4 GB de swap cuelgan la caja.** El 2026-09-29 hq (14 GB) se colgó entera con 11 sesiones de
  Claude, ~10 procesos Python y el CI: hubo que apagarla a mano. Desde entonces: swap ≥ RAM (16 GB)
  y systemd-oomd, que mata al cgroup más pesado (puede ser herdr o un agente) en vez de colgar todo.
- **≤ 4 sesiones de agente a la vez en 14 GB** cuando la caja además carga staging y runners. Una
  caja dedicada da más, pero mídelo antes de subir el techo.
- **`gh auth setup-git` pisa el `.gitconfig` compartido.** `~/.gitconfig` es el symlink a
  `shared/git/.gitconfig`, así que gh escribe su helper, con path absoluto, en el repo. El helper
  vive per-box en `~/.config/git/config` (el script lo escribe) y el paso b restaura el archivo
  compartido si solo tiene cambios de credential helper.
- **Ubuntu reporta `graphical.target` sin escritorio.** hq (Ubuntu Server) lo hace, así que
  `systemctl get-default` no sirve para detectar un headless. `install.sh` detecta por display
  manager y sesiones instaladas, y el script fuerza igual `./install.sh server`.
- **ET no está en el apt de Ubuntu 26.04**: solo en el PPA `jgmath2000/et`.
- **El ssh no interactivo no ve `~/.local/bin`**: el `~/.bashrc` de Ubuntu hace `return` antes de
  todo. `bootstrap-ubuntu.sh` mete el PATH en la primera línea, y el paso b lo prueba por efecto.
- **`x | grep -q` con `pipefail` da falsos negativos** (141 por SIGPIPE cuando grep sale antes que
  `x`). Le pasó al propio script en su primera corrida: vio un marketplace como ausente y lo re-agregó
  (no-op). Por eso los scripts remotos corren sin `pipefail` y comparan con here-strings.

## Mantenimiento

Si cambia cómo quedó armado un worker (un drop-in, un repo apt, una clave de settings), el cambio va
**en el script**, y se prueba con `--dry-run` y dos corridas reales contra `hq`: la segunda tiene que
dar `0 cambio(s)` y exit 0.
