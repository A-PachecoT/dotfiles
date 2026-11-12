# fabrica-vigia

Vigía externo de `/factory` (cofoundy-orchestrator#202, gaps G35 · G36 · G39 · G40). Un timer de systemd
corre `fabrica-vigia ronda` cada 5 min y 2 min después de arrancar la máquina. Solo cuida las fábricas que
la sesión que decide registró; nunca lanza una nueva.

    fabrica-vigia vigilar --nombre el-deily --workspace-label <space del proyecto> --cwd <carpeta de la fábrica> --repo el-deily
    fabrica-vigia estado
    fabrica-vigia ronda --dry-run
    fabrica-vigia soltar --nombre el-deily

Qué hace en cada ronda, y su prueba: `tests/test_fabrica_vigia.py` (herdr falso, 14 casos).
Relance real verificado el 2026-11-11: panel nuevo, `pane rename`, claude en la carpeta registrada, kickoff, respuesta.
No acepta el diálogo de confianza de una carpeta: avisa a la bandeja de André.
Instalar: `cd ~/dotfiles/linux && stow -t ~ fabrica-vigia && systemctl --user daemon-reload && systemctl --user enable --now fabrica-vigia.timer`.

## Panel en blocked (2026-11-12)
Separa **permiso** (diálogo de Claude Code en pantalla; trae el comando) de **sin-avance** (sin diálogo y sin commits en 1 h ni transcripts de la fábrica o sus subagentes en 30 min). En ambos casos despierta al panel `pm` del workspace con `herdr pane run` (una vez por diálogo; `pm_pane` en la config lo fija) y deja la tarea en la bandeja de André. blocked con avance y sin diálogo solo se anota. Origen: la noche del 2026-11-12 marcó «bloqueada» 4,5 h mientras la fábrica commiteaba y el aviso solo fue a Vikunja.
