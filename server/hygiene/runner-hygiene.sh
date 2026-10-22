#!/usr/bin/env bash
# runner-hygiene.sh — higiene de disco de los runners de GitHub Actions (cofoundy-hq).
#
# Por qué (2026-10-22): el disco de hq llegó al 100 % otra vez, ahora sin culpa de Docker:
# 15 GB en los `_work` de 13 runners (checkouts, node_modules, _temp que nadie borra), 2,3 GB de
# `_diag` (6.500 logs por runner, desde septiembre) y 5,5 GB de cachés npm/pnpm/playwright de
# `gh-runner`. `deploy.sh` de staging abortaba por falta de espacio y el CI de todos los repos
# se frenaba. Además `hq-inbox-ai-light-3` llevaba 4 días caído por un OOM y nadie lo levantó.
#
# Qué hace, en orden:
#   1. `_work` de cada runner OCIOSO: lo vacía si pesa > WORK_MAX_MB o si el disco está ≥ UMBRAL_PCT.
#      El runner se para antes y se levanta después, para que no tome un job a mitad del borrado.
#      Un runner con `Runner.Worker` vivo (job en curso) no se toca.
#   2. `_diag`: borra logs de más de DIAG_DIAS días.
#   3. Cachés de `gh-runner` (npm, pnpm, uv, playwright) si el disco está ≥ UMBRAL_PCT y no hay
#      ningún job corriendo: todo se vuelve a bajar en el próximo job.
#   4. Runners habilitados en estado `failed` (OOM, disco lleno): reset-failed + start.
# Log → journald (`journalctl -u runner-hygiene`). Exit 0 salvo error inesperado.
set -euo pipefail
RAIZ="${RAIZ:-/opt/actions-runner}"
UMBRAL_PCT="${UMBRAL_PCT:-80}"
WORK_MAX_MB="${WORK_MAX_MB:-1500}"
DIAG_DIAS="${DIAG_DIAS:-7}"
USUARIO="${USUARIO:-gh-runner}"

uso() { df --output=pcent / | tail -1 | tr -dc '0-9'; }
servicio() { systemctl list-units --all --plain --no-legend "actions.runner.*.$1.service" | awk '{print $1}' | head -1; }
antes=$(uso)

for dir in "$RAIZ"/*/; do
  nombre=$(basename "$dir")
  [ -d "$dir/_work" ] || continue
  [ -n "$(ls -A "$dir/_work")" ] || continue
  if pgrep -f "$RAIZ/$nombre/bin/Runner.Worker" >/dev/null; then
    echo "$nombre: job en curso, no se toca"
    continue
  fi
  mb=$(du -sm "$dir/_work" | cut -f1)
  [ "$mb" -gt "$WORK_MAX_MB" ] || [ "$(uso)" -ge "$UMBRAL_PCT" ] || continue
  svc=$(servicio "$nombre")
  activo=no
  if [ -n "$svc" ] && systemctl is-active -q "$svc"; then
    activo=si
    systemctl stop "$svc"
  fi
  # Con el listener abajo no entra un job nuevo mientras se borra.
  find "$dir/_work" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
  [ "$activo" = si ] && systemctl start "$svc"
  echo "$nombre: _work vaciado (${mb} MB)"
done

find "$RAIZ"/*/_diag -type f -mtime +"$DIAG_DIAS" -delete 2>/dev/null || true

# Las cachés las comparten todos los runners: sólo se borran sin ningún job en curso.
if [ "$(uso)" -ge "$UMBRAL_PCT" ] && id "$USUARIO" >/dev/null 2>&1 && ! pgrep -f "$RAIZ/.*/bin/Runner.Worker" >/dev/null; then
  casa=$(getent passwd "$USUARIO" | cut -d: -f6)
  echo "AVISO: disco en $(uso)% (≥ ${UMBRAL_PCT}%); borro cachés de $USUARIO" >&2
  rm -rf "$casa/.npm/_cacache" "$casa/.cache/pnpm-store" "$casa/.cache/ms-playwright" "$casa/.cache/uv" "$casa/.cache/pip"
fi

for svc in $(systemctl list-units --all --plain --no-legend --state=failed 'actions.runner.*' | awk '{print $1}'); do
  systemctl is-enabled -q "$svc" || continue
  systemctl reset-failed "$svc"
  systemctl start "$svc" && echo "$svc: estaba caído, levantado"
done

echo "disco ${antes}% → $(uso)%"
