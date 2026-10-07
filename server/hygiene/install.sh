#!/usr/bin/env bash
# Instala la higiene Docker en un host Linux con systemd (idempotente). Uso: sudo ./install.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
install -m 0755 "$here/docker-hygiene.sh" /usr/local/sbin/docker-hygiene.sh
install -m 0644 "$here/docker-hygiene.service" "$here/docker-hygiene.timer" /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now docker-hygiene.timer
systemctl list-timers docker-hygiene.timer --no-pager
