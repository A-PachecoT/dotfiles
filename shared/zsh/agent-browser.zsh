# Auto-reap de daemons agent-browser tras 10 min ociosos.
#
# Sin esto, el daemon persiste con el browser vivo: fue la causa del freeze OOM
# del 2026-07-04 en el box Arch (CTO nocturno dejó chromes leaked hasta agotar
# la RAM). agent-browser >= 0.3x trae un default propio de 1h; 10 min es más
# agresivo y cubre además las versiones viejas, que no traían ninguno.
#
# Vive en shared/ porque el leak no es platform-specific. Estuvo solo en
# linux/zsh/conf.d hasta el 2026-09-14, así que la Mac nunca lo recibió — y ese
# mismo día agent-browser pasó a ser el camino por defecto para browser work al
# desarmar el MCP de playwright, que multiplicaba ~250 MB por instancia de claude.
export AGENT_BROWSER_IDLE_TIMEOUT_MS=600000
