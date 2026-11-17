# 2026-11-16 — Space y Ctrl+R de yazi en Arch → plugin remote-quicklook

**Contexto.** En el yazi de Arch (terminal de herdr-core vista desde la Herdr app del Mac),
Space y Ctrl+R no hacían nada visible. Causa: Arch tiene `WAYLAND_DISPLAY=wayland-1`, así
que `quicklook.sh` abría con `xdg-open` y `reveal.sh` con dolphin en una pantalla que nadie mira.

**Qué shipeó.**
- Plugin público `github.com/A-PachecoT/remote-quicklook.yazi` (fuente en `~/oss/`): en Arch
  copia el archivo a `~/Library/Caches/remote-quicklook` del Mac por ssh y corre `qlmanage -p`
  u `open -R`; en el Mac abre el archivo en su sitio. Vendorizado en
  `shared/yazi/.config/yazi/plugins/`; `init.lua` pasa a dotfiles con el host.
- Se borraron `scripts/quicklook.sh`, `scripts/reveal.sh` y el puente intermedio `mac-bridge-open`.
- Issue a Herdr: herdrdev/herdr-app#1146 (que `files.open` y el Ctrl-click acepten `on`, para
  ver archivos remotos en el panel Files). El feedback in-app no envía en builds desde fuente.

**Validación.** yazi real en Arch (hc) con Space → `qlmanage` corriendo en el Mac sobre la copia;
nombre con espacio y comilla OK; sin `host` → aviso. En el Mac (tmux) Space → `qlmanage` sobre el
archivo original.

**Learnings.**
- En Arch `WAYLAND_DISPLAY` no implica que alguien vea la pantalla: dentro de herdr-core/ssh
  el «display» real es el Mac.
- El panel Files de la Herdr app navega carpetas remotas, pero `files.open` fija `on: null`
  (solo rutas del Mac) — por eso Ctrl+R va a Finder y no al panel.
- herdr-core no relanza agentes tras un reinicio: la terminal vuelve como shell en su carpeta
  (por diseño); se retoma con `claude --continue`.
