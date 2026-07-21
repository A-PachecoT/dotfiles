---
title: "Self-host WorkAdventure"
subtitle: "Cómo replicar el experimento de André y saltar a producción con UDP (LiveKit + coturn). Alternativa open-source a Gather.town."
author: "Cofoundy"
date: "2026-07-20"
version: "1.0"
client: "Arbues"
confidentiality: "internal"
abstract: "Guía práctica para levantar tu propia instancia de WorkAdventure con Docker, y —lo más importante— qué falta para que corra en serio: un servidor con IP pública, LiveKit y coturn con sus puertos UDP abiertos. André y su equipo ya lo self-hostearon como experimento (probado solo con celulares en LAN); esta guía está aterrizada en su deployment real (el repo oficial clonado en su caja Arch, en ~/workadventure), no en doc genérica."
toc: true
toc-depth: 3
---

> [!NOTE] Leyenda de confianza — qué está verificado
> A lo largo del documento cada afirmación va etiquetada:
> - **[CONFIG REAL DE ANDRÉ]** — extraído de su instalación real: `~/workadventure` (repo oficial `github.com/workadventure/workadventure` clonado) y sus `.env.template`, `livekit-config.yaml`, `egress-config.yaml`, `docker-compose.single-domain.yaml`, `docker-compose.livekit.yaml`.
> - **[DOC OFICIAL]** — verificado en la documentación / repo oficial de WorkAdventure.
> - **[SUPUESTO]** — inferencia razonable, no textual. Úsalo con criterio.
> - **[DATO DE ANDRÉ]** — lo que André reportó de su experimento (probaron solo con celulares, incompleto para prod).

## 1. Qué es WorkAdventure

**[DOC OFICIAL]** WorkAdventure es una **aplicación web colaborativa (oficina virtual) presentada como un videojuego RPG de 16 bits**. Es open-source, mantenida por TheCodingMachine (repo: `thecodingmachine/workadventure`), y es la **alternativa open-source a Gather.town**.

La idea central:

- Cada persona entra por el navegador y es un **avatar 2D** que camina por un **mapa estilo RPG**.
- Los mapas se dibujan con el editor **[Tiled](https://www.mapeditor.org/)** (formato `.tmj`/`.tmx`), o con el editor de mapas integrado (`ENABLE_MAP_EDITOR=true`, que **[CONFIG REAL DE ANDRÉ]** ya está activo en su `.env`).
- El **video/audio se activa por proximidad**: cuando dos avatares se acercan, se abre una "burbuja" (bubble) y arranca una videollamada **WebRTC**. Te alejas → se corta. Es exactamente la mecánica de Gather.
- El modelo de media es **híbrido**, controlado por `MAX_USERS_FOR_WEBRTC` (**[CONFIG REAL DE ANDRÉ]** = `4`):
  - **≤ 4 personas** en un grupo → **WebRTC P2P / malla directa** entre navegadores (usa STUN + TURN/coturn para atravesar NAT).
  - **> 4 personas** → salta a **LiveKit (SFU)**, que recibe y reenvía los streams centralizadamente (la malla P2P no escala más allá de unos pocos).

Es **self-hostable** por completo con Docker Compose (o Kubernetes vía Helm), y ahí es donde entra esta guía.

---

## 2. Estado del experimento de André (lee esto antes de emocionarte)

**[DATO DE ANDRÉ] + [CONFIG REAL DE ANDRÉ]:**

- André y su equipo **self-hostearon WorkAdventure** clonando el repo oficial en su caja Arch (`~/workadventure`).
- Lo probaron **solo con celulares** (móvil), en la misma red, **no** en producción real.
- Está **incompleto para producción**, y su config lo confirma literalmente:
  - En `livekit-config.yaml`: `rtc.use_external_ip: false` → **LiveKit NO anuncia una IP pública**, solo direcciones locales. Funciona en LAN, no entre redes.
  - En `.env`: `TURN_SERVER=` y `TURN_STATIC_AUTH_SECRET=` **vacíos** → **no hay TURN/coturn configurado**. Solo tiene STUN (el público de Google). Sin TURN, cualquier NAT estricto rompe el P2P.
  - Credenciales **dev por defecto** sin cambiar: `SECRET_KEY=yourSecretKey2020`, `LIVEKIT_API_KEY=devkey`, `LIVEKIT_API_SECRET=12345678901234567890123456789012`.

La conclusión de André es exactamente esta: *"funcionó con celulares (grupos chicos, misma red), pero para producción/escala falta el server con **UDP y el protocolo que sea necesario** abiertos."* Ese "protocolo" son **LiveKit (SFU, UDP 7882)** y **TURN (coturn, UDP 3478 + relay)**. Es la sección §5.

Traducción práctica: el experimento probó el **plano web** (avatares, mapa, señalización) y quizá algo de video **P2P en LAN**, donde los celulares se ven directo. Eso **no escala a internet abierto** — apenas metes gente desde datos móviles u otra red, el NAT rompe todo el media si no tienes `use_external_ip: true` + coturn + puertos UDP abiertos. Ver §5.

---

## 3. Arquitectura (servicios reales y flujo)

### 3.1 Servicios del deployment de André — **[CONFIG REAL DE ANDRÉ]** (verificados en sus compose)

**Servicios base** (`docker-compose.yaml` + `docker-compose.single-domain.yaml`):

| Servicio | Rol | Puerto interno |
|---|---|---|
| **reverse-proxy** (Traefik) | Reverse proxy: enruta TODO bajo un solo dominio (`play.workadventure.localhost`) por path-prefixes, y termina HTTPS en prod. | 80 / 443 |
| **play** | El corazón. Sirve el **juego Phaser** (rol `front`) en `:3000` **y** el **gateway WebSocket** (rol `pusher`, la señalización) en `:3001` con sticky-cookie. Fusiona los antiguos `front` + `pusher`. | 3000 (web) + 3001 (ws) |
| **back** | **Estado del juego** (posiciones, quién está en qué burbuja) vía gRPC. Fuente de verdad de las salas. Ruta `/api`. | 8080 |
| **map-storage** | Servidor de **mapas Tiled** + editor de mapas + UI. Ruta `/map-storage`. | 3000 / 8080 (ui) |
| **uploader** | Sube/sirve archivos de usuarios (audio, imágenes de chat). Usa Redis. Ruta `/uploader`. | 8080 |
| **icon** | Favicons para iframes/embeds en los mapas. Ruta `/icon`. | 8080 |
| **redis** | Store de la Scripting API y estado efímero compartido. | 6379 |

**Servicios de media/LiveKit** (`docker-compose.livekit.yaml`) — **[CONFIG REAL DE ANDRÉ]**:

| Servicio | Imagen | Rol |
|---|---|---|
| **livekit** | `livekit/livekit-server:v1.10.1` | **SFU**: maneja el audio/video cuando la burbuja supera `MAX_USERS_FOR_WEBRTC` (4). Escucha API en **7880**, media WebRTC en **UDP 7882** / **TCP 7881**. |
| **egress** | `livekit/egress:v1.12.0` | **Grabación** de sesiones LiveKit (composita y exporta a S3). Corre privilegiado. |
| **rustfs-livekit** | `rustfs/rustfs:1.0.0-alpha.83` | Almacenamiento **S3-compatible** (open-source) donde egress guarda las grabaciones. |
| **rustfs-livekit-init** | `amazon/aws-cli` | Job efímero que crea el bucket `livekit-recording` al arrancar. |

**Opcionales (no en el core de André):** Jitsi (videoconf embebida en zonas del mapa), Synapse/Matrix (chat persistente), OIDC mock (auth). coturn **no está desplegado todavía** en su setup (por eso `TURN_SERVER` está vacío).

> **Nota de arquitectura clásica vs actual.** Si ves docs viejas hablando de `front` + `pusher` como servicios separados: hoy están **fusionados en `play`** (front = `:3000`, pusher = gateway WS `:3001`). Y `maps` se renombró a `map-storage`. El deployment de André ya usa la arquitectura nueva.

### 3.2 Flujo de una sesión (diagrama ASCII)

```
                       navegador (avatar de cada persona)
                                     │
              HTTPS + WebSocket (TCP 443 → play :3001)  ← SEÑALIZACIÓN
                                     ▼
                        ┌────────────────────────┐
                        │   reverse-proxy         │   ← Traefik: TLS, enruta por
                        │      (Traefik)          │     path bajo un solo dominio
                        └───────────┬─────────────┘
        /  /ws  ,/api ,/map-storage │ /uploader ,/icon
        ┌──────────┬────────────────┼──────────────┬──────────┐
        ▼          ▼                ▼              ▼          ▼
   ┌─────────┐ ┌──────┐      ┌─────────────┐  ┌────────┐ ┌──────┐
   │  play   │►│ back │      │ map-storage │  │uploader│ │ icon │
   │ front + │ │(gRPC │      │ (mapas .tmj)│  └───┬────┘ └──────┘
   │ pusher  │ │state)│      └─────────────┘      │
   └─────────┘ └───┬──┘                           ▼
                   └──────────────► ┌──────────────┐
                                    │    redis      │
                                    └──────────────┘

  ═══════  EL MEDIA (video/audio por proximidad) va por UDP, NO por Traefik ═══════

   Grupo de ≤ 4 personas  (MAX_USERS_FOR_WEBRTC=4):
      navegador A ◄════ WebRTC media P2P, UDP ════► navegador B
           ║                                             ║
           ║  si el NAT/firewall rompe el P2P directo    ║
           ╚══════════►  ┌──────────────┐  ◄════════════╝
                         │   coturn      │  ← RELAY TURN (UDP 3478 + rango relay)
                         │ (IP pública)  │    [HOY VACÍO en la config de André]
                         └──────────────┘

   Grupo de > 4 personas:
      navegadores  ═══════►  ┌─────────────────┐
                             │    LiveKit      │  ← SFU. Media WebRTC UDP 7882.
                             │  (IP pública)   │    use_external_ip DEBE ser true.
                             └────────┬────────┘
                                      ▼ (grabación opcional)
                             egress ─► rustfs (S3) ─► bucket livekit-recording
```

**La idea que tienes que interiorizar:** la **señalización** (quién está dónde, abrir/cerrar burbujas) va por **TCP/WebSocket a través de Traefik → play**. Pero el **video y audio reales viajan por WebRTC sobre UDP** y **NO** tocan Traefik: van **P2P entre navegadores** (≤4, con coturn de respaldo) o por **LiveKit** (>4). Por eso Traefik + HTTPS **no bastan** para producción: te falta abrir el plano **UDP** (LiveKit 7882, coturn 3478 + relay).

---

## 4. Self-hosting paso a paso (replicando el setup de André)

### 4.1 Requisitos del servidor

- **[DOC OFICIAL]** El servidor de WorkAdventure en sí es liviano: **2 CPU / 4 GB RAM** alcanza para hasta **~300 usuarios concurrentes**.
- **[DOC OFICIAL]** **LiveKit y coturn necesitan ser bastante más potentes** — procesan/relayean los streams de video. En prod: server(s) aparte con más CPU y **ancho de banda**.
- **[DOC OFICIAL]** **Dominio con DNS obligatorio**: WebRTC exige **HTTPS con certificado válido**, así que **no puedes** entrar por la IP pelada. Necesitas un `A record` → IP pública.
- **Docker + docker compose** actualizados.
- **Puertos a abrir** (resumen; detalle UDP en §5): `80/tcp` + `443/tcp` (Traefik), `7882/udp` (LiveKit media), `7881/tcp` (LiveKit fallback), `3478/udp` + rango relay (coturn).

### 4.2 El repo (André ya lo tiene clonado)

**[CONFIG REAL DE ANDRÉ]** André ya tiene el repo oficial en `~/workadventure`. Para replicarlo desde cero:

```bash
git clone https://github.com/thecodingmachine/workadventure.git
cd workadventure
```

### 4.3 Preparar el `.env`

**[CONFIG REAL DE ANDRÉ]** el repo trae un `.env.template` (es el que André copió). Cópialo y edítalo:

```bash
cp .env.template .env
```

Valores reales del template de André y qué **cambiar sí o sí para prod**:

```dotenv
# ── Identidad / seguridad ──────────────────────────────────
# ⚠️ DEV DEFAULT INSEGURO — cámbialo por un random fuerte:
SECRET_KEY=yourSecretKey2020        # → openssl rand -hex 32
DOMAIN=workadventure.localhost      # → tu dominio real, SIN "https://"

# ── Juego / burbujas ───────────────────────────────────────
MAX_USERS_FOR_WEBRTC=4              # ≤4 = P2P; >4 = LiveKit SFU
ENABLE_MAP_EDITOR=true
ENABLE_CHAT=true
ENABLE_TUTORIAL=false

# ── STUN / TURN (capa de NAT traversal para el P2P) ───────
STUN_SERVER=stun:stun.l.google.com:19302   # ✓ ya seteado (STUN público Google)
# ⚠️ VACÍOS en la config de André = coturn NO configurado (pendiente de prod):
TURN_SERVER=
TURN_STATIC_AUTH_SECRET=

# ── LiveKit (SFU) ──────────────────────────────────────────
LIVEKIT_HOST=http://livekit.workadventure.localhost   # → https://livekit.tudominio.com en prod
# ⚠️ DEV DEFAULTS — cámbialos en prod (deben coincidir con livekit-config.yaml):
LIVEKIT_API_KEY=devkey
LIVEKIT_API_SECRET=12345678901234567890123456789012

# ── LiveKit recording (egress → rustfs S3) ────────────────
LIVEKIT_RECORDING_S3_ENDPOINT="http://rustfs-livekit:9000"
LIVEKIT_RECORDING_S3_ACCESS_KEY="rustfs-access-key"
LIVEKIT_RECORDING_S3_SECRET_KEY="rustfs-secret-access-key"
LIVEKIT_RECORDING_S3_BUCKET="livekit-recording"
LIVEKIT_RECORDING_S3_REGION="eu-west-1"

# ── Jitsi (opcional) ───────────────────────────────────────
JITSI_URL=meet.jit.si
```

> **Genera secrets de verdad para prod:**
> ```bash
> openssl rand -hex 32      # SECRET_KEY
> openssl rand -hex 16      # LIVEKIT_API_SECRET (y actualízalo también en livekit-config.yaml → keys:)
> ```

### 4.4 Levantar en modo "single-domain" (el camino recomendado para self-host simple)

**[CONFIG REAL DE ANDRÉ]** el repo trae un **`docker-compose.single-domain.yaml`** que hace override para servir **todos los servicios bajo un solo dominio** (`play.workadventure.localhost`) por path-prefixes de Traefik (`/`, `/ws`, `/api`, `/map-storage`, `/uploader`, `/icon`). Es lo ideal para un self-host limpio (un solo cert, un solo DNS para la app). Se levanta apilando compose files:

```bash
# Base + single-domain + LiveKit:
docker compose \
  -f docker-compose.yaml \
  -f docker-compose.single-domain.yaml \
  -f docker-compose.livekit.yaml \
  up -d

docker compose ps          # todos "running"/"healthy"
docker compose logs -f      # seguir logs
```

En prod, reemplaza `workadventure.localhost` por tu dominio real en `.env`, los `livekit-config.yaml`/labels, y configura el DNS (§4.5) + HTTPS (§4.6).

### 4.5 DNS

**[SUPUESTO/DOC OFICIAL]** En single-domain, la app entera vive bajo un dominio; LiveKit va en su subdominio; coturn (cuando lo montes) en el suyo:

```
play.tudominio.com        A → IP_pública_del_servidor        (app entera: /, /api, /map-storage...)
livekit.tudominio.com     A → IP_pública_del_LiveKit         (puede ser el mismo host)
coturn.tudominio.com      A → IP_pública_del_coturn
```

### 4.6 HTTPS con Traefik + Let's Encrypt

**[DOC OFICIAL/SUPUESTO]** El `reverse-proxy` (Traefik) es quien termina TLS. Para prod agrega al servicio `reverse-proxy` un **certificatesresolver ACME** (HTTP challenge) y pon tu email:

```yaml
# command del service reverse-proxy:
- "--certificatesresolvers.myresolver.acme.email=tu-email@dominio.com"
- "--certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json"
- "--certificatesresolvers.myresolver.acme.httpchallenge.entrypoint=web"
# staging mientras pruebas (evita quemar el rate limit):
# - "--certificatesresolvers.myresolver.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory"
```

Y en los routers de cada servicio, `entryPoints=websecure` + `tls.certresolver=myresolver`. Verifica la emisión del cert con `docker compose logs -f reverse-proxy`.

---

## 5. Producción con UDP / LiveKit / coturn — LA SECCIÓN CLAVE

> Esto es exactamente lo que André señaló: *"para que corra en serio hay que correrlo en un servidor, con **UDP y el protocolo que sea necesario**."* Ese plano UDP son **LiveKit** (media de grupos grandes) y **coturn** (relay TURN para el P2P). **Es justo lo que en su config sigue apagado.**

### 5.1 Por qué el media WebRTC necesita STUN, TURN y (para escala) un SFU

El video/audio por proximidad es **WebRTC**, y transporta el media por **UDP** (baja latencia). Como casi nadie tiene IP pública directa (todos detrás de **NAT**: router, red móvil/CGNAT, firewall corporativo), hay tres piezas:

- **STUN** — ligero. El cliente pregunta *"¿cuál es mi IP:puerto público?"* e intenta **hole punching** para P2P directo. **[CONFIG REAL DE ANDRÉ]** ya lo tiene: `stun:stun.l.google.com:19302`. En LAN/NATs amables, con STUN basta → **por eso el experimento con celulares en la misma red funcionó**.
- **TURN (coturn)** — plan B. Cuando el hole punching **falla** (NAT simétrico, CGNAT móvil, firewall que bloquea UDP entrante), todo el media se **relayea** por un servidor TURN con IP pública: A → coturn → B. **[CONFIG REAL DE ANDRÉ]** `TURN_SERVER=` **vacío** = hoy NO hay relay. **[DOC OFICIAL]** sin coturn, **~15% de usuarios fallan** en establecer audio/video (justo los de redes móviles/corporativas).
- **SFU (LiveKit)** — para **>4 personas** en una burbuja, la malla P2P (N×N conexiones) colapsa. LiveKit recibe cada stream una vez y lo reenvía: escala a grupos grandes. Media por **UDP 7882**.

### 5.2 El smoking gun: por qué el experimento SOLO funcionó en LAN/celus

**[CONFIG REAL DE ANDRÉ]** — dos cosas en su config lo condenan a LAN:

1. `livekit-config.yaml` → `rtc.use_external_ip: false`. LiveKit **solo anuncia sus IPs locales** a los clientes. Un navegador en otra red recibe una dirección `192.168.x.x`/`10.x.x.x` inalcanzable → el media no cuaja. **En prod DEBE ser `true`** para que LiveKit anuncie la **IP pública** del server.
2. `TURN_SERVER=` vacío → sin relay TURN. El P2P depende 100% del hole punching por STUN; en cuanto un peer está detrás de NAT estricto, no hay fallback.

```
EXPERIMENTO (LAN / misma WiFi)             PRODUCCIÓN (internet abierto)
──────────────────────────────            ──────────────────────────────
 celu A ◄──── UDP directo ────► celu B     userA (datos móviles, CGNAT)
   mismo router, se ven directo,              │  P2P NO se abre; LiveKit anuncia
   STUN basta, LiveKit anuncia IP local        ▼  IP local inalcanzable
                                            ┌──────────────┐
 ✓ funciona SIN coturn y con               │ coturn / LiveKit │ ← faltan:
   use_external_ip:false                    │  con IP pública  │   coturn config +
   (todo es local)                          └──────────────┘      use_external_ip:true +
                                              ▲                    UDP abierto
                                              │ relay / SFU
                                            userB (firewall corporativo)

 ✗ tal cual está hoy: entre 2 redes distintas el video NO conecta.
```

En la LAN los dos celulares están detrás del **mismo** NAT y se alcanzan directo (y LiveKit local les sirve). Apenas una persona entra desde **datos móviles** u **otra red**, se cae. Eso es lo "incompleto para producción".

### 5.3 Qué cambiar para producción (la checklist técnica de media)

**A) LiveKit — [CONFIG REAL DE ANDRÉ] a modificar:**

En `livekit-config.yaml`:
```yaml
port: 7880
rtc:
    udp_port: 7882
    tcp_port: 7881
    use_external_ip: true        # ← CAMBIAR de false a true (crítico en prod)
keys:
    devkey: 12345678901234567890123456789012   # ← reemplazar por API_KEY:SECRET reales
                                                #   (deben coincidir con el .env)
```
- Abrir **`7882/udp`** (media RTC) en el firewall/security group → host de LiveKit. Este es el puerto por el que fluye el video.
- **[GOTCHA — [CONFIG REAL DE ANDRÉ]]** Ojo con una inconsistencia del repo: `livekit-config.yaml` declara `udp_port: 7882`, pero `docker-compose.livekit.yaml` publica el mapeo `"7881:7881/udp"` (y `7880:7880`). En prod, **reconcilia**: abre y publica el puerto UDP que LiveKit realmente usa (7882 según el config) o alinéalos. No dejes que el config diga 7882 y el firewall/compose solo exponga 7881 — el media quedaría sin salida.
- `7881/tcp` como **fallback** cuando el cliente no puede UDP (redes que solo dejan TCP). `7880` es la API/signaling (va por Traefik).

**B) coturn — [DOC OFICIAL] a agregar (hoy ausente):**

El repo trae un ejemplo de servicio coturn (comentado). Config recomendada:
```yaml
coturn:
  image: coturn/coturn:4.5.2
  command:
    - turnserver
    - --log-file=stdout
    - --external-ip=$$(detect-external-ip)   # IP pública real del host (crítico)
    - --listening-port=3478                  # STUN/TURN
    - --min-port=49152                        # inicio rango relay UDP (default coturn)
    - --max-port=65535                        # fin rango relay UDP
    - --tls-listening-port=5349               # TURN sobre TLS (turns:)
    - --listening-ip=0.0.0.0
    - --realm=coturn.tudominio.com
    - --server-name=coturn.tudominio.com
    - --lt-cred-mech
    # RECOMENDADO: secret compartido, credenciales efímeras:
    - --use-auth-secret
    - --static-auth-secret=<UN_SECRET_LARGO>
    # (alternativa credenciales fijas: --user=workadventure:<password>)
  network_mode: host     # evita el mal rendimiento de Docker mapeando rangos UDP grandes
```
Y en el `.env` de WorkAdventure:
```dotenv
TURN_SERVER=turn:coturn.tudominio.com:3478
TURN_STATIC_AUTH_SECRET=<EL_MISMO_SECRET_QUE_EN_COTURN>
# (o el par fijo: TURN_USER=workadventure  /  TURN_PASSWORD=<password>)
```

### 5.4 Puertos UDP/TCP a abrir en producción — resumen

| Componente | Puerto | Protocolo | Para qué |
|---|---|---|---|
| Traefik | **80**, **443** | TCP | Web + WebSocket (señalización) + Let's Encrypt |
| LiveKit | **7882** | **UDP** | Media WebRTC (SFU) — *el puerto declarado en `livekit-config.yaml`* |
| LiveKit | **7881** | TCP | Fallback media cuando no hay UDP |
| LiveKit | **7880** | TCP | API/signaling (vía Traefik) |
| coturn | **3478** | **UDP** (+ TCP) | STUN/TURN |
| coturn | **5349** | UDP/TCP (TLS) | TURN sobre TLS (`turns:`) — atraviesa firewalls que solo dejan 443/TLS |
| coturn | **49152–65535** (o tu `min–max`) | **UDP** | Rango de relay TURN |

Regla mental: **sin los UDP abiertos (7882 LiveKit + 3478/relay coturn), el video no conecta entre redes**, por más que el HTTPS y el mapa funcionen.

### 5.5 Cómo validar (no repitas el error del experimento)

- **Prueba con 2 dispositivos en redes DISTINTAS** (uno WiFi, otro datos móviles). Probar en la misma LAN **no** valida nada — funcionaría igual roto.
- **STUN/TURN:** [Trickle ICE tester](https://webrtc.github.io/samples/src/content/peerconnection/trickle-ice/) — mete `turn:coturn.tudominio.com:3478` + credenciales y confirma que aparezcan candidatos tipo **`relay`**. Si no hay `relay`, tu coturn/puertos/credenciales están mal.
- **LiveKit:** entra a una burbuja de **5+ personas** y verifica en los logs de `livekit` que reciba tracks; si `use_external_ip:false`, los peers remotos no recibirán media.

---

## 6. Crear y cargar mapas (Tiled + Map Starter Kit)

**[DOC OFICIAL]** breve:

- Los mapas se hacen con **[Tiled](https://www.mapeditor.org/)** y se exportan en **`.tmj`** (JSON de Tiled), con tilesets (spritesheets) y capas. Capas/propiedades especiales definen colisiones, punto de entrada (`start`), zonas de Jitsi/LiveKit, exits a otros mapas, etc.
- Punto de partida: el **[Map Starter Kit](https://github.com/workadventure/map-starter-kit)** de WorkAdventure — repo template con un `office.tmj` de ejemplo y el scaffolding listo.
- Para servir **tus** mapas: súbelos al servicio **`map-storage`** (auth con `MAP_STORAGE_AUTHENTICATION_USER`/`PASSWORD`, o token bearer para CI). Verifícalo en `https://play.tudominio.com/map-storage/`. Luego apunta la sala de inicio a tu mapa.
- **[CONFIG REAL DE ANDRÉ]** con `ENABLE_MAP_EDITOR=true` (ya activo), puedes editar zonas desde el **editor integrado** en el navegador, sin abrir Tiled.

Flujo típico: clonar map-starter-kit → editar en Tiled → subir al `map-storage` → apuntar la sala de inicio.

---

## 7. Checklist de producción + limitaciones conocidas

### 7.1 Checklist de producción

- [ ] Servidor con **IP pública** + **dominio con DNS** (`A record`) — nunca IP pelada.
- [ ] Cambiar **todos los dev defaults**: `SECRET_KEY` (no `yourSecretKey2020`), `LIVEKIT_API_KEY`/`LIVEKIT_API_SECRET` (no `devkey`/`123...32`), y alinearlos con `livekit-config.yaml`.
- [ ] `DOMAIN` real en `.env`; subdominios `livekit.` y `coturn.` en DNS.
- [ ] **HTTPS válido** vía Traefik + Let's Encrypt (probar en staging primero).
- [ ] `80/tcp` + `443/tcp` abiertos → host WA.
- [ ] **LiveKit:** `rtc.use_external_ip: true` **y** `7882/udp` abierto (reconciliar el gotcha 7881/7882 del compose). `7881/tcp` para fallback.
- [ ] **coturn desplegado**: `TURN_SERVER` + `TURN_STATIC_AUTH_SECRET` seteados (hoy vacíos), `--external-ip` = IP pública real, `3478/udp` + rango relay UDP + `5349` abiertos.
- [ ] Probado **entre 2 redes distintas** (WiFi + datos móviles), no solo LAN.
- [ ] Candidatos `relay` confirmados con Trickle ICE; burbuja de 5+ verificada en logs de LiveKit.
- [ ] Recursos dimensionados: WA server liviano (2CPU/4GB ~300 users); **LiveKit + coturn con más CPU y ancho de banda**.
- [ ] Backups de volúmenes (`redis`, `map-storage`, `rustfs`/grabaciones) y de `acme.json` (certs).
- [ ] Auth de `map-storage` habilitada (no dejar el upload abierto al mundo).

### 7.2 Limitaciones y TODO conocido (honesto)

- **[DATO DE ANDRÉ]** El experimento se probó **solo con celulares en la misma red**; eso **no** valida el plano de media para internet abierto.
- **[CONFIG REAL DE ANDRÉ]** TODO #1: `TURN_SERVER`/`TURN_STATIC_AUTH_SECRET` vacíos → **montar coturn** con IP pública + UDP abiertos.
- **[CONFIG REAL DE ANDRÉ]** TODO #2: `use_external_ip: false` en LiveKit → **ponerlo en `true`** y abrir `7882/udp`.
- **[CONFIG REAL DE ANDRÉ]** TODO #3: rotar **todos los secrets dev** (`yourSecretKey2020`, `devkey`, el API secret de LiveKit).
- **[DOC OFICIAL]** Sin coturn, **~15%** de usuarios reales quedan sin audio/video. No es opcional en prod.
- **[DOC OFICIAL]** LiveKit y coturn **consumen recursos serios** (procesan streams); subestimarlos = video entrecortado con varios usuarios.
- **[SUPUESTO]** Self-hostear WA implica **mantenimiento periódico** (imágenes, versiones que deben coincidir). No es "instalar y olvidar".
- **[DATO DE ANDRÉ]** Resumen: el experimento demostró que **se puede self-hostear y usar en LAN**; el salto a prod = **servidor con IP pública + LiveKit (`use_external_ip:true`, UDP 7882) + coturn (TURN, UDP 3478 + relay)**. Eso es lo que queda pendiente.

---

## Referencias

- Deployment real de André: `~/workadventure` (clon de `github.com/thecodingmachine/workadventure`) — `.env.template`, `livekit-config.yaml`, `egress-config.yaml`, `docker-compose.single-domain.yaml`, `docker-compose.livekit.yaml`.
- Repo oficial: `https://github.com/thecodingmachine/workadventure`
- Guía self-hosting: `github.com/workadventure/workadventure/blob/master/docs/others/self-hosting/install.md`
- Variables de entorno (incl. TURN/STUN): `.../docs/others/self-hosting/env-variables.md`
- Map Starter Kit: `https://github.com/workadventure/map-starter-kit` · Tiled: `https://www.mapeditor.org/`
- LiveKit: `https://github.com/livekit/livekit` · coturn: `https://github.com/coturn/coturn`
