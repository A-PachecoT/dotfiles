---
when: "Una regla de ~/.claude/CLAUDE.md te parece arbitraria, querés el incidente que la compró, o vas a cambiarla: acá está el texto ORIGINAL de cada sección comprimida el 2026-09-14."
---

# Los porqués de `~/.claude/CLAUDE.md`

El `CLAUDE.md` global se auto-carga en CADA sesión de CADA repo (PRD context-economy: regla en una
línea, el porqué se enlaza). El 2026-09-14 medía 14,4k chars y se comprimió a ≤7k; lo que salió está
acá **verbatim**, sección por sección, con el mismo título que la regla que lo apunta. No es una
superficie pre-cargada: se lee cuando el puntero manda.

## Nota de cabecera: SSOT y conciliación

> **SSOT: `~/dotfiles/shared/claude/CLAUDE.md`**, symlinked como `~/.claude/CLAUDE.md`
> en TODAS las cajas (Arch + macOS). **Tratalo como un archivo normal**: editás
> cualquiera de los dos paths y es el mismo archivo. El loop de sync está cerrado
> por infra, no por disciplina — el hook `ssot-sync` (SessionStart) pullea dotfiles
> y el toolkit al inicio de cada sesión, y avisa si dejaste ediciones sin commitear.
> Tras editar: commit+push dotfiles (auto-OK por git-autonomy §abajo). (Conciliado
> 2026-07-12: unión de Arch@jun-19 + macOS@jul-12; originales en
> `dotfiles/backup/claude-md/`.) Secciones marcadas [macOS]/[Arch] aplican solo en esa caja.

## General instructions — auto mode e intención → deliberación → producto

**"auto mode" / "igtg" / "/cto auto" = contrato de autonomía.** André entrega ejecución completa y se va: tomá vos las decisiones (incluida "¿por dónde empiezo?" — rechazó un `AskUserQuestion` mid-task con *"whatever just /cto auto mode igtg"*), shippeá lo verificable y dejá como gate humano lo que toca prod. **Parar ante riesgo DESCUBIERTO** (colisión de migraciones, rama hermana en vuelo) es obligatorio; parar ante una pregunta desperdicia la ventana. Cerrá con punto de resume limpio: rama commiteada, issues abiertos, handoff.

**Intención → deliberación → producto; nunca intent-a-pila-de-tareas.** Su queja explícita: *"las tareas se hacen como deben, pero no han sido reevaluadas, replaneadas."* Consolidá toda intención de producto en un SSOT durable ANTES de cualquier tarea (con sus palabras, no un resumen); corré loops de consejo en paralelo y terminá en gate humano, no en auto-ejecución. Nunca absorbas en silencio un pivot de scope o visión — explicitalo.

## Git autonomy (override del default de Claude Code)

COMMITS y PUSH a branches feature/working son auto-OK sin preguntar. `gh pr create` también auto-OK. **Repos scaffolding/SSOT de Cofoundy (el "brain": `core/`, `handbook/`, `deals/`, `leads/`, `legal/`, `contabilidad/`, `plugins/*`, y cualquier repo de docs/config) → commit y push directo a `main` es auto-OK, SIN PR.** Es el SSOT, no necesita gate de review/CI. Solo PEDIR confirmación primero para operaciones sensibles: `--force` / `--force-with-lease`, commit/push directo a `main` **en repos de código de app/producto** (`products/*`, `projects/*`, `packages/*` — ahí sí vía PR por CI/deploys), archivos con secretos (`.env`, credentials, keys), `git reset --hard`, `git rebase` sobre commits publicados, `gh pr merge`, hooks bypass (`--no-verify`, `--no-gpg-sign`), o cualquier operación que borre trabajo no commiteado. **Excepción `gh pr merge` (auto-OK si se cumplen las 2):** (a) **`gh pr checks <pr>` sale con exit 0** — el comando, NUNCA tu parseo de `statusCheckRollup`: un PR apilado sobre otra rama devuelve CERO check-runs y ese array vacío se lee como "sin fallos" cuando significa "sin señal"; `gh` sale 1, tu jq sale en blanco (verificado en inbox-ai#278). Es lo que `handbook/governance/git-strategy.md` ya exige para Tier B, sin aprobación humana. ⚠️ **Esto es de GitHub. En GitLab NO se traduce: `glab mr checks <n>` NO EXISTE — imprime la ayuda y sale 0**, así que el gate se lee verde siempre (medido 2026-08-31 en pets-marketplace, y ya estaba en su `SONDAS-QUE-MIENTEN.md` §2 con otro MR). En repos GitLab el gate equivalente es la **API de jobs**: `glab api "projects/:id/pipelines/<id>/jobs"` → cero `failed`, cero `skipped`, y `head_pipeline.sha` == sha del MR. Un `skipped` no es verde y un `manual` pendiente deja el resumen del pipeline en `running` para siempre. (b) el PR no prende ninguna capacidad autónoma por default (`ai-agent-autonomy.md` §deferred blast radius — el merge no debe dejar viva una capacidad que actúe sola); asiste `agent-decision.py derive`, que lista los defaults del diff (candidatos, no veredicto). Fuera de esas 2, `gh pr merge` sigue pidiendo confirmación. Dos cosas que NO son condición: que ningún floor haya disparado (un floor bloquea la ACCIÓN cuando ocurre, no es consultable al mergear — si hay PR, ninguno disparó), y que las decisiones de juicio estén en `agent-decisions.jsonl` (eso es auditabilidad, no seguridad: su ausencia hace el merge opaco, no peligroso). **Excepción incident recovery:** la regla de PEDIR confirmación previa para push directo a `main` de `products/*`/`projects/*`/`packages/*` se override SI las 3 condiciones se dan simultáneamente — (a) producción está caída/degradada con regresión visible (5xx, deploy crashed, security breach activo), (b) el fix es obviamente correcto (one-edit, no design choice involved), (c) hay autorización amplia reciente en la misma sesión ("ultrathink go", "mergeas", autonomous-mode acordado). SIEMPRE documenta el override en el commit body (referencia las 3 condiciones) + flag para retro de la próxima sesión. Misapplied = bypass governance. Validado 2026-06-01 (Dockerfile hotfix meeting-hub, /health 502 ~1h post PR #12, "ultrathink go" cover). → `pattern-library:incident_recovery_implicit_authorization`. Al cierre de sesión: si hay cambios sin commitear, commitealos por default (no preguntes); override solo si Andre dijo "no commitees todavía" durante la sesión.

## Memory format override

(supersedes default `Why:` / `How to apply:` mandate): 1-line rule by default. Opt-in `Why:` only when edge-case judgment requires it; even then, prefer linking `→ decision-log#anchor` over inline prose. Applies to all memory files (auto-memory, MEMORY.md, project memory). Rationale + scope: `~/cofoundy/handbook/governance/PRD-context-economy-v1.md`.
- **Memoria y docs = punteros e invariantes, NUNCA estado de sistemas mutables** (PR abierto/mergeado, versión N, flag on/off, "pendiente"). Si el estado importa: fecha absoluta + receta de derivación (`verificá: <cmd>`). Medido 2026-07-16: 23% de aserciones de estado stale en ~6 semanas; clase "estado" 10× drift. → `cantera/memory-doctor/rubric.md` (aprobado por Andre 2026-07-17). Vale igual en docs commiteados: una aserción de estado sin fecha ni receta se lee como verdad viva y manda a rehacer algo ya hecho. → `core/docs/decision-log.md#2026-09-04-estado-mutable-en-docs`

## Comms & content — shadergradient

- Shadergradient configs: cuando un proyecto usa `@shadergradient/react`, los params del shader (uSpeed, rotation*, c*, u*, cameraZoom, type, grain, lightType, envPreset) DEBEN copiarse literales de un URL de shadergradient.co/customize que el cliente/PO eligió visualmente. NO inventar. Modificaciones seguras: colores (mapear a brand), `uSpeed`, y `rotationZ ±180°` + `positionX` sign-flip juntos para mirror direction. Si el cliente quiere "probar otra cosa", abrir shadergradient.co/customize y elegir URL ahí. Validado xgodel-landing 2026-05-12: 5 iteraciones de configs inventados → todos feos, hasta que Andre pasó URL. Ver `cofoundy-toolkit:hero-shader` SKILL.

## Web Interaction — un MCP en ~/.mcp.json se paga por instancia

**Un MCP en `~/.mcp.json` (o cualquier `.mcp.json` bajo `~`) se paga POR INSTANCIA de agente, no una vez** — lo hereda todo proyecto bajo `~` y `enableAllProjectMcpServers: true` lo auto-aprueba sin preguntar. Medido 2026-09-14 en la caja Arch: 19 paneles de claude = 4.5G; sus MCP = 64 procesos y 6.2G (≈250 MB cada uno entre el `npm exec` y el node hijo), y eso fue parte de lo que llenó el swap y le hizo matar a oomd la sesión de herdr con 2 `/cto` adentro. Antes de agregar un server ahí, multiplicá su RSS por los paneles que vas a correr; para capacidades de ráfaga preferí un CLI (`agent-browser` para browser, WebSearch/WebFetch + `agent-reach` para fetch/search), que cuesta 0 hasta que lo invocás. Verificá: `cat ~/.mcp.json` y `ps -eo args | grep -oE "<server>" | wc -l`. → `dotfiles/bitacora/2026-09-14-oomd-mato-herdr.md`

## Clipboard [Arch]

**[Arch]** El worker corre en la caja Arch headless; André está en macOS, conectado vía ET (Eternal Terminal). El clipboard vive en el **Mac**, nunca en Arch. NEVER use `wl-paste`/`xclip`/`pbpaste` localmente — leen el clipboard equivocado (Arch) o fallan. Always use the bridge:
```bash
CLIP_REMOTE="styreep@100.73.150.52" /home/andre/dotfiles/scripts/mac-clipboard paste-text   # read Mac clipboard text (pbpaste)
CLIP_REMOTE="styreep@100.73.150.52" /home/andre/dotfiles/scripts/mac-clipboard paste-image  # read Mac clipboard image → pipe to a .png, then Read it
CLIP_REMOTE="styreep@100.73.150.52" /home/andre/dotfiles/scripts/mac-clipboard copy-text    # write to Mac clipboard (pbcopy)
```
"paste-image: No image data found" → the Mac clipboard has text (use paste-text). Vault/secrets needing Touch ID can't be written from Arch (headless) — give André a one-liner to run in his Mac terminal.
- **Si el ssh Arch→Mac cuelga en la fase de auth** (bridge incluido): el `SSH_AUTH_SOCK` de la sesión suele ser un socket ET-forwarded muerto (`/tmp/et_forward_sock_*`). Bypass: `SSH_AUTH_SOCK= ssh -F /dev/null -i ~/.ssh/id_ed25519 styreep@100.73.150.52 …`. El WiFi del Mac no importa — la IP `100.73.150.52` es Tailscale. (Aprendido 2026-07-12.)
