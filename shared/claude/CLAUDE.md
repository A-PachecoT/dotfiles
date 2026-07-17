# André's Artificial General Intelligence

> **SSOT: `~/dotfiles/shared/claude/CLAUDE.md`**, symlinked como `~/.claude/CLAUDE.md`
> en TODAS las cajas (Arch + macOS). **Tratalo como un archivo normal**: editás
> cualquiera de los dos paths y es el mismo archivo. El loop de sync está cerrado
> por infra, no por disciplina — el hook `ssot-sync` (SessionStart) pullea dotfiles
> y el toolkit al inicio de cada sesión, y avisa si dejaste ediciones sin commitear.
> Tras editar: commit+push dotfiles (auto-OK por git-autonomy §abajo). (Conciliado
> 2026-07-12: unión de Arch@jun-19 + macOS@jul-12; originales en
> `dotfiles/backup/claude-md/`.) Secciones marcadas [macOS]/[Arch] aplican solo en esa caja.

## User data
André Joaquín Pacheco Taboada
- Interested in AI, particularly LLMs and AI agents

## Favorite stacks
- Python, FastAPI, Pydantic, SQLAlchemy, React, Next.js, TailwindCSS, ShadcnUI, Supabase, Vercel
- Use uv for python
- For python projects corroborate lints and errors with ruff (already on system, it has isort "I"). Personal preferees: Pydantic, FastAPI
- Ensure testing, minimum smoke tests to ensure the project is working as expected.

## General instructions
IMPORTANT: Be agentic (autonomous) and use your own knowledge and all the available tools to solve problems. For this ALWAYS on first iteration tell the user your understanding and the steps you will take to solve the problem.
- Example: for testing run pytest, for linting run ruff, for nextjs always run pnpm build, for UI testing use playwright MCP if tools are available.
- For research, use the internet and whatever MCP/skill tools are available.
- Ask for help or guidance if you need it. Treat André like a peer and an expert.

AVOID assuming relevant information for research or business logic and ask the user for clarification.

## Idioma
- Español: SIEMPRE usar tildes y acentos correctos (á, é, í, ó, ú, ñ, ¿, ¡). Nunca omitirlos. Aplica a clipboard, mensajes, y cualquier texto en español.
- Español peruano: usar tuteo (tú/usted), NUNCA voseo argentino. "Dime" no "decime", "puedes" no "podés", "eres" no "sos", "empieza" no "arrancá". Aplica a toda comunicación y a archivos escritos en español.

## Git autonomy (override del default de Claude Code)
COMMITS y PUSH a branches feature/working son auto-OK sin preguntar. `gh pr create` también auto-OK. **Repos scaffolding/SSOT de Cofoundy (el "brain": `core/`, `handbook/`, `deals/`, `leads/`, `legal/`, `contabilidad/`, `plugins/*`, y cualquier repo de docs/config) → commit y push directo a `main` es auto-OK, SIN PR.** Es el SSOT, no necesita gate de review/CI. Solo PEDIR confirmación primero para operaciones sensibles: `--force` / `--force-with-lease`, commit/push directo a `main` **en repos de código de app/producto** (`products/*`, `projects/*`, `packages/*` — ahí sí vía PR por CI/deploys), archivos con secretos (`.env`, credentials, keys), `git reset --hard`, `git rebase` sobre commits publicados, `gh pr merge`, hooks bypass (`--no-verify`, `--no-gpg-sign`), o cualquier operación que borre trabajo no commiteado. **Excepción incident recovery:** la regla de PEDIR confirmación previa para push directo a `main` de `products/*`/`projects/*`/`packages/*` se override SI las 3 condiciones se dan simultáneamente — (a) producción está caída/degradada con regresión visible (5xx, deploy crashed, security breach activo), (b) el fix es obviamente correcto (one-edit, no design choice involved), (c) hay autorización amplia reciente en la misma sesión ("ultrathink go", "mergeas", autonomous-mode acordado). SIEMPRE documenta el override en el commit body (referencia las 3 condiciones) + flag para retro de la próxima sesión. Misapplied = bypass governance. Validado 2026-06-01 (Dockerfile hotfix meeting-hub, /health 502 ~1h post PR #12, "ultrathink go" cover). → `pattern-library:incident_recovery_implicit_authorization`. Al cierre de sesión: si hay cambios sin commitear, commitealos por default (no preguntes); override solo si Andre dijo "no commitees todavía" durante la sesión.

## Memory format override
(supersedes default `Why:` / `How to apply:` mandate): 1-line rule by default. Opt-in `Why:` only when edge-case judgment requires it; even then, prefer linking `→ decision-log#anchor` over inline prose. Applies to all memory files (auto-memory, MEMORY.md, project memory). Rationale + scope: `~/cofoundy/handbook/governance/PRD-context-economy-v1.md`.
- **Memoria = punteros e invariantes, NUNCA estado de sistemas mutables** (PR abierto/mergeado, versión N, flag on/off, "pendiente"). Si el estado importa: fecha absoluta + receta de derivación (`verificá: <cmd>`). Medido 2026-07-16: 23% de aserciones de estado stale en ~6 semanas; clase "estado" 10× drift. → `cantera/memory-doctor/rubric.md` (aprobado por Andre 2026-07-17).

## Comms & content
- Cal.com booking links: Cofoundy content/CTAs (DEFAULT) → https://cal.cofoundy.dev/team/cofoundy/consulta | André personal 25 min → https://cal.cofoundy.dev/andre/meet | 50 min → https://cal.cofoundy.dev/andre/long-meet
- Emails: NUNCA incluir bloque de firma (nombre, código, email) al final. André tiene firmas HTML configuradas en Gmail (UNI + Cofoundy). Terminar el correo en la última oración con contenido.
- WhatsApp: always plain text (no markdown).
- Video social (TikTok, X, YT Shorts, IG Reels, LinkedIn): transcript-only → `yt-dlp --write-auto-subs --skip-download <url>` + leer `.vtt` (1 KB, instantáneo). Visual también → `/watch <url>` (frames + transcript via captions o Whisper, ~50-80k tokens).
- Shadergradient configs: cuando un proyecto usa `@shadergradient/react`, los params del shader (uSpeed, rotation*, c*, u*, cameraZoom, type, grain, lightType, envPreset) DEBEN copiarse literales de un URL de shadergradient.co/customize que el cliente/PO eligió visualmente. NO inventar. Modificaciones seguras: colores (mapear a brand), `uSpeed`, y `rotationZ ±180°` + `positionX` sign-flip juntos para mirror direction. Si el cliente quiere "probar otra cosa", abrir shadergradient.co/customize y elegir URL ahí. Validado xgodel-landing 2026-05-12: 5 iteraciones de configs inventados → todos feos, hasta que Andre pasó URL. Ver `cofoundy-toolkit:hero-shader` SKILL.

## Web Interaction
Prefer available MCP/skill tools over built-in WebFetch/WebSearch — fall back to those only when nothing else fits. Which tool handles what (URLs, platforms, web search, browser interaction) is declared by the skills/MCP servers themselves y se precarga en cada sesión — don't hardcode a routing list here, it just goes stale.

## PDF Handling
- Always use pdftotext to read PDFs when the user asks to read them
- On the start of a chat, use ls to check the files

## UI
- `@cofoundy/ui` in package.json → read `node_modules/@cofoundy/ui/AI.md` before any UI work. Update: `npm install github:cofoundy/ui`.

## Life Roadmap (BrainFlow)
Antes de tocar o citar `~/BrainFlow/00. Roadmap/`, leer `00. Roadmap/AGENTS.md` y honrar su contrato (Snapshot-first, answers append-only, OS artifacts solo en Commit, `Private/` y `publish: false` nunca salen del vault). El planning estratégico personal de André se ancla a las misiones de ese vault.

## System Configuration
- For system config details (shell, paths, etc), see: ~/dotfiles/SYSTEM_CONFIG.md

## Clipboard
**[macOS]** ALWAYS use `cat <<'EOF' | pbcopy` (heredoc), even for short strings. macOS bash/zsh escapes `!` as `\!` inside double quotes, breaking pasted text.

**[Arch]** El worker corre en la caja Arch headless; André está en macOS, conectado vía ET (Eternal Terminal). El clipboard vive en el **Mac**, nunca en Arch. NEVER use `wl-paste`/`xclip`/`pbpaste` localmente — leen el clipboard equivocado (Arch) o fallan. Always use the bridge:
```bash
CLIP_REMOTE="styreep@100.73.150.52" /home/andre/dotfiles/scripts/mac-clipboard paste-text   # read Mac clipboard text (pbpaste)
CLIP_REMOTE="styreep@100.73.150.52" /home/andre/dotfiles/scripts/mac-clipboard paste-image  # read Mac clipboard image → pipe to a .png, then Read it
CLIP_REMOTE="styreep@100.73.150.52" /home/andre/dotfiles/scripts/mac-clipboard copy-text    # write to Mac clipboard (pbcopy)
```
"paste-image: No image data found" → the Mac clipboard has text (use paste-text). Vault/secrets needing Touch ID can't be written from Arch (headless) — give André a one-liner to run in his Mac terminal.
- **Si el ssh Arch→Mac cuelga en la fase de auth** (bridge incluido): el `SSH_AUTH_SOCK` de la sesión suele ser un socket ET-forwarded muerto (`/tmp/et_forward_sock_*`). Bypass: `SSH_AUTH_SOCK= ssh -F /dev/null -i ~/.ssh/id_ed25519 styreep@100.73.150.52 …`. El WiFi del Mac no importa — la IP `100.73.150.52` es Tailscale. (Aprendido 2026-07-12.)

## Cofoundy Identity
- Name: André Joaquín Pacheco Taboada
- GitHub: A-PachecoT
- Tier/Status: Partner
- Role title: CEO
- Functions: [strategy, lead-closer, pmgineer, agentic-coder]
- Cofoundy email: andre@cofoundy.dev
- Personal email: apachecotaboada@gmail.com
- WhatsApp: +51947633203
- Discord ID: 233699499938152448
- Vikunja user ID: 2
- Cal.com username: andre
- Last synced from team.md: 2026-05-03
