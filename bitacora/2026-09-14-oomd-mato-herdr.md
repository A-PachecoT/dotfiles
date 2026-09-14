# 2026-09-14 — systemd-oomd mató herdr con 2 /cto adentro

**Operador:** André (+ Claude)

---

## Contexto

André puso **2 `/cto` a correr** en el box Arch y herdr se murió, llevándose las
dos corridas. Pidió evaluar por qué. El box es el mismo que ya había quedado
endurecido contra OOM el 2026-07-04 — y ese hardening fue justamente parte del
problema, por dónde NO llegó.

---

## Qué pasó

**Herdr no crasheó.** `systemd-oomd` mató el *scope de login entero* donde herdr
vivía:

```
Sep 14 16:36:20 systemd-oomd[636]: Marked /user.slice/user-1000.slice/session-924.scope
  for killing due to memory used (30112395264) / total (33382576128) and swap used
  (21352448000) / total (21352669184) being more than 90.00%
Sep 14 16:36:20 systemd[1]: session-924.scope: Consumed 1d 11h 30min CPU over 3d 20h wall,
  14.8G memory peak, 7.8G memory swap peak.
```

El swap llegó a **100%** (21.3G/21.3G) y la RAM a 90%. oomd elige el cgroup con
más swap: ese scope tenía 7.8G. Dentro estaban el `herdr server` **y** los ~20
paneles de agente, así que el kill se los llevó a todos de una.

### Por qué le tocó a herdr y no a un runner

El hardening del 2026-07-04 capeó los **9 runners** (`MemoryHigh=6G` /
`MemoryMax=8G` + `ManagedOOMMemoryPressure=kill`) y dejó el lado usuario **sin
techo**. Cuando la presión viene de los agentes en vez del CI, el único cgroup
gordo que oomd encuentra es la sesión de herdr. El hardening funcionó — tapó la
fuente de 2026-07 y dejó la de 2026-09 abierta.

### El costo real por panel no es `claude`, son sus MCP

Medido con los 19 paneles vivos:

| Qué | Procesos | RSS |
|-----|----------|-----|
| `claude` | 19 | 4.5G |
| MCP que cada claude levanta | 64 (39 firecrawl + 22 playwright + 3 perplexity) | ~6.2G |

**Los MCP pesaban más que los agentes.** Cada instancia de claude levanta su
propio `npm exec firecrawl-mcp` + `npx @playwright/mcp` (≈250 MB entre el
wrapper npm y el node hijo). Costo efectivo ≈ **600 MB por panel**, no 250.

El multiplicador estaba en **`~/.mcp.json`** (en el HOME, así que *todo* proyecto
bajo `~` lo hereda) + `enableAllProjectMcpServers: true` en
`~/.claude/settings.local.json`: auto-aprobado en cada instancia, en cada repo,
la use o no.

Encima corría `fovente-staging-frontend.service` (`next dev`, 4 días arriba):
1.4G residentes, **4.8G de pico y 3.3G de swap** acumulados sin techo.

---

## Qué se hizo

1. **`~/.mcp.json` vaciado** — firecrawl-mcp y playwright fuera; `enabledMcpjsonServers`
   limpiado a nivel user y en inbox-ai/basalt. Backup con la `FIRECRAWL_API_KEY`
   en `~/.config/cofoundy/disabled-mcp/` (chmod 600, fuera de git).
   Reemplazos que ya existían: **`agent-browser`** (vercel-labs) para browser —
   instalado, faltaba en esta caja (`command not found`), que es por qué todo
   caía al MCP; **WebSearch/WebFetch nativos + skill `agent-reach`** para fetch/search.
2. **`herdr.service`** (`~/.config/systemd/user/herdr.service`, enabled) — herdr deja
   de vivir en el scope de login. `Restart=always`, `OOMPolicy=continue`,
   `ManagedOOMPreference=avoid`, `MemoryHigh=12G`.
   **No se arrancó**: hacerlo mata el herdr vivo. Toma efecto al próximo restart
   de herdr o del box.
3. **Techo del lado usuario** — `/etc/systemd/system/user-1000.slice.d/10-memory-cap.conf`
   con `MemoryHigh=20G` (reclaim, no kill), y en caliente sobre el scope vivo:
   `systemctl set-property session-1031.scope ManagedOOMPreference=avoid MemoryHigh=12G --runtime`.
4. **Staging capeado y reciclado** — drop-in `MemoryHigh=1500M`/`MemoryMax=2500M` en
   `fovente-staging-frontend.service` + restart. `Restart=always` ya estaba, así que
   matarlo a secas no servía de nada.
5. **`seo-audit` migrada** a `agent-browser` (era la única skill que dependía de
   `mcp__playwright__`) — commit `4dc70bc` en cofoundy-business.

---

## Validación

| Antes | Después |
|-------|---------|
| load 39.79 | **4.06** |
| swap 20.3G/20.3G (100%) | 16.4G/20.3G |
| staging: 1.4G RSS, 3.3G swap | 466M RSS, capeado a 2.5G |
| `agent-browser`: no instalado | 0.37.1, `doctor` 10 pass / 0 fail, launch headless 0.72s |

`agent-browser eval --stdin` verificado 1:1 contra `browser_evaluate` sobre una
página real antes de migrar la skill (no según la doc: `eval` toma una
**expresión**, no una arrow function, y hay que pasarla por heredoc — inline se
rompe con las comillas anidadas de los selectores).

Estado que queda pendiente de un restart de herdr — **verificá**:
`systemctl --user is-active herdr.service` (debe decir `active`, no `inactive`).

---

## Decisiones

- **No matar el `next dev` de staging, reiniciarlo.** Yo se lo describí a André
  como "un dev server que un agente dejó vivo" y él dijo "mátalo". Era un servicio
  deliberado con `Restart=always`: matarlo tumba staging y revive en 3s. El
  restart libera lo mismo sin downtime.
- **No bajar `SwapUsedLimit` ni `vm.swappiness` todavía.** Con el swap aún al 80%,
  bajar el umbral de oomd dispara kills inmediatos. Primero hay que drenar el
  swap (reboot o reciclar paneles); recién ahí tiene sentido bajar de 90%.
- **No matar los 64 MCP vivos.** El beneficio (−5G) no paga romperle la
  herramienta a 19 agentes en vuelo. El `MemoryHigh` recién puesto los recicla
  solo, y mueren al reciclar paneles.
- **`~/dotfiles/.mcp.json` NO se toca** aunque su path sea de macOS
  (`/Users/styreep/...`): fue deliberado (bitácora 2026-08-04, chrome-mcp
  escopeado a este repo) y en Arch cuesta un arranque fallido, no RAM.

---

## Learnings

- **Un MCP declarado en `~/.mcp.json` no se paga una vez, se paga por instancia
  de agente.** En el HOME lo hereda todo proyecto bajo `~`; con
  `enableAllProjectMcpServers: true` ni siquiera pregunta. 2 `/cto` → 19 paneles →
  64 procesos MCP y 6.2G, más que los agentes mismos.
- **Capear una fuente de OOM reapunta el kill, no lo elimina.** Con los 9 runners
  capeados y el lado usuario abierto, el cgroup más gordo pasó a ser la sesión de
  herdr — y matarla cuesta *todas* las sesiones de agente a la vez, mientras que
  matar un runner cuesta un job que reintenta. Cualquier cap parcial hay que
  leerlo como "¿quién es ahora el más gordo sin techo?".
- **Meter el multiplexor y sus paneles en un solo cgroup hace que el blast radius
  sea todo.** El server tiene que ser un servicio propio para que systemd lo
  reviva en vez de que se lo lleve puesto la sesión de login.
- **`Restart=always` invalida "matá el proceso que sobra".** Antes de matar algo
  gordo hay que mirar de qué unit cuelga: si es un servicio, el kill no libera
  nada y encima puede tumbar un entorno.
- **Un CLI vale más que un MCP para capacidades que se usan a ráfagas.**
  `agent-browser` cuesta 0 hasta que lo invocás; el MCP equivalente cuesta 250 MB
  por agente, esté o no usándolo.
