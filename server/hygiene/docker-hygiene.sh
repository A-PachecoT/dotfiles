#!/usr/bin/env bash
# docker-hygiene.sh — higiene de disco de un host Docker con runners de CI (cofoundy-hq).
#
# Por qué (2026-10-06): los service containers de CI (postgres/redis declaran VOLUME) dejaron
# 888 volúmenes anónimos huérfanos = 26 GB; el disco de hq llegó al 100 % y los runners de
# inbox-ai cayeron en loop con «No space left on device». Fix de raíz: tmpfs en ci.yml
# (inbox-ai#1894). Esto es la red: que ninguna fuga futura vuelva a llenar el disco.
#
# Sólo borra lo que ningún contenedor (corriendo o parado) referencia:
#   - volúmenes anónimos huérfanos (`docker volume prune` sin -a: los con nombre no se tocan)
#   - imágenes colgantes (sin tag) y caché de build de más de 7 días
# Si el disco sigue sobre UMBRAL_PCT, además borra imágenes sin usar de más de 3 días y lo dice.
# Log → journald (`journalctl -u docker-hygiene`). Exit 0 siempre que docker responda.
set -euo pipefail
UMBRAL_PCT="${UMBRAL_PCT:-85}"

uso() { df --output=pcent / | tail -1 | tr -dc '0-9'; }
antes=$(uso)
vol=$(docker volume prune -f | tail -1)
img=$(docker image prune -f | tail -1)
bld=$(docker builder prune -f --filter until=168h | tail -1)
echo "disco ${antes}% → $(uso)% · volúmenes: ${vol} · imágenes: ${img} · build: ${bld}"

if [ "$(uso)" -ge "$UMBRAL_PCT" ]; then
  echo "AVISO: disco en $(uso)% (≥ ${UMBRAL_PCT}%) tras la higiene; borro imágenes sin usar de > 72 h" >&2
  docker image prune -af --filter until=72h | tail -1
  echo "disco tras el modo agresivo: $(uso)%" >&2
fi
