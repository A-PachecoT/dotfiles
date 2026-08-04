# 2026-08-04 — Chrome MCP server escopeado a nivel proyecto

**Operador:** André (vía Claude Code)

---

## Contexto

André quería usar Claude in Chrome / `mcp-chrome` (hangwin/mcp-chrome) para automatizar el navegador desde este proyecto, sin que el server apareciera en todos sus otros proyectos. Ya tenía instalado `mcp-chrome-bridge` (npm global) y la extensión de Chrome cargada — solo faltaba el lado de config de Claude Code.

## Qué Pasó

1. Se encontró una entrada **global** preexistente `chrome-mcp-server` en `~/.claude.json` (stdio, apuntando a `mcp-chrome-bridge` vía npm), habilitada por default en todos los proyectos (incluido `dotfiles`, que no la tenía en su `disabledMcpServers`).
2. En vez de editar `~/.claude.json` a mano, se usó el CLI oficial:
   - `claude mcp add chrome-mcp-server --scope project -- node <path-a-mcp-server-stdio.js>` → crea `.mcp.json` en la raíz del repo (versionado, se sincroniza Mac↔Arch).
   - `claude mcp remove chrome-mcp-server --scope user` → saca la entrada global para que no siga apareciendo en otros proyectos.
3. Tras reiniciar la sesión, la extensión conectó y expuso tools reales (`get_windows_and_tabs`, `chrome_bookmark_add`, `chrome_close_tabs`, `chrome_javascript`, `chrome_computer`, etc.) — usadas en la misma sesión para limpiar ~100 tabs acumuladas en Chrome.

## Aprendizaje

- `claude mcp add/remove --scope project|user` es más seguro que editar `~/.claude.json` o `.mcp.json` a mano — evita romper el JSON global que afecta todas las sesiones.
- `chrome_javascript` de `mcp-chrome` corre en el contexto de la página (CDP `Runtime.evaluate`), NO en el del extension background — confirmado empíricamente (`chrome.tabGroups` no existe ahí). Ni ese tool ni los de "computer use" (clicks por coordenada) pueden tocar UI nativa del navegador (tab strip, grupos de tabs) — esa API solo la exponen tools dedicados que el MCP server decida implementar, y `mcp-chrome` no expone una para tab groups.
- Cuando un MCP tool devuelve `invalidTabIds` en un close masivo, no es necesariamente un error — puede ser que el estado de tabs ya cambió entre el snapshot y la ejecución (usuario navegando en paralelo). Conviene re-verificar con `get_windows_and_tabs` después, no asumir que falló.

## Acción

- Commit `a43f1fc` — `.mcp.json` nuevo en la raíz del repo, entrada global removida de `~/.claude.json`.
- Cross-referencia: la misma sesión derivó en un diseño de skill `content-filter` (triage de backlog de YouTube/artículos/repos), pero ese spec vive en otro repo (`A-PAchecoT/andre-personal`, commit `1ea75a2`) por ser tooling de hábito personal, no de dotfiles — no se duplica acá.
