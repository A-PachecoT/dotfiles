#!/data/data/com.termux/files/usr/bin/bash
# termux-bootstrap.sh — alta de un dispositivo Android (Termux) al mesh
# =====================================================================
# Uso: pegar este script COMPLETO en Termux (o curl desde el repo) DESPUÉS
# de correr a mano:  pkg update -y && pkg install -y openssh mosh et termux-api
# (el pkg install va separado: sus prompts se comen las líneas pegadas después).
#
# Qué hace: genera key propia, autoriza a los workers (Mac + Arch), escribe
# ~/.ssh/config con los hosts del mesh, ~/.bashrc con aliases h/ha + sshd
# autostart, arranca sshd (puerto 8022) e imprime la pubkey para autorizarla
# en los workers.
#
# Post-manual en Android: Ajustes → Batería → "Sin restricciones" para
# Termux Y Tailscale (si no, Android mata sshd/el túnel). Opcional:
# Termux:Boot (F-Droid) para sshd tras reboot sin abrir la app.
#
# Topología completa: ver docs/device-mesh.md

set -e

MESH_MAC_IP="100.73.150.52"
MESH_ARCH_IP="100.84.249.22"
MESH_CELU_IP="100.113.92.48"
MESH_TABLET_IP="100.108.156.30"

# --- key propia (una por dispositivo, revocable individualmente) ---
mkdir -p ~/.ssh && chmod 700 ~/.ssh
[ -f ~/.ssh/id_ed25519 ] || ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""

# --- autorizar workers ---
add_key() { grep -qxF "$1" ~/.ssh/authorized_keys 2>/dev/null || echo "$1" >> ~/.ssh/authorized_keys; }
add_key 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIcMsTYqLoyRnH5nOXfZduGkPoPW6wltE/fJdXa+U0O8 mac'
add_key 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINGMBnMfp5MW2SRNSIKLwaL5pNbzjAOYFJLmctL06AQM arch'
chmod 600 ~/.ssh/authorized_keys

# --- hosts del mesh ---
cat > ~/.ssh/config <<EOF
Host mac
	HostName $MESH_MAC_IP
	User styreep
	ServerAliveInterval 60

Host arch razer
	HostName $MESH_ARCH_IP
	User andre
	ServerAliveInterval 60

Host celu
	HostName $MESH_CELU_IP
	Port 8022
	ServerAliveInterval 60

Host tablet
	HostName $MESH_TABLET_IP
	Port 8022
	ServerAliveInterval 60
EOF
chmod 600 ~/.ssh/config

# --- shell: sshd autostart + aliases del mesh ---
# ET y no mosh: mosh NO pasa el mouse/touch (validado 2026-07-14); ET sí,
# y reconecta solo ante cortes de red.
cat > ~/.bashrc <<EOF
# autostart sshd al abrir Termux (puerto 8022)
pgrep -x sshd >/dev/null || sshd
# mesh: h = herdr Mac | ha = herdr Arch (mismos aliases en las 4 cajas)
alias h="et styreep@$MESH_MAC_IP -c herdr"
alias ha="et andre@$MESH_ARCH_IP -c herdr"
EOF

sshd 2>/dev/null || true
echo "=================================================="
echo "✓ dispositivo listo — autoriza esta key en los workers:"
echo "  (Mac y Arch: append a ~/.ssh/authorized_keys)"
cat ~/.ssh/id_ed25519.pub
echo "=================================================="
