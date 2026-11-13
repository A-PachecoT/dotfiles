# Limpia las variables de sesión de Claude Code que se filtran a terminales nuevas.
# Si una sesión de Claude arranca el servidor de herdr-core (o tmux), todos los paneles
# heredan CLAUDE_CODE_CHILD_SESSION=1 y cada `claude` nuevo cree ser hijo: no guarda transcript.
# Solo en shells interactivas: las del Bash tool de Claude no lo son y conservan el marcador.
if [[ -o interactive ]]; then
  unset CLAUDE_CODE_CHILD_SESSION CLAUDE_CODE_SESSION_ID CLAUDE_CODE_BRIDGE_SESSION_ID \
        CLAUDE_CODE_MESSAGING_SOCKET CLAUDE_CODE_MESSAGING_TOKEN CLAUDE_CODE_SESSION_ATTENDED \
        CLAUDE_CODE_ENTRYPOINT CLAUDE_CODE_EXECPATH
fi
