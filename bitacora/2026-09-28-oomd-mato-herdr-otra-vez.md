# 2026-09-28 — oomd volvió a matar herdr: scope por panel

## Contexto
18:58: swap 19G/19G, carga en 52, presión de I/O al 95 %. systemd-oomd mató varios `kitty-*.scope`, los dos `hermes-gateway` y al final `herdr.service` (12,1 G), que es el que tenía todos los paneles adentro. `ManagedOOMPreference=avoid` estaba puesto (xattr `user.oomd_avoid=1` confirmado), pero solo hace que oomd lo deje para el final; con la presión sostenida igual le tocó.

## Qué llenó la memoria
- ~20 claude + **21 playwright-mcp**: el MCP había vuelto a registrarse a nivel usuario en `~/.claude.json` (`~/.mcp.json` estaba vacío, por eso parecía apagado).
- **/tmp es tmpfs** y ocupaba 8,9 G: 7 G eran worktrees completos de inbox-ai (con `backend/.venv`) que los agentes creaban en su scratchpad, que nunca se limpia.
- `pytest -n 8` (~2,4 G) fue lo que terminó de llenar el swap.
- Dos `next-server` de worktrees viejos con 4,3 G en swap.

## Qué se hizo
- `claude mcp remove -s user playwright`.
- `git worktree remove` de los worktrees del scratchpad (/tmp 8,9 → 6,4 G). Se quitaron 10 por antigüedad antes de acordar el criterio «solo mergeados»; todos estaban limpios y las ramas siguen existiendo.
- Regla en `shared/claude/CLAUDE.md`: los worktrees van en `~/.herdr/worktrees/<repo>/<nombre>`, nunca en el scratchpad ni en /tmp.
- `linux/zsh/.config/zsh/conf.d/00-herdr-pane-scope.zsh`: toda shell interactiva cuyo cgroup es `herdr.service` se mueve a su propio `herdr-pane-<pid>.scope` (StartTransientUnit vía busctl, sin exec: si falla, la shell sigue igual). oomd pasa a matar el panel más gordo en vez de herdr entero.
- Migración en vivo de los paneles ya abiertos (árbol de procesos completo, `pstree -pT`, sin TIDs) → en `herdr.service` quedó solo el server.

## Learnings
- herdr hace double-fork: las shells de los paneles cuelgan de `systemd --user` (ppid 946), no del server. Se detectan por el cgroup, no por el ppid.
- `pstree -p` lista los hilos como `{name}(tid)`; pasarle esos TIDs a `PIDs` hace fallar StartTransientUnit con ENOENT. Hay que usar `-T`.
- StartTransientUnit es asíncrono: el cgroup cambia un instante después de que vuelve la llamada.
