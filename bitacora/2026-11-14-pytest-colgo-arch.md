# 2026-11-14 — un pytest de un agente colgó Arch dos veces en 10 min

**Operador:** André (+ Claude)

## Contexto
André vio Tracta (Vivaldi, la pestaña de Tracta, «Application Not Responding») colgada en Arch. Load 157 sobre 16 cores,
swap 19/19G, vmstat 98% `sys` y 2-4 GB/s de lectura de bloque: el kernel reclamando memoria, no CPU útil.

## Causa
El agente `chatgpt-mcp` (herdr app, tracta / 7) corrió la suite entera con `uv run pytest -n 8` (≈5.5G)
y, después de que lo maté, otra vez con `-n 10`. Lo pide la regla del repo
(`.claude/rules/backend-quality.md:109`, `-n 8`), afinada para el runner de CI, no para una caja con 13 agentes.
oomd no actuó: su kill por swap exige además RAM > 90%, y con 10G de page cache la RAM marcaba 84%.
El herdr TUI viejo (`herdr server`, 32 días arriba) tiene 8.8G en swap: no queda margen.

## Qué se hizo
- Maté las dos corridas (ojo: `pkill -f` por ssh se mata a sí mismo; y en zsh `kill $P` no separa la lista → `xargs`).
- `scripts/claude-guard-test-load.py` (PreToolUse Bash, en el template y parchado directo en el `settings.json`
  de Arch — `install.sh claude` habría borrado el `vault-write-gate-hook` que solo vive ahí). En Linux:
  capea `pytest -n` a max(2, nproc/4) y mete todo test/build en un scope `MemoryMax=8G`, `MemorySwapMax=1G`,
  `CPUWeight=20`/`IOWeight=20`. Reescribe vía `updatedInput`, no bloquea. Escape `TEST_LOAD_GUARD=off`.

## Validación
- 13 tests en `scripts/tests/test_guard_test_load.py` (Mac y Arch).
- Scope real en Arch: el comando corre en `app.slice/claude-guard-test-load-*.scope`, propaga el exit code,
  y un exceso de memoria vuelve 137 sin tocar a nadie más.
- E2E con `claude -p --model haiku` en Arch: el comando que ejecutó Claude cayó en el scope → el harness respeta `updatedInput`.
- Load 157 → 3.4 tras matar las corridas.

## Learnings
- El techo tiene que estar en la corrida, no en la sesión: un cap al slice entero frena a herdr junto con el culpable,
  y oomd elige el cgroup con más swap (el herdr viejo), no al que la está causando.
- Sesiones de Claude ya abiertas puede que no recarguen hooks: al agente culpable se le avisó por `hc send`.
