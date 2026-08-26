# Cofoundy Sandbox — homelab compartido

Entorno sandbox/homelab **compartido de toda la empresa** — el análogo del
device-mesh que André tiene en su Arch (ver [`device-mesh.md`](../device-mesh.md)),
pero para todo el equipo. El disparador original fue
[WorkAdventure](./workadventure.md); para la capa de red ver
[`network-topology.md`](./network-topology.md).

> **Estado (2026-08-26): host = laptop gamer en casa de André. AWS EC2 REVERTIDO.**
> Decisión tomada con la caja de la empresa apretada; objetivo de costo **$0/mes**.
> Nada implementado todavía.

## Historial de la decisión (cambió dos veces — leé esto antes de re-proponer cloud)

| Fecha | Decisión | Qué pasó |
|---|---|---|
| 2026-07-24 | **AWS EC2** (t3.large) | Elegido por governance/billing centralizado en la cuenta Cofoundy. **Nunca se implementó** — requería `aws sso login` por browser y quedó parado. |
| 2026-08-26 | **Revertido → laptop gamer** | André: EC2 salía **MUY caro** para este uso y **se perdieron los créditos free de AWS**. Sin ese colchón, la cuenta paga tarifa lista desde el día 1. |

## Por qué NO AWS EC2

1. **Se perdieron los créditos free** (André, 2026-08-26). El plan de 2026-07-24 asumía
   implícitamente ese colchón para la fase de discovery.
2. **El egress mata.** WorkAdventure con >4 personas enruta todo el video por un SFU
   (LiveKit), y un SFU es una máquina de subir bytes: una llamada de 6 personas son
   ~30 streams salientes ≈ **13 GB/hora**. 20 h/mes ≈ 270 GB → a ~$0.09/GB de egress
   son **~$24/mes solo de tráfico**, creciendo con el uso, *encima* de la instancia.
3. **No entra en el presupuesto.** El budget de la cuenta es `cofoundy-monthly-50usd`
   con alerta al 80% — una t3.large encendida 24/7 más ese egress lo revienta sola.
   Ver `cofoundy/handbook/infrastructure/aws.md`.

**Corolario:** AWS sigue siendo la cuenta de la empresa para lo demás. Lo que se
revierte es **poner ahí un workload de media en tiempo real**, que es el peor
encaje posible con su modelo de precios.

## Por qué NO `coworky-no1` (la VPS Hetzner que ya tenemos)

Existe una VPS Hetzner de la empresa — **cx23, Nuremberg (NBG1), 4 vCPU / 7.56 GiB,
37 GB de disco, ~$7/mes, id 55102306** — pero no sirve para esto. Tres bloqueantes
independientes:

1. **No hay acceso interactivo.** Sin SSH, sin `hcloud`, fuera del tailnet, sin ítem
   en el vault, y el API de GitLab devuelve `ip_address: null`. El único canal real
   es un job de CI manual. → `cofoundy/projects/pets-marketplace/.cofoundy/specs/architecture-vps-staging.md` §M7
2. **Es el único runner de CI de un proyecto de cliente** (`run_untagged: true`,
   ningún job con tags → todo el CI/CD de pets-marketplace pasa por ahí). Ya satura
   sus 4 cores a **2.4x** durante un pipeline (loadavg 5m = 9.79, medido 2026-08-18).
   Montarle un SFU encima acopla las comms de la empresa al CI de un cliente.
3. **Nuremberg.** 177 ms RTT medido desde Lima (2026-08-26, `ping nbg1-speed.hetzner.com`).

## Por qué NO una VPS nueva (y qué se aceptó a cambio)

La recomendación **técnica** era una Hetzner **CPX31 en Ashburn** (~$16/mes): 92 ms
desde Lima (vs 177 de Nuremberg, vs 119 de Hillsboro — los tres medidos 2026-08-26),
IP pública directa y ~20 TB de tráfico incluido.

**Descartada por caja.** André, 2026-08-26: *"es un riesgo que asumo porque es
cheaper y ahora no tenemos mucha plata"*. Decisión de negocio explícita, no un
descuido. Si entra plata, esta es la primera pieza a comprar.

## La decisión: la laptop gamer

Laptop gamer de André, <2 años, sin uso hace un año. Siempre enchufada.

**Ventaja que ninguna nube tiene:** está en Lima, igual que el equipo. Latencia de
media **<5 ms** contra 92 ms del mejor datacenter. Para un equipo 100% Lima,
self-hostear en casa es *técnicamente superior*, no solo más barato.

### Riesgos aceptados explícitamente (André, 2026-08-26)

| Riesgo | Estado |
|---|---|
| Batería muerta = sin UPS; un corte de luz mata las comms al instante | **Aceptado.** "La podemos arreglar; hasta ahora nunca se nos ha ido la luz." Arreglar la batería la convierte en su propio UPS — es la mitigación más barata que existe. |
| Depende del router / ISP / breaker de una casa particular | **Aceptado** por costo. |
| IP pública dinámica | Se resuelve con Cloudflare Tunnel (abajo). |

### Lo que todavía hay que resolver (esto NO es riesgo aceptado, es trabajo pendiente)

El doble NAT de la casa (ZTE + TP-Link, ver `network-topology.md`) es un problema
**funcional**, no un riesgo. Plan propuesto, en orden de costo:

1. **HTTP/WS/TLS/dominio → Cloudflare Tunnel.** Resuelve dominio + TLS + NAT para TCP
   de una, gratis, sin tocar los routers. Ya tenemos `cofoundy.dev` en Cloudflare.
2. **Media ≤4 personas → P2P WebRTC.** Solo necesita STUN + un TURN de respaldo.
3. **Media >4 → aquí está el nudo.** LiveKit necesita un puerto **UDP** públicamente
   alcanzable, y **el túnel de Cloudflare no proxea UDP arbitrario**. Dos salidas:
   - **(a) Quedarse en P2P**: subir `MAX_USERS_FOR_WEBRTC` (hoy `4`) por encima del
     tamaño del equipo (~6) y **no prender LiveKit**. En WorkAdventure la mayoría del
     tiempo hay 2-4 personas por burbuja de proximidad — el mesh solo sufre en el
     all-hands. **Camino recomendado para empezar: costo $0.**
   - **(b) Port-forward UDP** en los dos routers + DDNS. Gratis pero frágil con IP
     dinámica, y con NAT simétrico el relay puede fallar igual.
4. **TURN.** Cloudflare Realtime ofrece TURN gestionado con tier gratis.
   ⚠️ **Verificar límite y precio vigentes antes de depender de eso** — no está
   confirmado en esta sesión. Alternativa: coturn en la propia laptop (gratis, pero
   vuelve al problema de UDP público del punto 3).

### Specs — PENDIENTE de medir

Marca/modelo/CPU/RAM/disco de la laptop: **desconocidos**. Medir antes de sizear
nada. `verificá:` correr en la laptop `lscpu | head -20; free -h; df -h /`.
WorkAdventure solo pide ~2-4 GB, pero el uso compartido (abajo) es lo que manda.

## Propósito multi-uso (lo que vivirá ahí)

1. **WorkAdventure** — mundo social del equipo, el disparador original. Junto con
   **Buzz** es el reemplazo de Discord: Buzz = texto/async/agentes, WA = presencia
   ambiente y voz espontánea. (Verificado 2026-08-26: Buzz **no** tiene llamadas hoy
   — `buzz-voice` es TTS/STT local, `buzz-media` es subida de archivos; los huddles
   están en `VISION.md`, no en los crates. No hay redundancia.)
2. **Sandbox de pruebas** — levantar stacks Docker sin cargar la laptop propia.
   **Ayuda directa a Juan**, que necesita mejor equipo para probar aplicaciones.
3. **Segundo runner de CI (con tags)** — descarga a `coworky-no1`, que hoy está
   saturado a 2.4x. Los timeouts flaky de `pets-marketplace` bajo concurrencia 2 son
   inanición de CPU; esto los ataca en la raíz.
4. **Nodo Tailscale del mesh** — acceso desde cualquier caja del equipo.
5. **Agentes de Hermes** — correr agentes persistentes fuera de la máquina de André.

## Próximos pasos

1. Prender la laptop, medir specs, instalar Arch/Debian + Docker + Tailscale.
2. Clonar WorkAdventure y portar la config real que ya existe en la Arch
   (`andre-arch:~/workadventure/contrib/docker/.env` — ver [`workadventure.md`](./workadventure.md)).
3. Cloudflare Tunnel → subdominio de `cofoundy.dev`, TLS terminado en el edge.
4. Subir `MAX_USERS_FOR_WEBRTC`, dejar LiveKit apagado, y **validar con 5-6 personas
   reales** antes de declarar nada (el error de julio fue no validar fuera de la LAN).
5. Arreglar la batería → UPS gratis.
6. Documentar en `cofoundy/handbook/infrastructure/` (SSOT de infra Cofoundy) y dar
   acceso al equipo.

## Pendiente de contenido

André grabará **videos de YouTube** sobre estos setups. Los temas/guiones se definen
aparte; este doc es el SSOT técnico que los alimenta.
