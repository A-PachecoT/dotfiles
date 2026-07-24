# Cofoundy Sandbox — homelab compartido en AWS

Decisión de infra (2026-07-24): montar un **VPS en AWS EC2** como entorno
sandbox/homelab **compartido de toda la empresa**, no solo para un servicio suelto.
Es el análogo del device-mesh que André tiene en su Arch (ver
[`device-mesh.md`](../device-mesh.md)), pero para todo el equipo.

> **Estado: DECIDIDO, no implementado.** Cuenta AWS Cofoundy confirmada
> (`447580526114`, SSO session `cofoundy`, rol AdministratorAccess vía la skill
> `/aws`). El AWS CLI **no está instalado** en la caja Arch y el login es SSO por
> browser → la implementación requiere que André corra `aws sso login` (no
> automatizable headless).

## Por qué AWS EC2 (y no Cloudflare / Railway / Hetzner)

- **Cloudflare y Railway NO dan VPS** (máquina con root + Docker Compose).
  Cloudflare = Tunnel/Workers/TURN; Railway = PaaS de contenedores web, con UDP
  problemático. Ver el análisis en [`network-topology.md`](./network-topology.md).
- **Hetzner** era la opción más barata (~€7/mes CX32) y es ideal para uso personal,
  pero se descartó: **esto es infra Cofoundy** → mantenerlo en la cuenta AWS de la
  empresa (governance, billing centralizado, IAM del equipo).
- **EC2 da IP pública directa** → elimina el doble NAT de raíz (no hay routers que
  atravesar), a diferencia de self-hostear en casa.

## Propósito multi-uso (lo que vivirá ahí)

1. **WorkAdventure** — mundo social del equipo (el disparador original). Ver
   [`workadventure.md`](./workadventure.md).
2. **Sandbox de pruebas** — probar apps / levantar stacks Docker sin cargar la
   laptop propia. **Ayuda directa a Juan**, que necesita mejor equipo para levantar
   contenedores y probar aplicaciones.
3. **Overflow de CI** — self-hosted GitHub Actions runners cuando se agoten los
   minutos de CI (la Arch ya corre ~9 runners; ver `Runner.Listener` en esa caja).
4. **Agentes de Hermes** — correr agentes de forma persistente fuera de la máquina
   de André.
5. **Cloudflare** — (por definir el uso exacto: tunnels/edge para exponer lo de arriba).

## Sizing (empezar chico, escalar con uso)

Sandbox multiusuario con Docker + CI + agentes concurrentes pide RAM. Punto de
partida sugerido: **t3.large (2 vCPU / 8 GB)**; subir a t3.xlarge (16 GB) si varios
usan Docker a la vez. WorkAdventure solo necesita ~2-4 GB, pero el uso compartido es
lo que manda el sizing. Considerar **start/stop** o schedule para ahorrar cuando
nadie lo usa (EC2 cobra por hora encendida).

## Próximos pasos (cuando se priorice)

1. `aws sso login --sso-session cofoundy` (André, browser) + instalar AWS CLI en la
   caja de trabajo.
2. Elegir región (latencia Lima → `us-east-1` o `sa-east-1`), lanzar EC2, IP elástica.
3. Security groups: abrir lo que cada servicio necesite (WA: TCP 80/443 + rango UDP
   coturn; runners: solo salida; etc.).
4. Docker + docker-compose, y montar cada servicio (empezar por WorkAdventure —
   ver su doc para el detalle de dominio + TLS + TURN).
5. Documentar en `handbook/infrastructure/` (SSOT de infra Cofoundy) y dar acceso al
   equipo (Juan, etc.).

## Pendiente de contenido

André grabará **videos de YouTube** sobre estos setups (~semana del 2026-07-28). Los
temas/guiones se definen aparte; este doc es el SSOT técnico que alimenta esos guiones.
