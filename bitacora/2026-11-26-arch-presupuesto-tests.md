# 2026-11-26 — Arch ahogado otra vez: presupuesto de caja para tests (slice + turnos + barredor)

## Contexto
14:07: load 291 en 16 cores, swap 19/19G, 33 sesiones. Tres sitios `/cto` de tracta (compositor-ia, formularios-meta, senales-meta)
corrían a la vez 3 vitest (~8G entre los tres) y pytest-xdist (~15 workers), con 17 claude encima. André: «pasa casi todos los días».

## Por qué el guard del 14-nov no alcanzó
- Capeaba CADA corrida (8G), no cuántas juntas: 3 × 8G no caben en 31G.
- Dos pytest corrían fuera de su scope, en `hc-hold-*.service` (el holder de paneles de la Herdr app, 10G RAM + 10G swap sin techo).

## Qué se hizo
- Matar los 3 vitest → disponible 4G → 11G, load 291 → 114.
- `linux/agent-heavy` (stow): `agent-heavy.slice` (MemoryHigh 12G, MemoryMax 14G, MemorySwapMax 2G, CPU/IO weight 20);
  `agent-heavy run` = turnos con flock (máx. 2, `AGENT_HEAVY_SLOTS`) + scope 8G/RuntimeMaxSec 1h en el slice;
  `agent-heavy sweep` cada 10 s (timer) mueve al slice, vía `StartTransientUnit` con `PIDs`, todo árbol pytest/vitest/jest/next build/tsc/mypy
  del user manager que esté fuera. `next dev`/`next-server` NO entra (es servidor, no corrida).
- `claude-guard-test-load.py` reescribe a `agent-heavy run` si existe; si no, el scope de antes con `--slice=agent-heavy.slice`.

## Validación
- 35 tests (guard + agent-heavy) en Mac; ruff limpio.
- Arch: el primer sweep movió 4 árboles; el timer atrapó un pytest nuevo en el primer tick. Load 25 a los 7 min.
- 3 `agent-heavy run` simultáneos: dos a 6 s, el tercero esperó turno (12 s), los tres en el slice, exit code 3 propagado.
- Hook real en Arch: `npx vitest run` → `agent-heavy run -- /usr/bin/zsh -c '…'`.

## Learnings
- Un tope por corrida sin tope de concurrencia no es un presupuesto: falta la suma.
- systemd trata el guion de un slice como jerarquía: `agent-heavy.slice` vive en `agent.slice/agent-heavy.slice`. Inocuo aquí.
- Un barredor que mueve procesos al cgroup cubre lo que un hook no ve (background, `hc run`, subagentes).

## Pendiente (opción E de la sesión)
- Swap lleno por sesiones ociosas (claudes de 6-12 días, `next-server` con 3.6G en swap). Recolectarlas toca sesiones de André: decide él.
