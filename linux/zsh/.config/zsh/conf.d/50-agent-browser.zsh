# Auto-reap de daemons agent-browser tras 10 min ociosos — evita browsers
# leaked que agotan RAM (freeze OOM 2026-07-04). Solo afecta al subproceso
# del browser; hermes y demás servicios long-running NO llevan timeout.
export AGENT_BROWSER_IDLE_TIMEOUT_MS=600000
