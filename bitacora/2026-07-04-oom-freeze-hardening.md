# 2026-07-04 — OOM freeze del Arch box + hardening

**Operador:** André (+ Claude)

---

## Contexto

El box Arch headless (dev sandbox, 31 GB RAM, 4 GB zram, sin swap en disco) se
**murió de madrugada ~3am**. André lo prendió a la mañana y pidió debug. El box
corre el worker; André está en macOS via ET. Había mandado un **CTO nocturno**
a trabajar intenso.

---

## Qué Pasó

### Diagnóstico (systematic-debugging)

- `who -b` / `journalctl --list-boots`: boot anterior corrió May 30 → **Jul 04
  03:17:30**, luego el box quedó **apagado ~4h** hasta reencendido manual 07:36.
- **Sin apagado limpio** (último `Reached target Shutdown` = May 30, arranque de
  ese boot) → **freeze duro**, no reboot.
- **49 eventos OOM-killer** esa noche + watchdog timeouts en `journald`,
  `logind`, `networkd` → hasta los daemons core dejaron de responder = **livelock
  por OOM**.

Cascada Jul 3→4:

| Hora | Muerto |
|------|--------|
| 00:20–02:32 | **chrome headless OOM-killed 5×**, ~1.45 TB VM c/u |
| 02:53 | `hermes-gateway` (python) |
| 02:54 | `hermes-quipu` (python) |
| 03:11 | `syncthing` |
| 03:12–03:17 | thrashing total → freeze |

### Atribución (clave)

Los chrome muertos estaban en cgroups **`tmux-spawn-*.scope` y
`session-440.scope`** = **sesión interactiva del CTO en tmux**, NO en
`app.slice/hermes-*.service`. hermes fue *víctima*, no leaker. Los runners de
CI (`actions.runner.cofoundy-*`) también ejecutaron jobs a las 22:14, 02:32 y
03:12 → el CTO **pusheaba commits toda la noche**, disparando CI self-hosted en
cada push. Doble flanco: **QA browsers leaked + CI en cada push**.

### Causa raíz del leak de browsers

`agent-browser` (v0.26.0, dep de `hermes-agent`) usa un **daemon que persiste el
browser entre comandos**. Por README, el daemon **solo se auto-cierra si se setea
`AGENT_BROWSER_IDLE_TIMEOUT_MS`** — que **no estaba seteado**. Cerrar es regla
blanda del agente (incluso exceptuada "si el parent pide mantener la sesión").
→ cada sesión de QA quedó huérfana y se acumuló. `chrome-guardian` existía
(commit `6883f36`, Jun 5) pero **inactivo** y solo mata por **CPU**, no RAM.

### Fixes shipeados

1. **systemd-oomd** activado + enabled. Drop-ins en `/etc`:
   - `oomd.conf.d/10-cofoundy.conf` (SwapUsedLimit 90%, MemPressureLimit 60%/20s)
   - `-.slice.d/10-oomd-root-swap.conf` → `ManagedOOMSwap=kill` (red global, cubre CI)
   - `user@.service.d/10-oomd-mempressure.conf` → `ManagedOOMMemoryPressure=kill` 50% (mata el cgroup del agente antes del livelock). Verificado con `oomctl`.
2. **Caps de memoria en los 9 runners**: `actions.runner.*.service.d/10-memory-cap.conf` → `MemoryHigh=6G` / `MemoryMax=8G`. Aplicado en vivo (restart, sin jobs corriendo).
3. **Idle-reap del browser**: `~/.config/environment.d/10-agent-browser.conf` +
   export en `linux/zsh/.config/zsh/conf.d/50-agent-browser.zsh` →
   `AGENT_BROWSER_IDLE_TIMEOUT_MS=600000` (10 min). **hermes NO lleva timeout**
   (la var solo afecta al subproceso del browser).
4. **Migración CI self-hosted → GitHub-hosted** (minutos mensuales reseteados):
   `basalt-landing`, `landing-page-v3` (clones locales, push directo) y
   `xgodel-landing` (vía Contents API, no clonado) → `runs-on: ubuntu-latest`.
   Los 3 `deploy.yml` decían explícitamente que el self-hosted era temporal por
   el billing cap agotado. Cero dependencia local del box (builds pnpm + deploy
   a Cloudflare Pages con GitHub secrets).

### Validación

- `oomctl`: swap-kill en `/`, mem-pressure-kill en `user@1000` (límite 50%/20s). ✅
- Runners: `MemoryMax=8G` vivo en los 9, todos `active`. ✅
- 3 runs GH-hosted **verdes**: basalt-landing (e2e+deploy+smoke), landing-page-v3,
  xgodel-landing → todos `completed | success`. El solo hecho de que arrancaran
  confirma que los minutos ya están disponibles.

---

## Aprendizaje

- `agent-browser` persiste el browser **indefinidamente** salvo que se setee
  `AGENT_BROWSER_IDLE_TIMEOUT_MS`; cerrar es regla blanda → en runs autónomas
  largas (CTO nocturno) los browsers se fugan y agotan RAM.
- El kernel OOM-killer solo NO alcanza en cargas anon-heavy: llega tarde y
  produce **livelock**. Hace falta `systemd-oomd` (PSI/cgroup-aware) como early-kill.
- Atribuir un OOM por **cgroup del victim** (`task_memcg`) separa al *leaker* real
  del *víctima*: hermes/syncthing eran víctimas; el leaker era el CTO en tmux.
- Un guardián por **CPU** (`chrome-guardian`) no cubre leaks por **RAM** — son ejes
  distintos; y un guardián symlinkeado pero no `enable --now` es no-op.
- CI self-hosted en el box acopla la salud del hardware a cada push del agente;
  hosted runners lo desacoplan (cuando el billing lo permite).

---

## Acción

- `/etc/systemd/oomd.conf.d/10-cofoundy.conf`, `/etc/systemd/system/-.slice.d/`,
  `/etc/systemd/system/user@.service.d/`, `.../actions.runner.*.service.d/` (root, en el box, fuera del repo)
- `~/.config/environment.d/10-agent-browser.conf` (en el box)
- `linux/zsh/.config/zsh/conf.d/50-agent-browser.zsh` (dotfiles, SSOT)
- Pushes: `cofoundy/basalt-landing@8fc4d3a`, `cofoundy/landing-page-v3@1fe99c0`,
  `cofoundy/xgodel-landing@4ebe217` (`runs-on: self-hosted → ubuntu-latest`)
- Memoria: `arch-box-oom-hardening.md`
- Pendientes: subir zram/swap; dar dimensión RAM a `chrome-guardian` (o retirarlo);
  reiniciar `hermes-*` en algún momento para que hereden la var (no urgente).
