# Cada panel de herdr en su propio scope de systemd.
#
# Por qué: todos los paneles (claude, pytest, next dev, MCPs) vivían en el
# cgroup de herdr.service. Bajo presión de memoria systemd-oomd mata el cgroup
# más gordo, y ese era herdr entero con todos los paneles adentro (2026-09-14 y
# 2026-09-28). Con un scope por panel, oomd mata solo el panel más gordo.
#
# Se adopta el PID de la shell con StartTransientUnit (lo mismo que hace
# `systemd-run --scope`, pero sin exec): si falla, la shell sigue normal donde
# estaba. Los hijos que arranque después heredan el scope.
#
# El panel se reconoce por HERDR_ENV, no por el cgroup del server: el
# 2026-10-17 el server vivía en session-6.scope (no en herdr.service), el chequeo
# por cgroup no disparaba y los 23 claude compartían cgroup con herdr.
[[ -o interactive ]] || return 0
[[ ${HERDR_ENV:-} == 1 ]] || return 0
[[ "$(</proc/$$/cgroup)" == */herdr-pane-*.scope ]] && return 0
(( $+commands[busctl] )) || return 0

busctl --user call org.freedesktop.systemd1 /org/freedesktop/systemd1 \
  org.freedesktop.systemd1.Manager StartTransientUnit 'ssa(sv)a(sa(sv))' \
  "herdr-pane-$$.scope" fail 3 \
  PIDs au 1 $$ \
  CollectMode s inactive-or-failed \
  Description s "herdr pane (shell $$)" \
  0 >/dev/null 2>&1
