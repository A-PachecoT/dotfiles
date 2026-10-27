# 2026-10-26 — Sincronización e interoperabilidad de Skills y Plugins entre Claude Code y Antigravity (Gemini)

**Operador:** André (vía Antigravity / Gemini)

---

## Contexto

André consultó si existía compatibilidad entre los formatos de **Skills** de Claude Code y los de Antigravity / Gemini CLI (`agy`), y si era posible sincronizar al 100% la configuración de usuario (skills personales, ofimática, branding, video) y los plugins internos de Cofoundy para que funcionen indistintamente en ambas herramientas sin duplicar esfuerzo.

## Qué Pasó

1. **Evaluación de Compatibilidad:**
   - Se constató que ambos ecosistemas implementan la misma especificación abierta de **Agent Skills**: directorio con `SKILL.md`, frontmatter YAML (`name`, `description` en tercera persona) y markdown progresivo.
   - La única diferencia radica en las rutas de descubrimiento (`~/.claude/skills` vs `~/.gemini/skills` y `~/.gemini/config/skills`).

2. **Sincronización Bidireccional de Skills:**
   - Se respaldó `~/.gemini/skills` y se reemplazó por un symlink directo a `~/.claude/skills`.
   - Se apuntó también `~/.gemini/config/skills` a la misma ruta.
   - Se crearon symlinks relativos en `~/.claude/skills` para exponer a nivel raíz los skills que estaban anidados o dispersos:
     - Skills oficiales/synced: `pdf`, `docx`, `pptx`, `xlsx`, `docs`, `deep-research`, `built-in-browser`, `chrome-browser`, `computer-use`, `google-workspace`, `morning`, `humanizador`, `skill-creator`, `import-memory`.
     - Skills de coaching personal: `andre-coach`, `secretary`, `wrap-up`.
     - Skills de `.agents/skills`: `find-skills`, `design-taste-frontend`, `redesign-existing-projects`.
   - Con esto, quedaron 48 skills activos y 100% sincronizados en tiempo real: cualquier adición o edición en Claude o Gemini se refleja automáticamente en ambos.

3. **Unificación de Reglas Globales:**
   - Se enlazó `~/.gemini/GEMINI.md` a `~/dotfiles/shared/claude/CLAUDE.md`, unificando las directivas de comportamiento (estilo conciso de 5 líneas, español con tildes, stack de preferencia, etc.).

4. **Importación y Adaptación de Plugins de Cofoundy:**
   - Se descubrió que Antigravity cuenta con soporte de primera clase mediante el comando:
     ```bash
     agy plugin import <path> [--force]
     ```
   - Este comando lee el `.claude-plugin/plugin.json`, genera el `plugin.json` nativo de Antigravity, reubica los `hooks/` al root y convierte los `commands/` de Claude Code en skills ejecutables.
   - Se importaron y habilitaron 13 plugins de Cofoundy en `~/.gemini/config/plugins/`:
     - `cofoundy-toolkit` (1.128.0) — 48 skills, 2 hooks
     - `cofoundy-orchestrator` (0.39.3) — 25 skills, 1 agent, 1 hook
     - `cofoundy-founders` (0.23.4) — 11 skills, 4 agents, 1 hook
     - `brand-skills` (0.3.0) — 17 skills
     - `cofoundy-business` (0.17.3) — 6 skills
     - `basalt` (0.3.3) — 2 skills, 1 MCP server, 2 hooks
     - `cofoundy-finance`, `cofoundy-meta`, `cofoundy-pms`, `cofoundy-docs`, `licita`, `mailglow`, `profile-readme-skills`.

## Aprendizaje

- Un symlink a nivel de directorio de skills (`~/.gemini/skills -> ~/.claude/skills`) es la solución más limpia y con cero overhead de sincronización para skills planos.
- Para plugins, `agy plugin import` es el estándar sanctioned por Antigravity: no solo copia carpetas sino que normaliza el esquema de plugins (incluyendo conversión de `commands` a skills y adaptación de hooks del ciclo de vida).
- Para actualizar cualquier plugin modificado en el monorepo de Cofoundy:
  ```bash
  agy plugin import ~/cofoundy/plugins/<nombre-plugin> --force
  ```

## Acción

- Creados los symlinks bidireccionales en `~/.gemini/skills`, `~/.gemini/config/skills` y `~/.gemini/GEMINI.md`.
- Importados los 13 plugins de Cofoundy mediante `agy plugin import`.
- Registro de esta bitácora en `~/dotfiles/bitacora/2026-10-26-sincronizacion-skills-plugins-claude-gemini.md`.
