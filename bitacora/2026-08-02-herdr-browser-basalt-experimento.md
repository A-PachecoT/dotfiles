# herdr-browser: experimento de pane embebido para ver páginas de Basalt

**Fecha:** 2026-08-02
**Estado:** experimento pausado — plugin funciona para render/inspección, pero el login de Google dentro del Chromium embebido quedó buggeado
**Continúa de:** [Herdr trial + device mesh 4-way](2026-07-14-herdr-trial-device-mesh.md)

## Contexto

André quería probar [ogulcancelik/herdr-browser](https://github.com/ogulcancelik/herdr-browser)
(Chromium real dentro de un pane de Herdr vía CDP) para, eventualmente, que al
crear/actualizar una página de Basalt (`app.basalt.cofoundy.ai`, MCP interno)
se abra sola al lado en un split.

## Qué pasó

1. **Requisitos:** Herdr 0.7.3 → tocó actualizar a 0.7.4+ (terminó en 0.7.5).
   `herdr update` se niega a correr attached — hubo que detach manual. Herdr
   restaura paneles y **re-engancha cada Claude Code por su `agent_session` id**
   (visible en `session.json`), así que los chats sobrevivieron el restart.
2. Habilitado `[experimental] kitty_graphics = true` en
   `shared/herdr/.config/herdr/config.toml` (commit `0a2f137`).
3. `herdr plugin install ogulcancelik/herdr-browser --yes` → ok.
4. Abrir pane (`herdr plugin pane open --plugin official.browser --entrypoint
   browser --placement split --direction right --env
   HERDR_BROWSER_INITIAL_URL=...`) **sí renderiza** una página real — se
   confirmó apuntando a Basalt, que redirige a `id.cofoundy.dev` (Casdoor).
5. Inspección del login vía CDP (`bun run <plugin_root>/src/cli.ts connect
   --view <id>` + `Runtime.evaluate` por WebSocket) confirmó que Casdoor NO es
   solo Google/GitHub: tiene form usuario+password normal, y soporta agregar
   Email OTP / SMS OTP / WebAuthn-passkeys / SAML-OIDC (Entra ID) desde su
   admin panel — sin código, pero Cofoundy hoy solo tiene habilitado Google.
6. **Bug encontrado:** abrir una conexión CDP directa (paso 5) rompió el
   tracking del daemon del plugin — `bun run cli.ts status` pasó a reportar
   `"views": 0` aunque el pane seguía existiendo como rectángulo vacío (split
   visible, sin contenido). Fix: `herdr pane close` + reabrir pane nuevo
   (daemon y proceso de Chrome se relanzan limpios, `"views": 1`).
7. Con el pane limpio, André probó el login real con Google: **el botón/flow
   de "Next" se quedó buggeado/no respondía** dentro del Chromium embebido.
   No se investigó la causa raíz (¿bloqueo de Google a browser con CDP
   attached? ¿bug de forwarding de input del plugin v0.1.0?). André cerró el
   pane y dejó el experimento ahí.

## Decisiones

- `kitty_graphics` queda habilitado en el config (no molesta, es prerequisito
  para reintentar). El plugin (`official.browser`) queda instalado.
- **No se tocó nada en producción** (Casdoor/Entra ID/OTP quedó solo como
  research — necesita acceso admin a `id.cofoundy.dev` que André no confirmó
  tener a mano, y es infra de auth de todo el equipo, así que cualquier cambio
  ahí va con André mirando en vivo, no autónomo).
- Se descartó la idea de copiar cookies del Chrome real al perfil aislado del
  plugin (frágil, Google puede flaguear el fingerprint distinto, y duplica
  todo el perfil real innecesariamente).

## Learnings

- `herdr server reload-config` no rompe el daemon del plugin, pero **una
  conexión CDP externa directa sí puede desincronizar su view-tracking**.
  Si vuelve a pasar `"views": 0`, el fix es cerrar+reabrir el pane, no reload.
- El plugin es v0.1.0 (`herdr-plugin.toml`), recién lanzado (154 stars al
  momento de instalarlo) — esperable que el input-forwarding hacia flows de
  terceros (OAuth) tenga bugs. No asumir production-ready para flujos
  interactivos complejos todavía.
- Pendiente si se retoma: reproducir el bug del botón "Next" con
  `showDiagnostics=true` en `browser.json` del plugin, o probar con
  `captureBackend` alternativo, antes de reportar upstream o re-intentar.
