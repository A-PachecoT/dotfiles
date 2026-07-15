# Mesh de dispositivos: herdr en los workers desde cualquier caja
# ---------------------------------------------------------------
# Semántica única en todo el mesh (Mac, Arch, celu, tablet):
#   h  = herdr de la Mac
#   ha = herdr del Arch box
# Local → binario directo; remoto → ET (Eternal Terminal: auto-reconexión
# + mouse/touch passthrough fiel, validado 2026-07-14 — mosh rompe el touch).
# Los Termux (celu/tablet) definen estos mismos aliases en su ~/.bashrc
# (ver scripts/termux-bootstrap.sh).

MESH_MAC="styreep@100.73.150.52"    # Tailscale
MESH_ARCH="andre@100.84.249.22"     # Tailscale

case "$(uname -s)" in
  Darwin)
    alias h="herdr"
    alias ha="et $MESH_ARCH -c herdr"
    ;;
  Linux)
    alias h="et $MESH_MAC -c herdr"
    alias ha="herdr"
    ;;
esac

# Fan-out del mesh: pull dotfiles + reload herdr en AMBOS workers de un comando.
# Corré `mu` tras pushear cambios de config y las dos cajas quedan a la última,
# con los keybinds de herdr live. Ver scripts/mesh-update.sh.
alias mu="$HOME/dotfiles/scripts/mesh-update.sh"
alias mesh-update="$HOME/dotfiles/scripts/mesh-update.sh"
