#!/usr/bin/env bash
# new-worker.sh — suma un «worker» (una caja más donde corren agentes Claude Code) al mesh.
#
# Uso:   scripts/new-worker.sh <ssh-host> <alias> [--dry-run]
#        <ssh-host>  cómo llega ssh desde ESTA caja (entrada de ~/.ssh/config o user@ip)
#        <alias>     alias corto del mesh (h/ha/hq…): define MESH_<ALIAS> y `alias <alias>=et … -c herdr`
#        --dry-run   no cambia nada: reporta qué haría en cada paso
#
# Se corre desde una caja YA armada (Arch o Mac): de ella copia herdr, la lista de repos de
# ~/cofoundy, los marketplaces/plugins de Claude Code y los settings no secretos.
# Idempotente: cada paso verifica por EFECTO y se salta si ya está. Nunca pasa secretos por
# argv ni los imprime; los secretos entran por los PASOS HUMANOS del final.
#
# Exit: 0 = todo lo automatizable está hecho (puede haber pasos humanos pendientes, se listan)
#       2 = faltan clones privados porque el worker aún no tiene `gh auth` → paso humano y re-correr
#       1 = algún paso falló
# Runbook: docs/new-worker.md
set -uo pipefail
# `remote … | relay` tiene que correr relay en ESTE shell (si no, los contadores y el exit
# code se pierden en un subshell): lastpipe, que pide bash ≥ 4 (en la Mac: brew install bash).
if [ "${BASH_VERSINFO[0]:-0}" -lt 4 ]; then echo "new-worker.sh necesita bash ≥ 4 (tienes $BASH_VERSION): brew install bash" >&2; exit 1; fi
shopt -s lastpipe

usage() { awk 'NR>1 && /^#/ { sub(/^# ?/, ""); print; next } NR>1 { exit }' "$0"; exit "${1:-1}"; }

HOST="" ALIAS="" DRY=0
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1 ;;
    -h|--help) usage 0 ;;
    -*) echo "flag desconocido: $a" >&2; usage ;;
    *) if [ -z "$HOST" ]; then HOST=$a; elif [ -z "$ALIAS" ]; then ALIAS=$a; else usage; fi ;;
  esac
done
[ -n "$HOST" ] && [ -n "$ALIAS" ] || usage
case "$ALIAS" in *[!a-z0-9]*|"") echo "alias inválido: '$ALIAS' (solo [a-z0-9])" >&2; exit 1 ;; esac
ALIAS_UP=$(printf '%s' "$ALIAS" | tr '[:lower:]' '[:upper:]')

DOTFILES="$HOME/dotfiles"
WS="$HOME/cofoundy"
MESH_FILE="$DOTFILES/shared/zsh/mesh.zsh"
TERMUX_FILE="$DOTFILES/scripts/termux-bootstrap.sh"
ET_PPA="ppa:jgmath2000/et"
VAULT_URL="https://vault.cofoundy.dev"

# ── salida ───────────────────────────────────────────────────────────────────
N_CHANGED=0 N_FAIL=0 N_PENDING=0 CLONES_BLOCKED=0
step()    { printf '\n\033[1m[%s] %s\033[0m\n' "$1" "$2"; }
ok()      { printf '  ok  %s\n' "$1"; }
changed() { printf '  ++  %s\n' "$1"; N_CHANGED=$((N_CHANGED+1)); }
plan()    { printf '  ~~  (dry-run) %s\n' "$1"; N_CHANGED=$((N_CHANGED+1)); }
pend()    { printf '  ..  %s\n' "$1"; N_PENDING=$((N_PENDING+1)); }
warn()    { printf '  !!  %s\n' "$1"; }
fail()    { printf '  XX  %s\n' "$1"; N_FAIL=$((N_FAIL+1)); }
die()     { fail "$1"; printf '\nabortado en preflight: nada se cambió.\n'; exit 1; }

# ── ssh: una sola conexión multiplexada, sin prompts ─────────────────────────
CM_DIR=$(mktemp -d "${TMPDIR:-/tmp}/nw.XXXXXX")
SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=10 -o ControlMaster=auto
          -o "ControlPath=$CM_DIR/%C" -o ControlPersist=120)
cleanup() { ssh "${SSH_OPTS[@]}" -O exit "$HOST" >/dev/null 2>&1; rm -rf "$CM_DIR"; }
trap cleanup EXIT
# R 'cmd'          → comando remoto con ~/.local/bin en PATH
# RS arg… <<'EOS'  → script remoto por stdin; args como $1…
R()  { ssh "${SSH_OPTS[@]}" "$HOST" "export PATH=\"\$HOME/.local/bin:\$PATH\"; $1"; }
RS() { ssh "${SSH_OPTS[@]}" "$HOST" 'export PATH="$HOME/.local/bin:$PATH"; bash -s --' "$@"; }
# remote DRY args… <<'EOS' → REMOTE_LIB + PRELUDE (variables ya citadas) + el heredoc, por stdin
PRELUDE=""
remote() { { printf '%s\n' "$REMOTE_LIB" "$PRELUDE"; cat; } | RS "$@"; }

# Absorbe las líneas de estado de un script remoto: "OK|CHANGED|PLAN|PEND|WARN|FAIL <texto>"
relay() {
  local tag rest
  while IFS= read -r line; do
    tag=${line%% *}; rest=${line#* }
    case "$tag" in
      OK) ok "$rest" ;; CHANGED) changed "$rest" ;; PLAN) plan "$rest" ;;
      PEND) pend "$rest" ;; WARN) warn "$rest" ;; FAIL) fail "$rest" ;;
      BLOCKED) pend "$rest"; CLONES_BLOCKED=1 ;;
      *) printf '      %s\n' "$line" ;;
    esac
  done
}
# Prefijo común de los scripts remotos (misma semántica de DRY que acá).
REMOTE_LIB='
# Sin pipefail a propósito: `x | grep -q` daría 141 (SIGPIPE) cuando grep sale antes que x.
export GIT_TERMINAL_PROMPT=0
DRY=$1; shift
say() { printf "%s %s\n" "$1" "$2"; }
act() { # act "descripción" cmd…  → en dry-run solo reporta; salida del cmd solo si falla
  local d=$1 log; shift
  if [ "$DRY" = 1 ]; then say PLAN "$d"; return 0; fi
  log=$(mktemp)
  if "$@" >"$log" 2>&1; then say CHANGED "$d"; rm -f "$log"; return 0; fi
  say FAIL "$d (salida: $(tail -3 "$log" | tr "\n" " "))"; rm -f "$log"; return 1
}
run() { # run "descripción" cmd…  → como act, pero muestra la salida (bootstrap, install.sh)
  local d=$1; shift
  if [ "$DRY" = 1 ]; then say PLAN "$d"; return 0; fi
  "$@" 2>&1 | sed "s/^/      /"
  if [ "${PIPESTATUS[0]}" = 0 ]; then say CHANGED "$d"; else say FAIL "$d"; return 1; fi
}
'

[ "$DRY" = 1 ] && echo "new-worker · DRY-RUN · $HOST ($ALIAS)" || echo "new-worker · $HOST ($ALIAS)"

# ═════════════════════════════════════════════════════════════════════════════
step a "preflight"
# ═════════════════════════════════════════════════════════════════════════════
for f in "$DOTFILES/.git" "$WS" "$HOME/.claude/settings.json" "$HOME/.claude/plugins/installed_plugins.json"; do
  [ -e "$f" ] || die "esta caja no está armada: falta $f (córrelo desde la Mac o la Arch)"
done
command -v jq >/dev/null || die "falta jq en esta caja"
ok "caja fuente armada ($(uname -s) $(uname -m))"

ssh "${SSH_OPTS[@]}" "$HOST" true 2>/dev/null \
  || die "ssh a '$HOST' pide algo o no llega. Autoriza tu key: ssh-copy-id $HOST (y Tailscale arriba)"
ok "ssh sin prompt"

eval "$(R '. /etc/os-release 2>/dev/null; printf "W_ID=%q W_LIKE=%q W_PRETTY=%q W_ARCH=%q W_KERNEL=%q W_USER=%q W_HOME=%q W_HOSTNAME=%q\n" "${ID:-}" "${ID_LIKE:-}" "${PRETTY_NAME:-?}" "$(uname -m)" "$(uname -s)" "$(id -un)" "$HOME" "$(hostname)"')"
case "${W_KERNEL:-}" in
  Linux) ;;
  *) die "SO no soportado: ${W_KERNEL:-desconocido}. Un worker nuevo es Linux (Ubuntu)." ;;
esac
case " ${W_ID} ${W_LIKE} " in
  *" ubuntu "*) ok "SO: $W_PRETTY ($W_ARCH)" ;;
  *) die "SO no soportado: $W_PRETTY. Este script es Ubuntu (apt + PPA de ET + perfil server). Arch: ./install.sh + setup_et a mano." ;;
esac

R 'sudo -n true' >/dev/null 2>&1 \
  || die "sudo pide password en $HOST. Una vez, en el worker: echo \"$W_USER ALL=(ALL) NOPASSWD:ALL\" | sudo tee /etc/sudoers.d/$W_USER"
ok "sudo sin password"

W_TSIP=$(R 'tailscale ip -4 2>/dev/null | head -1')
case "$W_TSIP" in
  100.*) ok "Tailscale: $W_TSIP" ;;
  *) die "sin IP de Tailscale. En el worker: curl -fsSL https://tailscale.com/install.sh | sh && sudo tailscale up" ;;
esac
MESH_TARGET="$W_USER@$W_TSIP"

# ═════════════════════════════════════════════════════════════════════════════
step b "dotfiles (clone + bootstrap-ubuntu.sh + perfil server)"
# ═════════════════════════════════════════════════════════════════════════════
DOT_URL=$(git -C "$DOTFILES" remote get-url origin | sed -E 's#^git@github\.com:#https://github.com/#; s#^ssh://git@github\.com/#https://github.com/#')
remote "$DRY" "$DOT_URL" <<'EOS' | relay
URL=$1; D="$HOME/dotfiles"
if [ ! -d "$D/.git" ]; then
  run "clone $URL → ~/dotfiles" git clone -q "$URL" "$D" || exit 0
  [ "$DRY" = 1 ] && { say PLAN "bootstrap-ubuntu.sh + ./install.sh server"; exit 0; }
else
  # Trampa: `gh auth login`/`gh auth setup-git` escribe su credential helper en ~/.gitconfig,
  # que es el symlink a shared/git/.gitconfig → ensucia el archivo COMPARTIDO del repo.
  if ! git -C "$D" diff --quiet -- shared/git/.gitconfig 2>/dev/null; then
    if git -C "$D" diff -U0 -- shared/git/.gitconfig | grep -E '^[+-][^+-]' | grep -vqiE 'credential|helper|^[+-]\s*$'; then
      say WARN "shared/git/.gitconfig tiene cambios locales que no son del credential helper: revísalos a mano"
    else
      run "shared/git/.gitconfig restaurado (gh le había escrito un credential helper)" git -C "$D" checkout -- shared/git/.gitconfig
    fi
  fi
  if [ -n "$(git -C "$D" status --porcelain --untracked-files=no)" ]; then
    say WARN "~/dotfiles tiene cambios sin commitear: no hago pull"
  else
    git -C "$D" fetch -q origin 2>/dev/null
    behind=$(git -C "$D" rev-list --count HEAD..@{u} 2>/dev/null || echo 0)
    if [ "${behind:-0}" -gt 0 ]; then run "pull --ff-only ($behind commit(s) atrás)" git -C "$D" pull -q --ff-only
    else say OK "~/dotfiles al día ($(git -C "$D" log --oneline -1 | cut -c1-60))"; fi
  fi
fi

# ¿hace falta bootstrap? = algún paquete apt, p10k, yazi, tpm o la línea de PATH faltan.
pkgs=$(sed -n '/^APT_PKGS=(/,/^)/p' "$D/server/bootstrap-ubuntu.sh" | sed '1d;$d' | tr -s ' \n' '\n' | grep -v '^$')
missing=""
for p in $pkgs; do
  dpkg-query -W -f='${Status}' "$p" 2>/dev/null | grep -q 'install ok installed' || missing="$missing $p"
done
extra=""
[ -d "$HOME/.local/share/powerlevel10k/.git" ] || extra="$extra p10k"
[ -x "$HOME/.local/bin/yazi" ] || command -v yazi >/dev/null || extra="$extra yazi"
[ -d "$HOME/.tmux/plugins/tpm" ] || extra="$extra tpm"
grep -qF '# dotfiles(server): ~/.local/bin for non-interactive ssh' "$HOME/.bashrc" 2>/dev/null || extra="$extra bashrc-PATH"
if [ -n "$missing$extra" ]; then
  run "bootstrap-ubuntu.sh (faltaban:$missing$extra)" "$D/server/bootstrap-ubuntu.sh"
else
  say OK "bootstrap completo ($(printf '%s\n' $pkgs | wc -l | tr -d ' ') paquetes apt, p10k, yazi, tpm, PATH)"
fi

# ¿stow pendiente? Simula el perfil server paquete por paquete.
pending=0
group=""
while IFS= read -r l; do
  case "$l" in
    "Shared packages:") group=shared ;; "linux packages:") group=linux ;; "server packages:") group=server ;;
    "  "*) pkg=${l#  }
           n=$(stow -n -v --no-folding --dir="$D/$group" --target="$HOME" "$pkg" 2>&1 | grep -c '^LINK')
           [ "$n" -gt 0 ] && pending=$((pending+n)) ;;
  esac
done < <(DOTFILES_PROFILE=server "$D/install.sh" list 2>/dev/null)
if [ "$pending" -gt 0 ]; then run "./install.sh server ($pending links pendientes)" "$D/install.sh" server
else say OK "perfil server stoweado (0 links pendientes)"; fi
EOS
# Verificación por efecto: un ssh NO interactivo sin tocar PATH ve ~/.local/bin.
if [ "$DRY" = 0 ]; then
  if ssh "${SSH_OPTS[@]}" "$HOST" 'case ":$PATH:" in *":$HOME/.local/bin:"*) exit 0;; esac; exit 1'; then
    ok "~/.local/bin en el PATH de ssh no interactivo"
  else fail "~/.local/bin NO está en el PATH de ssh no interactivo (revisa la primera línea de ~/.bashrc)"; fi
fi

# ═════════════════════════════════════════════════════════════════════════════
step c "herdr"
# ═════════════════════════════════════════════════════════════════════════════
L_HERDR="$HOME/.local/bin/herdr"
W_HV=$(R '"$HOME/.local/bin/herdr" --version 2>/dev/null | awk "{print \$2}"')
L_HV=$([ -x "$L_HERDR" ] && "$L_HERDR" --version 2>/dev/null | awk '{print $2}')
newer() { [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1)" = "$1" ]; }  # $1 > $2
if [ -n "$W_HV" ] && { [ -z "$L_HV" ] || ! newer "$L_HV" "$W_HV"; }; then
  ok "herdr $W_HV en el worker (fuente: ${L_HV:-sin binario})"
elif [ -z "$L_HV" ]; then
  fail "no hay ~/.local/bin/herdr en esta caja para copiar"
elif [ "$(uname -s)/$(uname -m)" != "Linux/$W_ARCH" ]; then
  fail "herdr local es $(uname -s)/$(uname -m) y el worker Linux/$W_ARCH: corre este paso desde la Arch"
elif [ "$DRY" = 1 ]; then
  plan "copiar herdr $L_HV (worker: ${W_HV:-ausente})"
else
  if ssh "${SSH_OPTS[@]}" "$HOST" 'mkdir -p ~/.local/bin && cat > ~/.local/bin/herdr.new && chmod 755 ~/.local/bin/herdr.new && mv -f ~/.local/bin/herdr.new ~/.local/bin/herdr' < "$L_HERDR"; then
    W_HV=$(R '"$HOME/.local/bin/herdr" --version 2>/dev/null | awk "{print \$2}"')
    [ "$W_HV" = "$L_HV" ] && changed "herdr $W_HV copiado y verificado (--version)" || fail "herdr copiado pero --version da '$W_HV'"
  else fail "no se pudo copiar herdr"; fi
fi

# ═════════════════════════════════════════════════════════════════════════════
step d "Eternal Terminal (PPA jgmath2000/et + et.service)"
# ═════════════════════════════════════════════════════════════════════════════
remote "$DRY" "$ET_PPA" <<'EOS' | relay
PPA=$1
if command -v etserver >/dev/null; then say OK "et instalado ($(dpkg-query -W -f='${Version}' et 2>/dev/null))"
else
  # ET no está en el apt de Ubuntu 26.04: solo en el PPA.
  act "PPA $PPA + apt install et" bash -c "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq software-properties-common \
    && sudo add-apt-repository -y $PPA && sudo apt-get update -qq \
    && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq et \
    && { [ ! -f /etc/et.cfg ] || sudo sed -i 's/^telemetry = true/telemetry = false/' /etc/et.cfg; }"
fi
if [ "$(systemctl is-enabled et 2>/dev/null)" = enabled ] && [ "$(systemctl is-active et 2>/dev/null)" = active ]; then
  say OK "et.service enabled + active"
else act "systemctl enable --now et.service" sudo systemctl enable --now et.service; fi
# ET pasa el TERM real del cliente (xterm-ghostty desde la Mac); sin terminfo la salida se rompe.
if infocmp xterm-ghostty >/dev/null 2>&1; then say OK "terminfo xterm-ghostty"
else act "terminfo xterm-ghostty (alias de xterm-256color)" bash -c \
  "printf 'xterm-ghostty|ghostty alias to xterm-256color,\n\tuse=xterm-256color,\n' | sudo tic -x -o /usr/share/terminfo -"; fi
EOS
if [ "$DRY" = 0 ]; then
  if command -v nc >/dev/null && nc -z -w 5 "$W_TSIP" 2022 2>/dev/null; then ok "puerto 2022 alcanzable desde esta caja ($W_TSIP)"
  elif (exec 3<>"/dev/tcp/$W_TSIP/2022") 2>/dev/null; then ok "puerto 2022 alcanzable desde esta caja ($W_TSIP)"
  else fail "no llego a $W_TSIP:2022 (etserver)"; fi
fi

# ═════════════════════════════════════════════════════════════════════════════
step e "memoria (swap ≥ RAM + systemd-oomd como en hq)"
# ═════════════════════════════════════════════════════════════════════════════
remote "$DRY" <<'EOS' | relay
mem_kb=$(awk '/^MemTotal:/{print $2}' /proc/meminfo)
swap_kb=$(awk 'NR>1{s+=$3} END{print s+0}' /proc/swaps)
gib() { awk -v k="$1" 'BEGIN{printf "%.1f", k/1048576}'; }
if [ "$swap_kb" -ge "$mem_kb" ]; then
  say OK "swap $(gib "$swap_kb") GiB ≥ RAM $(gib "$mem_kb") GiB"
else
  need_gib=$(( (mem_kb - swap_kb + 1048575) / 1048576 ))
  f=/swapfile2; i=2; while [ -e "$f" ]; do i=$((i+1)); f=/swapfile$i; done
  free_gib=$(df -BG --output=avail / | tail -1 | tr -dc 0-9)
  fstype=$(df --output=fstype / | tail -1 | tr -d ' ')
  if [ "$free_gib" -lt $((need_gib + 5)) ]; then
    say FAIL "faltan ${need_gib} GiB de swap y / tiene ${free_gib} GiB libres (dejo 5 de margen): agranda el disco o baja el techo de agentes"
  elif [ "$fstype" = btrfs ]; then
    act "swapfile $f de ${need_gib} GiB (btrfs)" bash -c "sudo btrfs filesystem mkswapfile --size ${need_gib}g $f && sudo swapon $f"
  else
    act "swapfile $f de ${need_gib} GiB (swap total $(gib "$swap_kb") → $(gib $((swap_kb + need_gib*1048576))) GiB)" \
      bash -c "sudo fallocate -l ${need_gib}G $f && sudo chmod 600 $f && sudo mkswap -q $f >/dev/null && sudo swapon $f"
  fi
fi
# Todo swapfile activo tiene que estar en fstab o se pierde al reiniciar.
for f in $(awk 'NR>1 && $2=="file"{print $1}' /proc/swaps); do
  [ -e "$f" ] || continue
  if awk -v f="$f" '$1==f && $3=="swap"' /etc/fstab | grep -q .; then say OK "$f en fstab"
  else act "$f → /etc/fstab" bash -c "echo '$f none swap sw 0 0' | sudo tee -a /etc/fstab >/dev/null"; fi
done

# systemd-oomd: mata al cgroup más pesado en vez de colgar la máquina (OOM de hq, 2026-09-29).
dpkg-query -W -f='${Status}' systemd-oomd 2>/dev/null | grep -q 'install ok installed' \
  && say OK "paquete systemd-oomd" \
  || act "apt install systemd-oomd" sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq systemd-oomd
reload=0
write_file() { sudo mkdir -p "$(dirname "$1")" && printf '%s\n' "$2" | sudo tee "$1" >/dev/null; }
dropin() { # dropin <path> <contenido exacto>
  if [ "$(cat "$1" 2>/dev/null)" = "$2" ]; then say OK "$1"
  else act "$1" write_file "$1" "$2" && reload=1; fi
}
dropin /etc/systemd/system/-.slice.d/10-oomd.conf "$(printf '[Slice]\nManagedOOMSwap=kill')"
dropin /etc/systemd/system/user@.service.d/10-oomd.conf "$(printf '[Service]\nManagedOOMMemoryPressure=kill\nManagedOOMMemoryPressureLimit=60%%')"
[ "$reload" = 1 ] && [ "$DRY" = 0 ] && act "systemctl daemon-reload" sudo systemctl daemon-reload
if [ "$(systemctl is-active systemd-oomd 2>/dev/null)" = active ]; then say OK "systemd-oomd active"
else act "systemctl enable --now systemd-oomd" sudo systemctl enable --now systemd-oomd; fi
# Verificación por efecto: lo que systemd efectivamente aplica, no el archivo.
if [ "$DRY" = 0 ]; then
  s=$(systemctl show -p ManagedOOMSwap --value -- -.slice)
  p=$(systemctl show -p ManagedOOMMemoryPressure --value "user@$(id -u).service")
  l=$(systemctl show -p ManagedOOMMemoryPressureLimit --value "user@$(id -u).service")
  if [ "$s" = kill ] && [ "$p" = kill ] && [ "$l" != 0 ]; then say OK "efectivo: -.slice ManagedOOMSwap=kill · user@$(id -u) presión=kill límite=$l/2^32"
  else say FAIL "oomd no efectivo (swap=$s pressure=$p limit=$l)"; fi
fi
EOS

# ═════════════════════════════════════════════════════════════════════════════
step f "Claude Code (installer oficial) · gh (apt cli.github.com) · bw"
# ═════════════════════════════════════════════════════════════════════════════
remote "$DRY" "$VAULT_URL" <<'EOS' | relay
VAULT=$1
if command -v claude >/dev/null; then say OK "claude $(claude --version 2>/dev/null | head -1)"
else
  act "Claude Code (curl -fsSL https://claude.ai/install.sh | bash)" bash -c 'curl -fsSL https://claude.ai/install.sh | bash'
  [ "$DRY" = 0 ] && { command -v claude >/dev/null && say OK "verificado: claude $(claude --version | head -1)" || say FAIL "claude no aparece en ~/.local/bin"; }
fi

# gh: el de Ubuntu ESM es 2.46 → repo oficial de cli.github.com, fijado con prioridad 1001.
KR=/etc/apt/keyrings/githubcli-archive-keyring.gpg
LIST=/etc/apt/sources.list.d/github-cli.list
PIN=/etc/apt/preferences.d/gh-cli
if [ -s "$KR" ] && [ -f "$LIST" ] && [ -f "$PIN" ] && dpkg-query -W -f='${Status}' gh 2>/dev/null | grep -q 'install ok installed'; then
  say OK "gh $(gh --version | head -1 | awk '{print $3}') (repo cli.github.com, fijado)"
else
  act "gh desde cli.github.com (keyring + list + pin 1001)" bash -c "
    sudo mkdir -p -m 755 /etc/apt/keyrings
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee $KR >/dev/null
    sudo chmod go+r $KR
    echo 'deb [arch=$(dpkg --print-architecture) signed-by=$KR] https://cli.github.com/packages stable main' | sudo tee $LIST >/dev/null
    printf 'Package: gh\nPin: origin cli.github.com\nPin-Priority: 1001\n' | sudo tee $PIN >/dev/null
    sudo apt-get update -qq && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq gh"
fi

# bw (Bitwarden CLI, para Vaultwarden): npm con prefijo de usuario, igual que en la Arch.
if command -v bw >/dev/null; then say OK "bw $(bw --version 2>/dev/null)"
else
  act "bw (npm install -g --prefix ~/.local @bitwarden/cli)" npm install -g --silent --prefix "$HOME/.local" @bitwarden/cli
  [ "$DRY" = 0 ] && { command -v bw >/dev/null && say OK "verificado: bw $(bw --version 2>/dev/null)" || say FAIL "bw no quedó en ~/.local/bin"; }
fi
if command -v bw >/dev/null; then
  st=$(bw status 2>/dev/null | jq -r '.status // "?"' 2>/dev/null)
  cur=$(bw config server 2>/dev/null)
  if [ "$cur" = "$VAULT" ]; then say OK "bw server = $VAULT"
  elif [ "$st" = unauthenticated ]; then act "bw config server $VAULT" bw config server "$VAULT"
  else say WARN "bw apunta a '$cur' con sesión '$st': cámbialo tras bw logout"; fi
fi
EOS

# ═════════════════════════════════════════════════════════════════════════════
step g "workspace ~/cofoundy + Claude Code (CLAUDE.md, marketplaces, plugins, settings)"
# ═════════════════════════════════════════════════════════════════════════════
# 1) repos de la fuente: solo clones reales (.git directorio) — los worktrees (.git archivo)
#    son trabajo en vuelo de esta caja, no parte del workspace. URL normalizada a https.
REPOS=$(cd "$WS" && find . -maxdepth 3 -name .git -type d -not -path './.staging/*' -not -path '*/node_modules/*' 2>/dev/null \
  | sed 's#^\./##; s#/\.git$##' | sort | while read -r d; do
      u=$(git -C "$WS/$d" remote get-url origin 2>/dev/null) || continue
      slug=$(printf '%s' "$u" | sed -E 's#\.git$##; s#^.*[:/]([^/:]+/[^/:]+)$#\1#')
      printf '%s https://github.com/%s.git\n' "$d" "$slug"
    done)
N_REPOS=$(printf '%s\n' "$REPOS" | grep -c .)
# 2) symlink de ~/cofoundy/CLAUDE.md, relativo al HOME del worker
WS_LINK=""
[ -L "$WS/CLAUDE.md" ] && WS_LINK=$(readlink "$WS/CLAUDE.md" | sed "s#^$HOME/##")
# 3) marketplaces (arg de `claude plugin marketplace add`) y plugins a instalar
MKTS=$(jq -r 'to_entries[] | .key + " " + (
          if .value.source.source == "github" then .value.source.repo
          elif .value.source.source == "git" then (.value.source.url
                | sub("^git@github\\.com:"; "https://github.com/") | sub("^ssh://git@github\\.com/"; "https://github.com/"))
          else "" end)' "$HOME/.claude/plugins/known_marketplaces.json")
# Plugin = instalado en la fuente Y declarado en enabledPlugins (así un plugin retirado que
# quedó en el cache de la fuente, p.ej. cofoundy-docs, no se propaga).
PLUGINS=$(jq -r --slurpfile s "$HOME/.claude/settings.json" \
  '.plugins | keys[] | select(. as $k | $s[0].enabledPlugins | has($k))' "$HOME/.claude/plugins/installed_plugins.json")
# 4) settings no secretos: allowlist de claves; env sin nada que huela a credencial.
OVERLAY=$(jq -c '
  {model, effortLevel, theme, editorMode, includeCoAuthoredBy, permissions,
   skipDangerousModePermissionPrompt, skipAutoPermissionPrompt, enabledPlugins,
   extraKnownMarketplaces, autoMode,
   env: ((.env // {}) | with_entries(select(.key | test("KEY|TOKEN|SECRET|PASS|JSON|EMAIL|USER|SUBJECT|CLIENT|CRED|AUTH|SESSION") | not)))}
  | with_entries(select(.value != null))
  | .extraKnownMarketplaces |= ((. // {}) | map_values(
      if .source.url? then .source.url |= (sub("^git@github\\.com:"; "https://github.com/")) else . end))
  | del(.. | select(. == []))
  | .autoMemoryEnabled = false' "$HOME/.claude/settings.json")

PRELUDE=$(printf 'REPOS=%q\nWS_LINK=%q\nMKTS=%q\nPLUGINS=%q\nOVERLAY=%q\n' "$REPOS" "$WS_LINK" "$MKTS" "$PLUGINS" "$OVERLAY")
remote "$DRY" <<'EOS' | relay
WS="$HOME/cofoundy"; D="$HOME/dotfiles"; S="$HOME/.claude/settings.json"
[ "$DRY" = 1 ] || mkdir -p "$WS" "$HOME/.herdr"

# git: credential helper PER-BOX en ~/.config/git/config (nunca en ~/.gitconfig, que es compartido).
GC="$HOME/.config/git/config"
if git config --file "$GC" --get-all credential.https://github.com.helper 2>/dev/null | grep -q 'gh auth git-credential'; then
  say OK "credential helper de gh en ~/.config/git/config"
elif command -v gh >/dev/null; then
  GH=$(command -v gh)
  set_helper() {
    mkdir -p "$(dirname "$GC")"
    for h in https://github.com https://gist.github.com; do
      git config --file "$GC" --replace-all "credential.$h.helper" '' \
        && git config --file "$GC" --add "credential.$h.helper" "!$GH auth git-credential" || return 1
    done
  }
  act "credential helper de gh → ~/.config/git/config (per-box)" set_helper
fi

# repos
gh_ok=0; gh auth status >/dev/null 2>&1 && gh_ok=1
have=0; cloned=0; blocked=""
while read -r path url; do
  [ -n "$path" ] || continue
  if [ -d "$WS/$path/.git" ]; then
    have=$((have+1))
    cur=$(git -C "$WS/$path" remote get-url origin 2>/dev/null | sed -E 's#\.git$##; s#^.*[:/]([^/:]+/[^/:]+)$#\1#')
    want=$(printf '%s' "$url" | sed -E 's#\.git$##; s#^.*[:/]([^/:]+/[^/:]+)$#\1#')
    [ "$cur" = "$want" ] || say WARN "$path apunta a $cur (la fuente: $want)"
  elif [ -e "$WS/$path" ]; then
    say WARN "$path existe y no es un clone: no lo toco"
  elif [ "$gh_ok" = 1 ] || git ls-remote -q "$url" HEAD >/dev/null 2>&1; then
    mkdir -p "$WS/$(dirname "$path")"
    act "clone $path" git clone -q "$url" "$WS/$path" && cloned=$((cloned+1))
  else
    blocked="$blocked $path"
  fi
done <<< "$REPOS"
total=$(printf '%s\n' "$REPOS" | grep -c .)
say OK "repos: $have/$total ya clonados$([ "$cloned" -gt 0 ] && echo ", $cloned nuevos")"
[ -n "$blocked" ] && say BLOCKED "privados sin clonar (falta gh auth en el worker):$blocked"

# ~/cofoundy/CLAUDE.md → mismo target que la fuente
if [ -n "$WS_LINK" ]; then
  tgt="$HOME/$WS_LINK"
  if [ "$(readlink "$WS/CLAUDE.md" 2>/dev/null)" = "$tgt" ]; then say OK "~/cofoundy/CLAUDE.md → ~/$WS_LINK"
  elif [ ! -e "$tgt" ] && [ "$DRY" = 0 ]; then say PEND "~/cofoundy/CLAUDE.md: falta ~/$WS_LINK (llega con los clones)"
  elif [ -e "$WS/CLAUDE.md" ] && [ ! -L "$WS/CLAUDE.md" ]; then say WARN "~/cofoundy/CLAUDE.md es un archivo regular: no lo piso"
  else act "~/cofoundy/CLAUDE.md → ~/$WS_LINK" ln -sfn "$tgt" "$WS/CLAUDE.md"; fi
fi

# dotfiles/claude: ~/.claude/CLAUDE.md, ~/.herdr/CLAUDE.md, skills personales y hooks.
need=""
[ "$(readlink "$HOME/.claude/CLAUDE.md" 2>/dev/null)" = "$D/shared/claude/CLAUDE.md" ] || need="$need ~/.claude/CLAUDE.md"
[ -e "$WS/CLAUDE.md" ] && { [ "$(readlink "$HOME/.herdr/CLAUDE.md" 2>/dev/null)" = "$WS/CLAUDE.md" ] || need="$need ~/.herdr/CLAUDE.md"; }
for sk in "$D"/shared/claude/skills/*/; do
  [ -d "$sk" ] || continue; n=$(basename "$sk")
  [ "$(readlink "$HOME/.claude/skills/$n" 2>/dev/null)" = "${sk%/}" ] || need="$need skill:$n"
done
want_hooks=$(sed "s|__DOTFILES__|$D|g" "$D/shared/claude/settings.template.json" | jq -S '.hooks')
have_hooks=$(jq -S '.hooks' "$S" 2>/dev/null)
[ "$want_hooks" = "$have_hooks" ] || need="$need hooks"
if [ -z "$need" ]; then say OK "dotfiles/claude: CLAUDE.md (global + herdr), skills y hooks al día"
else act "./install.sh claude (faltaba:$need)" "$D/install.sh" claude; fi

# marketplaces
have_m=$(jq -r 'keys[]' "$HOME/.claude/plugins/known_marketplaces.json" 2>/dev/null)
nm=0
while read -r name src; do
  [ -n "$name" ] || continue
  if grep -qxF "$name" <<< "$have_m"; then nm=$((nm+1)); continue; fi
  [ -n "$src" ] || { say WARN "marketplace $name: fuente no-git en la caja fuente, sáltalo"; continue; }
  act "marketplace $name ($src)" claude plugin marketplace add "$src" </dev/null
done <<< "$MKTS"
say OK "marketplaces: $nm/$(printf '%s\n' "$MKTS" | grep -c .) ya estaban"

# plugins
have_p=$(jq -r '.plugins | keys[]' "$HOME/.claude/plugins/installed_plugins.json" 2>/dev/null)
np=0
while read -r p; do
  [ -n "$p" ] || continue
  if grep -qxF "$p" <<< "$have_p"; then np=$((np+1)); continue; fi
  act "plugin $p" claude plugin install "$p" </dev/null
done <<< "$PLUGINS"
say OK "plugins: $np/$(printf '%s\n' "$PLUGINS" | grep -c .) ya instalados"

# settings: overlay no secreto de la fuente SOBRE lo del worker (sus hooks y sus secretos quedan).
cur_s=$(jq -S . "$S" 2>/dev/null || echo '{}')
new=$(printf '%s' "$cur_s" | jq -S --argjson o "$OVERLAY" '. * $o')
if [ "$new" = "$cur_s" ]; then say OK "settings.json: claves no secretas = fuente · autoMemoryEnabled=false"
else
  # Solo NOMBRES de claves (nunca valores: el env del worker puede tener secretos).
  changed_paths=$(jq -rn --argjson a "$cur_s" --argjson b "$new" '
    [($a, $b) | paths(scalars)] | unique
    | map(select(. as $p | (try ($a | getpath($p)) catch null) != (try ($b | getpath($p)) catch null)))
    | map(map(tostring) | join(".")) | .[:12] | join(", ")')
  write_settings() {
    [ -f "$S" ] && cp -p "$S" "$S.bak-new-worker-$(date +%Y%m%d%H%M%S)"
    mkdir -p "$(dirname "$S")" && printf '%s\n' "$new" > "$S.tmp" && mv "$S.tmp" "$S"
  }
  act "settings.json ← fuente (claves: $changed_paths)" write_settings
fi
[ "$(jq -r '.autoMemoryEnabled' "$S")" = false ] && [ "$DRY" = 0 ] && say OK "verificado: autoMemoryEnabled=false"
EOS

# ═════════════════════════════════════════════════════════════════════════════
step h "mesh: alias '$ALIAS' en shared/zsh/mesh.zsh (+ Termux) · commit + push de dotfiles"
# ═════════════════════════════════════════════════════════════════════════════
VAR="MESH_$ALIAS_UP"
CUR=$(sed -n "s/^$VAR=\"\([^\"]*\)\".*/\1/p" "$MESH_FILE")
MESH_CHANGED=0
# Colisión: el alias ya existe en mesh.zsh apuntando a OTRA caja → no toco nada.
COLLIDE=0
ALIAS_LINES=$(grep -E "^[[:space:]]*alias $ALIAS=" "$MESH_FILE")
if [ -n "$ALIAS_LINES" ] && grep -vqF "\$$VAR " <<< "$ALIAS_LINES"; then
  fail "el alias '$ALIAS' ya existe en mesh.zsh para otra caja: elige otro"; COLLIDE=1
fi
if [ "$COLLIDE" = 0 ]; then
  if [ "$CUR" = "$MESH_TARGET" ]; then ok "$VAR=\"$MESH_TARGET\""
  elif [ "$DRY" = 1 ]; then plan "$VAR=\"$MESH_TARGET\" (hoy: ${CUR:-no existe})"
  else
    tmp=$(mktemp)
    if [ -n "$CUR" ]; then
      awk -v v="$VAR" -v t="$MESH_TARGET" 'index($0, v"=\"")==1 { sub(/"[^"]*"/, "\"" t "\"") } { print }' "$MESH_FILE" > "$tmp"
    else
      last=$(grep -n '^MESH_[A-Z0-9]*=' "$MESH_FILE" | tail -1 | cut -d: -f1)
      awk -v n="$last" -v l="$VAR=\"$MESH_TARGET\"      # Tailscale ($W_HOSTNAME)" '{ print } NR==n { print l }' "$MESH_FILE" > "$tmp"
    fi
    cat "$tmp" > "$MESH_FILE"; rm -f "$tmp"; MESH_CHANGED=1; changed "$VAR=\"$MESH_TARGET\""
  fi
  for os in Darwin Linux; do
    if awk -v os="$os)" -v a="alias $ALIAS=" '$1==os{on=1} on && index($0,a){f=1} on && /;;/{on=0} END{exit !f}' "$MESH_FILE"; then
      ok "alias $ALIAS en el bloque $os"
    elif [ "$DRY" = 1 ]; then plan "alias $ALIAS=\"et \$$VAR -c herdr\" en el bloque $os"
    else
      tmp=$(mktemp)
      awk -v os="$os)" -v l="    alias $ALIAS=\"et \$$VAR -c herdr\"" \
        '$1==os{on=1} on && /^[[:space:]]*;;/{print l; on=0} {print}' "$MESH_FILE" > "$tmp"
      cat "$tmp" > "$MESH_FILE"; rm -f "$tmp"; MESH_CHANGED=1; changed "alias $ALIAS en el bloque $os"
    fi
  done
  # Termux (celu/tablet) define los mismos aliases en su ~/.bashrc.
  if [ -f "$TERMUX_FILE" ]; then
    if grep -qE "^alias $ALIAS=" "$TERMUX_FILE"; then ok "alias $ALIAS en termux-bootstrap.sh"
    elif [ "$DRY" = 1 ]; then plan "alias $ALIAS en termux-bootstrap.sh"
    else
      last=$(grep -n '^alias [a-z0-9]*="et ' "$TERMUX_FILE" | tail -1 | cut -d: -f1)
      if [ -n "$last" ]; then
        tmp=$(mktemp)
        awk -v n="$last" -v l="alias $ALIAS=\"et $MESH_TARGET -c herdr\"" '{ print } NR==n { print l }' "$TERMUX_FILE" > "$tmp"
        cat "$tmp" > "$TERMUX_FILE"; rm -f "$tmp"; MESH_CHANGED=1; changed "alias $ALIAS en termux-bootstrap.sh"
      else warn "termux-bootstrap.sh sin aliases 'et': agrégalo a mano"; fi
    fi
  fi
  if [ "$MESH_CHANGED" = 1 ]; then
    zsh -n "$MESH_FILE" 2>/dev/null || bash -n "$MESH_FILE" || fail "mesh.zsh quedó con error de sintaxis"
    if git -C "$DOTFILES" commit -q -m "feat(mesh): alias $ALIAS = herdr de $W_HOSTNAME por ET (new-worker.sh)" -- "$MESH_FILE" "$TERMUX_FILE" \
       && git -C "$DOTFILES" pull -q --rebase --autostash && git -C "$DOTFILES" push -q; then
      changed "dotfiles commit $(git -C "$DOTFILES" rev-parse --short HEAD) pusheado"
    else fail "commit/push de dotfiles falló: revisa git -C ~/dotfiles status"; fi
  fi
fi

# ═════════════════════════════════════════════════════════════════════════════
step i "PASOS HUMANOS"
# ═════════════════════════════════════════════════════════════════════════════
# Estado medido en el worker; solo se listan los que faltan. Nada de esto imprime secretos.
eval "$(R '
  gh auth status >/dev/null 2>&1 && echo H_GH=1 || echo H_GH=0
  [ -s "$HOME/.claude/.credentials.json" ] && echo H_CLAUDE=1 || echo H_CLAUDE=0
  n=$(jq "[.env // {} | keys[] | select(test(\"KEY|TOKEN|SECRET|PASS\"))] | length" "$HOME/.claude/settings.json" 2>/dev/null); echo H_KEYS=${n:-0}
  st=$(command -v bw >/dev/null && bw status 2>/dev/null | jq -r ".status // \"?\"" 2>/dev/null); echo H_BW=${st:-absent}
  if [ -s "$HOME/.claude/.credentials.json" ] && command -v claude >/dev/null; then
    m=$(timeout 120 claude mcp list 2>/dev/null | grep -i "needs auth" | awk -F": " "{print \$1}" | grep -v "^claude\.ai " | sort -u | paste -sd, -)
    echo "H_MCP=\"$m\""
  else echo H_MCP=\"?\"; fi
')"
ET_IN="et $MESH_TARGET          # o: ssh -t $HOST"
n=0
todo() { n=$((n+1)); printf '\n  %d. %s\n' "$n" "$1"; shift; for l in "$@"; do printf '       %s\n' "$l"; done; }
[ "$H_GH" = 1 ] || todo "GitHub (desbloquea los clones privados y ensure-keys)" \
  "$ET_IN" "gh auth login -h github.com -p https -w" \
  "→ a «Authenticate Git with your GitHub credentials?» responde NO: el helper ya está en ~/.config/git/config;" \
  "  si dices sí, gh lo escribe en ~/.gitconfig = shared/git/.gitconfig (compartido). Re-correr este script lo limpia." \
  "Después: $0 $HOST $ALIAS   (clona lo que faltó)"
[ "$H_CLAUDE" = 1 ] || todo "Login de Claude Code" "$ET_IN" "claude        # y dentro: /login"
if [ "${H_KEYS:-0}" = 0 ]; then
  todo "Secretos de las skills (Vaultwarden → env de ~/.claude/settings.json; requiere el paso de gh)" \
    "$ET_IN" \
    'CLAUDE_ENV_FILE=$(mktemp) bash "$(command ls -t ~/.claude/plugins/cache/cofoundy/cofoundy-toolkit/*/hooks/scripts/ensure-keys.sh | head -1)"' \
    "verifica: jq '.env | keys | length' ~/.claude/settings.json   (solo cuenta claves, no las imprime)"
fi
case "$H_BW" in
  unlocked|locked) ;;
  *) todo "Bitwarden personal (escrituras al vault vía bw-ensure-session.sh) — DESPUÉS de ensure-keys, que hace bw logout al terminar" \
       "$ET_IN" "bw login andre@cofoundy.dev          # pide password + 2FA por prompt, nunca por argv" \
       'export BW_SESSION="$(bw unlock --raw)"   # por sesión de shell' ;;
esac
if [ "$H_MCP" = "?" ]; then
  todo "Autorizar los MCP (tras el login de Claude)" "$ET_IN" "claude        # y dentro: /mcp → autoriza cada uno en 'needs authentication'"
elif [ -n "$H_MCP" ]; then
  todo "Autorizar los MCP de esta caja: $H_MCP" "$ET_IN" "claude        # y dentro: /mcp → autoriza cada uno" \
    "(los conectores «claude.ai …» son de la cuenta, no de la caja: se autorizan en claude.ai y no cuentan acá)"
fi
[ "$n" = 0 ] && ok "ninguno: el worker está completo"
printf '\n  Entrar al worker: %s   (alias del mesh; abre un shell nuevo o `exec zsh` para tomarlo)\n' "$ALIAS"

# ── resumen ──────────────────────────────────────────────────────────────────
printf '\nresumen: %d cambio(s)%s · %d pendiente(s) · %d fallo(s) · %d paso(s) humano(s)\n' \
  "$N_CHANGED" "$([ "$DRY" = 1 ] && echo ' planeados')" "$N_PENDING" "$N_FAIL" "$n"
[ "$N_FAIL" -gt 0 ] && exit 1
[ "$CLONES_BLOCKED" = 1 ] && exit 2
exit 0
