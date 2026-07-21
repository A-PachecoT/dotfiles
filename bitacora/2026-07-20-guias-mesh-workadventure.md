# Guías para Arbues: mesh + self-host WorkAdventure

**Fecha:** 2026-07-20
**Tipo:** sesión
**Contexto:** Arbues (colaborador) quería replicar el setup de André para "codear desde el celular en cualquier momento" + una guía de instalación del "Gather open source" que André creía haber hecho. Entrega: PDFs branded por Discord (André sin acceso a la compu).

---

## Qué shipeó

- **`docs/guides/codea-desde-el-celular.md`** (nuevo, versionado en el repo) — guía de replicación del mesh: Tailscale (4 devices + topología), Herdr (config real, keybinds 1:1), transporte ET vs mosh, aliases `h`/`ha`/`mu`, bootstrap Termux, Wispr Flow para dictado, flujo diario, troubleshooting, checklist. Fuente: `docs/device-mesh.md` + `shared/zsh/mesh.zsh` + `scripts/termux-bootstrap.sh` + `shared/herdr/`.
- **PDF branded del mesh** (17 pág, vía `md2pdf`) → Discord DM.
- **`~/workadventure/README-SELFHOST.md`** en la caja Arch (archivo local, untracked; NO se tocó el git upstream de WA) — guía de self-hosting de WorkAdventure aterrizada en el deployment real de André.
- **PDF branded de WorkAdventure** (14 pág) → Discord DM.
- **`agent_panel_sort = "priority"`** en `shared/herdr/.config/herdr/config.toml` (cambio pre-existente sin commitear, incluido en el cierre).

## Validación

- Los 3 PDFs se verificaron página-a-página (portada + diagramas) renderizando a PNG antes de enviar. Se corrigió título de portada que desbordaba la barra (regla: título ≤ ~24 chars) y un callout `[!iOS]` no soportado por md2pdf.
- El deployment de WorkAdventure se corroboró leyendo la config REAL en la Arch por SSH del mesh (`.env.template`, `livekit-config.yaml`, ambos compose).

## Decisiones

- **La 1ª guía de "Gather" se descartó**: André aclaró que no era un clon casero sino **WorkAdventure self-hosteado**. Se rehízo desde cero anclada en la config real (subagente + `wa-real-config.txt` extraído por SSH).
- Guía del mesh **sí** se versiona en el repo (onboarding reutilizable); la de WA queda **local en la Arch** porque su repo es el upstream oficial de WorkAdventure (no se le pushea).
- Diagramas de red en **ASCII dentro de code blocks**, no mermaid — renderizan más fiel la topología en md2pdf.

## Learnings

- **El mesh se dogfooded a sí mismo:** el propio SSH-full-mesh sobre Tailscale fue la herramienta que permitió encontrar el repo de WorkAdventure en la Arch (ausente en la Mac) y jalar su config real sin salir de la Mac. El entregable sobre el mesh se produjo *usando* el mesh.
- **WorkAdventure: media híbrido gateado por `MAX_USERS_FOR_WEBRTC`** (=4). ≤4 → WebRTC P2P (STUN/coturn); >4 → LiveKit (SFU). El "solo funcionó con celulares" se explica por `livekit-config.yaml: use_external_ip:false` + `TURN_SERVER` vacío = **condenado a LAN**. Salto a prod = `use_external_ip:true` + abrir `7882/udp` + montar coturn (`3478/udp` + relay).
- **Gotcha del repo WA:** `livekit-config.yaml` declara `udp_port: 7882` pero `docker-compose.livekit.yaml` publica `7881/udp` — reconciliar o el media queda sin salida.
- **md2pdf:** título de portada corto (≤~24 chars) o desborda la barra; callouts soportados = TIP/WARNING/IMPORTANT/NOTE (otros caen a default); box-drawing en code blocks renderiza limpio.
