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

## Recomendación si se retoma — DECIDIDO 2026-08-26

**Host = la laptop gamer de André, en Lima.** No AWS EC2 (revertido: se perdieron los
créditos free y el egress de un SFU es prohibitivo), no `coworky-no1` (es el único
runner de CI de un cliente, sin SSH, y Nuremberg está a 177 ms de Lima), no una VPS
nueva (la opción técnica era Hetzner Ashburn a 92 ms / ~$16 mes, descartada por caja).

Ventaja real de hostear en casa: el equipo es 100% Lima → latencia de media **<5 ms**,
mejor que cualquier datacenter. El costo objetivo es **$0/mes**.

Forma del despliegue:

- **HTTP/WS + TLS + dominio → Cloudflare Tunnel** (resuelve el doble NAT para TCP sin
  tocar los routers, y de paso la IP pública dinámica).
- **Media → quedarse en P2P**: subir `MAX_USERS_FOR_WEBRTC` (hoy `4`) por encima del
  tamaño del equipo (~6) y **no prender LiveKit**. El túnel no proxea UDP arbitrario,
  así que el SFU exigiría port-forward en los dos routers; con burbujas de proximidad
  de 2-4 personas el mesh alcanza. Queda un TURN de respaldo por resolver.
- **Validar con 5-6 personas reales fuera de la LAN** antes de declararlo listo. El
  error de julio fue exactamente ese: nunca se probó fuera del tailnet.

Detalle completo, riesgos aceptados y próximos pasos:
[`cofoundy-sandbox.md`](./cofoundy-sandbox.md).

Mientras tanto está **cerrado** y no consume nada. El repo, el `.env` y los volúmenes
(`docker_map-storage-data`, `docker_redisdata`) siguen intactos en la Arch — verificado
2026-08-26; los contenedores ya no existen (`down`, no `stop`).
