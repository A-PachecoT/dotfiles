# Self-hosting — topología de red y exposición pública

SSOT de cómo está la red de la caja Arch (`andre-arch`) y qué hace falta para
exponer **cualquier** servicio self-hosted a internet. Válido para Minecraft,
WorkAdventure, o cualquier cosa futura. Cada servicio documenta lo suyo aparte y
referencia este archivo para la capa de red.

> **Verificar antes de confiar en estos números** (cambian con mudanza / cambio de
> ISP / router): `curl ifconfig.me`, `upnpc -s`, `tailscale netcheck`, `speedtest-cli`.
> Datos medidos el **2026-07-19** en la ubicación de ese día (André estaba fuera de casa).

---

## El problema central: doble NAT + NAT simétrico

```
Internet — BANTEL SAC (AS269843, Lima)
   IP pública: 45.189.109.187   (sin IPv6)
        │
        ▼
  Router ISP  ZTE   192.168.18.1     ← panel web, SIN UPnP, requiere login
        │
        ▼
  Router  TP-Link Archer C50  192.168.68.1
        WAN = 192.168.18.6 (IP privada → confirma el doble NAT)
        UPnP activo (MiniUPnPd) ← la mitad interna se puede automatizar
        │
        ▼
  Arch  192.168.68.114  (WiFi wlan0)  ← los servicios viven aquí
```

Dos routers en cadena, cada uno haciendo NAT. Para que un paquete entrante desde
internet llegue a la caja hay que reenviar el puerto en **ambos**.

### Datos medidos (2026-07-19)

| Métrica | Valor | Nota |
|---|---|---|
| Upload | **57.1 Mbit/s** | Sobra para hostear (un server de juego usa ~0.1 Mbit/s por jugador) |
| Download | 48.1 Mbit/s | — |
| NAT | Doble + **simétrico** (`MappingVariesByDestIP: true`) | Mata el hole-punching confiable (P2P/STUN) |
| IPv6 | No disponible | Relevante para agentes que priorizan IPv6 (ver bug de playit) |
| Latencia a Lima | 26.5 ms | — |
| Jitter primer salto (WiFi→router) | avg 10.4 ms / **max 45.4 ms** | ⚠️ Patológico; debería ser <2 ms |
| Ethernet `enp48s0` | DOWN, sin cable | Conectarlo es la mejora de latencia más barata |
| WiFi | -61 dBm, 1.93M tx retries | Fuente del jitter |

**Conclusión:** el ancho de banda no es el limitante (sobra 100×). Los dos
problemas reales son (1) **atravesar el doble NAT** para exponer puertos, y (2) el
**jitter del WiFi** — se arregla con cable ethernet cuando André esté en casa.

---

## Rutas para exponer un servicio (ordenadas por calidad)

### Ruta A — Port forwarding directo ⭐

Mejor latencia, cero fricción (los usuarios reciben solo `IP:puerto`). Requiere
resolver tres bloqueadores:

1. **Contraseña del router ZTE** (`192.168.18.1`). Suele estar en etiqueta bajo el
   aparato. Alcanzable desde la caja Arch → **se puede configurar en remoto** con
   la contraseña, sin estar en casa.
2. **Doble reenvío** (por el doble NAT):
   - En el **ZTE** (`192.168.18.1`): reenviar el puerto → `192.168.18.6` (WAN del
     TP-Link). **Manual, requiere la contraseña.**
   - En el **TP-Link** (`192.168.68.1`): reenviar el puerto → `192.168.68.114`.
     Tiene **UPnP activo**, así que esta mitad se automatiza desde la Arch:
     `upnpc -a 192.168.68.114 <puerto> <puerto> <udp|tcp>` (o a mano en su panel).
3. **Verificar que BANTEL no haga CGNAT** por encima. Señal buena: la IP pública
   `45.189.109.187` **no** está en rango CGNAT (`100.64.0.0/10`) y responde a
   speedtest. Confirmar de verdad con una prueba entrante (`nc`/`nmap` desde fuera)
   una vez configurado el forward.

> **Mejoras en paralelo:** reserva DHCP (IP fija) para la Arch en el TP-Link, y
> **cable ethernet** en `enp48s0` — quita el jitter y estabiliza la IP interna.

### Ruta B — Túnel público (playit.gg, ngrok con soporte del protocolo, etc.)

Sin tocar el router. Da dirección pública, cero fricción para usuarios. Latencia
mayor (pasa por el edge del túnel). **Ojo con el protocolo:** para juegos UDP el
túnel debe soportar UDP (playit sí; ngrok free no). Ver el estado del intento con
playit en `minecraft-bedrock.md` (bloqueado por bug de IPv6 del agente).

### Ruta C — VPS + túnel propio (fallback robusto)

VPS barato (~$5/mes) con WireGuard o `frp` reenviando el puerto a la caja de casa.
Sin bugs de terceros, latencia media, dirección pública estable. Más setup y cuesta
dinero, pero es lo más confiable si A y B fallan.

---

## Nota sobre Tailscale (descartado para acceso de terceros)

Tailscale **funciona y es gratis** (compartir un nodo no consume asientos del plan;
el free tier ahora son 6 usuarios), pero **obliga a cada usuario a instalar la app
y crear cuenta**. Para "que cualquiera se conecte sin instalar nada" **no sirve** —
usar Ruta A/B/C. Tailscale sí es la vía para el **acceso propio de André** a sus
servicios (ya está montado: `andre-arch = 100.84.249.22`,
`andre-arch.tail706cdf.ts.net`).

---

## Endurecimiento antes de exponer públicamente

Exponer un puerto a internet = cualquiera puede tocarlo. Por servicio:
- Autenticación fuerte (allow-lists, `online-mode`, credenciales).
- Límite de recursos en Docker (`deploy.resources.limits`) para que un abuso no
  tumbe la caja.
- Backups del estado persistente.
- Considerar `nftables`/`ufw` (ahora mismo el firewall local está **inactivo**).
