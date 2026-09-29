# Cada panel de herdr en su propio scope de systemd.
#
# Por qué: todos los paneles (claude, pytest, next dev, MCPs) vivían en el
# cgroup de herdr.service. Bajo presión de memoria systemd-oomd mata el cgroup
# más gordo, y ese era herdr entero con todos los paneles adentro (2026-09-14 y
# 2026-09-28). Con un scope por panel, oomd mata solo el panel más gordo.
#
# Se adopta el PID de la shell con StartTransientUnit (lo mismo que hace
# `systemd-run --scope`, pero sin exec): si falla, la shell sigue normal en
# herdr.service. Los hijos que arranque después heredan el scope.
[[ -o interactive ]] || return 0
[[ "$(</proc/$$/cgroup)" == */herdr.service ]] || return 0
(( $+commands[busctl] )) || return 0

busctl --user call org.freedesktop.systemd1 /org/freedesktop/systemd1 \
  org.freedesktop.systemd1.Manager StartTransientUnit 'ssa(sv)a(sa(sv))' \
  "herdr-pane-$$.scope" fail 3 \
  PIDs au 1 $$ \
  CollectMode s inactive-or-failed \
  Description s "herdr pane (shell $$)" \
  0 >/dev/null 2>&1
