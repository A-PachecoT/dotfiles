# 2026-10-17 — Arch colgado: 5 next dev en paralelo y herdr fuera de su servicio

## Contexto
12:58: load 290, swap 19G/19G, PSI de memoria e I/O al ~94 %. oomd todavía no había matado nada. El orquestador `redesign-ui` (pane `w8W:p1`) tenía 5 subagentes en worktrees de inbox-ai (`redesign-mensajes/ventas/agente/ajustes`, más `reservas-modos`), cada uno con su propio `next dev` (~2 G) y dos `vitest` (3,5 G y 2,6 G), con 23 claude en la caja.

## Qué se hizo
- Se mataron los `next-server` y `vitest` → la RAM disponible subió de 5 a 15 G y la presión bajó a ~1 % en un minuto. Los subagentes los relanzaron en segundos. Se le mandó al orquestador vía `herdr --machine arch pane run` la regla: un solo `next dev` a la vez en toda la caja, `vitest --maxWorkers=2` solo con los archivos tocados, builds y tests en serie.
- **Hallazgo:** el `herdr server` (pid 4994) vivía en `session-6.scope`, la sesión ET del Mac, no en `herdr.service`. Al bootear el 12-10, `et -c herdr` llegó a las 14:47:49 y el cliente levantó su propio server. `herdr.service` (con `After=default.target`, atrasado 2 min por `ddev-fiorella.service`) arrancó a las 14:48:50 y desde entonces falló cada 2 s: 189 601 reinicios («already running»). Sin `ManagedOOMPreference=avoid` y sin scopes por panel, porque el hook buscaba el cgroup `herdr.service`. Los 23 claude compartían cgroup con herdr: el escenario del 14-09.
- Migración en vivo, sin reiniciar herdr (script en el scratchpad de la sesión, `StartTransientUnit` vía busctl): server → `herdr-server.scope` con `ManagedOOMPreference=avoid`; los 30 paneles → `herdr-pane-<pid>.scope`; los 96 árboles huérfanos (ppid 1: next dev en background, zsh viejas) → `herdr-orphan-<pid>.scope`. 127 ok, 0 fallas. En `session-6` quedaron solo el ET, su zsh y el cliente herdr.
- `herdr.service` entra a dotfiles (`linux/herdr`, stow): sin `After=default.target` y con `ExecCondition` que lo salta si ya corre un server (probado: `Result=exec-condition`, 0 reinicios).
- `00-herdr-pane-scope.zsh` reconoce el panel por `HERDR_ENV=1` y no por el cgroup del server (probado: con `HERDR_ENV` cae en `herdr-pane-*.scope`; sin él se queda en su sesión).

## Learnings
- Cuando el server lo levanta un cliente, los paneles son hijos directos del server: no hay double-fork como bajo `herdr.service`. Los huérfanos quedan con ppid 1, porque un session scope no tiene subreaper.
- `pkill -f patrón` dentro de `ssh host '…'` mata la propia shell remota, porque su cmdline contiene el patrón. Usar `[n]ext-server`.
- `After=default.target` en un servicio `WantedBy=default.target` lo pone detrás de la unidad más lenta del boot.
- `Restart=always` + «already running» = loop eterno silencioso. `ExecCondition` lo convierte en «skipped».
