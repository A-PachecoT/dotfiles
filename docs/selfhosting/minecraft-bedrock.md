# Servidor Minecraft Bedrock — self-hosted

Servidor de Minecraft Bedrock (compatible con Pocket Edition / móvil / Windows /
consola) en la caja Arch. Para la capa de red (doble NAT, cómo exponer), ver
[`network-topology.md`](./network-topology.md).

> **Estado (2026-07-21): APAGADO** a pedido de André ("ya no jugaremos"). El setup
> funciona y está probado; está detenido para no consumir recursos. El mundo se
> conserva. Proyecto operativo en `~/minecraft-bedrock/` (no versionado; el mundo
> `data/` es pesado). Este doc es el SSOT para reconstruirlo.

## Restricción de diseño

Acceso **público sin fricción**: los amigos reciben `dirección:puerto` y entran,
**sin instalar apps**. Por eso Tailscale queda descartado (ver network-topology).

## docker-compose.yml

```yaml
services:
  bedrock:
    image: itzg/minecraft-bedrock-server
    container_name: minecraft-bedrock
    restart: unless-stopped
    ports:
      - "19132:19132/udp"        # protocolo Bedrock RakNet (UDP)
    environment:
      EULA: "TRUE"
      GAMEMODE: survival
      DIFFICULTY: normal
      SERVER_NAME: "Server de Andre"
      LEVEL_NAME: "mundo-amigos"
      MAX_PLAYERS: "10"
      ONLINE_MODE: "true"        # exige cuenta real de Xbox Live
      ALLOW_LIST: "false"        # ⚠️ cualquiera con la dirección entra
      ALLOW_CHEATS: "false"
      VIEW_DISTANCE: "16"
      TICK_DISTANCE: "4"
      SERVER_PORT: "19132"
    volumes:
      - ./data:/data
    deploy:
      resources:
        limits:
          memory: 3G
```

Consumo medido: **~166 MB RAM, ~1% de un core.** Trivial para esta caja.

## Operación

```bash
cd ~/minecraft-bedrock
docker compose up -d                 # arrancar
docker compose down                  # parar (el mundo se conserva en data/)
docker logs -f minecraft-bedrock     # logs
docker exec minecraft-bedrock allowlist add <gamertag>   # gestionar allow-list
```

## Conectarse (una vez expuesto)

Minecraft → **Jugar → Servidores → Agregar servidor** → `Dirección: <IP/host público>`,
`Puerto: 19132`. Acceso propio de André vía Tailscale: `100.84.249.22:19132`.

## Lo que falta para el acceso público final

Solo falta **exponer el UDP 19132**. Las rutas están en
[`network-topology.md`](./network-topology.md). Resumen específico:

- **Ruta A (port forward)** — la mejor: `45.189.109.187:19132`, latencia ~25-40 ms,
  cero fricción. Bloqueada por: **contraseña del router ZTE** (+ doble reenvío,
  UPnP en el TP-Link automatiza la mitad interna).
- **Ruta B (playit.gg)** — casi montada, **bloqueada por bug del agente**:
  - `playit-bin` (AUR) v1.0.10, servicio systemd (user `playit`).
  - Agente **reclamado OK**: `agent_id=db6e4bd4-99e0-473e-8ae7-7efd2eace652`,
    secreto en `/etc/playit/playit.toml` (formato `secret_key = "<hex>"`, correcto).
  - **Bug [playit-agent #194](https://github.com/playit-cloud/playit-agent/issues/194):**
    el agente prueba IPv6 primero; sin IPv6 funcional entra en bucle
    `SessionNotSetup` → dashboard lo ve *offline*. El secreto/auth están bien.
  - Fix intentado (parcial, no resolvió): override systemd
    `RestrictAddressFamilies=AF_INET AF_UNIX` en
    `/etc/systemd/system/playit.service.d/override.conf`.
  - Pendiente por probar: pinnear una versión anterior del agente; o (invasivo,
    descartado) `sysctl net.ipv6.conf.all.disable_ipv6=1` host-wide.
  - Estado: **parado y deshabilitado** (`systemctl disable --now playit`). Secreto
    guardado por si se retoma.

## Endurecimiento antes de exponer

Con `allow-list=false` cualquiera con la dirección entra (aunque `online-mode=true`
exige cuenta real de Xbox Live). Antes de dejarlo público desatendido:
`ALLOW_LIST: "true"` + `allowlist add <gamertag>` de cada amigo; ajustar
`MAX_PLAYERS`; backups de `data/worlds/`.
