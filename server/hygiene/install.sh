#!/usr/bin/env bash
# Instala la higiene de disco (Docker + runners de CI) en un host Linux con systemd (idempotente). Uso: sudo ./install.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
for n in docker-hygiene runner-hygiene; do
  install -m 0755 "$here/$n.sh" "/usr/local/sbin/$n.sh"
  install -m 0644 "$here/$n.service" "$here/$n.timer" /etc/systemd/system/
done
systemctl daemon-reload
systemctl enable --now docker-hygiene.timer runner-hygiene.timer
systemctl list-timers docker-hygiene.timer runner-hygiene.timer --no-pager
