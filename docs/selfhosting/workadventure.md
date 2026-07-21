# WorkAdventure ("PlayWorld") — self-hosted

Variante self-hosted tipo Gather (mundo 2D con proximity video-chat vía Jitsi).
Estuvo corriendo en la caja Arch. Para la capa de red, ver
[`network-topology.md`](./network-topology.md).

> **Estado (2026-07-19): CERRADO.** Bajado con `docker compose -p docker -f
> docker-compose.prod.yaml down`. Volúmenes conservados. Proyecto en
> `~/workadventure/` (compose en `contrib/docker/docker-compose.prod.yaml`).
> Consumía 7 contenedores (uno, `map-storage`, en bucle de reinicio) y ocupaba los
> puertos 80/443/50051.

## ¿Aplica el mismo port forward que Minecraft?

**Sí para la capa de red — es el mismo doble NAT y los mismos dos routers que hay
que reenviar.** Pero exponer WorkAdventure es **bastante más complejo** que
Minecraft, por tres razones:

| | Minecraft Bedrock | WorkAdventure |
|---|---|---|
| Protocolo/puerto | UDP 19132 (uno) | **TCP 80 + 443** (Traefik) |
| ¿Necesita dominio? | No, basta `IP:puerto` | **Sí** — routers Traefik por `Host(DOMAIN)` |
| ¿Necesita TLS? | No | **Sí** — Let's Encrypt (ACME). El **cámara/mic (WebRTC) exige HTTPS**; sin TLS no funciona el video |
| Componente de video | — | **TURN server (coturn)** → rango **UDP adicional**, y sufre con NAT simétrico |

O sea: el port forward TCP 80/443 es la *misma técnica* (reenviar en ZTE + TP-Link),
pero **no alcanza**. Para exponerlo de verdad haría falta, además:

1. Un **dominio** apuntando a `45.189.109.187` (DNS A record) — y como la IP pública
   es probablemente dinámica, **DDNS** (DuckDNS, Cloudflare, etc.).
2. **Puerto 80 público alcanzable** para el ACME HTTP-challenge de Let's Encrypt
   (o usar DNS-challenge para evitarlo).
3. Setear en el `.env`: `DOMAIN`, `ACME_EMAIL`, y el bloque `TURN_SERVER` /
   `TURN_USER` / `TURN_PASSWORD` (coturn) para que el video atraviese el NAT.
4. Reenviar también el **rango UDP de coturn** — y aun así, con **NAT simétrico** el
   relay de media puede fallar para algunos participantes.

## Recomendación si se retoma

Por el dominio + TLS + WebRTC, WorkAdventure es un candidato **mucho mejor para un
túnel con TLS terminado (Cloudflare Tunnel) o un VPS** (Ruta C) que para port
forwarding casero. Cloudflare Tunnel resuelve dominio + TLS + NAT de una, aunque el
componente TURN/UDP sigue siendo el punto delicado.

Mientras tanto está **cerrado** y no consume nada.
