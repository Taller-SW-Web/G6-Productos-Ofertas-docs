# Evidencia de aprovisionamiento G5 — 2026-10-15

**Entorno:** Windows administrativo hacia Oracle Cloud. **Broker:** RabbitMQ `4.2.9`, contenedor `g6-po-rabbitmq-1`. **Base usada en la provisión:** instantánea histórica AsyncAPI `0.6.0-rc.3` que permanece en el historial de PR #98, commit [`184d0be`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/blob/184d0be54cb28b8178cba920e59c544c198348e4/contratos/eventos/asyncapi-0.6.0-rc.3-g5-candidate.yaml). El contrato canónico de `master` permanece en `0.6.0-rc.2`; la instantánea histórica no es normativa vigente. **Homologación:** aceptación técnica reportada por Marco; documento externo verificable y adaptación D-02 pendientes. La provisión se hizo bajo autorización operativa explícita del owner y no se registra como homologación.

## Acceso instalado

- Vhost existente: `g6-productos-ofertas`; listener verificado en `127.0.0.1:5672`.
- RabbitMQ `g5_ventas`: creado, sin tags administrativos. ACL verificada en Oracle: `configure=^$`; `write=^po\.comandos\.x$`; `read=^po\.ventas\.q$`.
- Topic ACL única: exchange `po.comandos.x`, write regex exacta para `promotions.coupon.consumption.requested` y `promotions.coupon.restoration.requested`; topic read `^$`.
- SSH `g5_tunnel`: creado con una clave pública Ed25519 compartida; sin shell/sesiones, sudo, Docker ni autenticación por contraseña. `sshd -T` efectivo: `AllowTcpForwarding local`, `PermitOpen 127.0.0.1:5672`, stream-local/agent/X11/tunnel forwarding desactivados, `MaxSessions 0`, `ForceCommand nologin`. Grupos efectivos: únicamente `g6-rabbitmq-tunnel`.
- Mapeo Docker observado: host loopback `127.0.0.1:5672`; el cliente local usa `127.0.0.1:5673` por SSH.
- No se reinstaló RabbitMQ, no se modificó Compose, no se tocó la topología, ni se ejecutaron cambios sobre los nueve usuarios/ACL G6. No se creó usuario adicional de Postventa ni grants retry/DLX.

## Secretos y paquete

- Contraseña aleatoria de `g5_ventas` guardada en Oracle y en bóveda local DPAPI bajo el perfil Windows administrativo, protegida con ACL NTFS para la cuenta actual y SYSTEM.
- Clave Ed25519 compartida generada en la PC administrativa, protegida con passphrase. Solo la clave pública se instaló en Oracle.
- Paquete grupal `g5_equipo.g5pkg` cifrado con AES-256-GCM y contraseña aleatoria propia; contiene la clave privada protegida por passphrase, la credencial RabbitMQ, configuración, scripts de túnel/verificación y plantilla `.env`. El instalador PowerShell se entrega como archivo acompañante separado.
- Respaldo independiente `g5_equipo.admin-backup.g5enc` cifrado con AES-256-GCM y contraseña de respaldo propia. La contraseña de paquete y la de respaldo se conservan protegidas por DPAPI en la bóveda administrativa.
- Los paquetes, claves privadas, contraseñas y bóveda no forman parte de este repositorio ni se publican en GitHub. No se imprimieron secretos en la salida de los scripts.
- **Entrega no realizada:** faltan representante autorizado y canal privado. No se liberó contraseña de descifrado ni se envió material.

## Pruebas ejecutadas desde la PC administrativa

| Prueba | Resultado | Alcance |
|---|---|---|
| Login SSH por clave Ed25519 | PASS | Esta PC; abrió el túnel como `g5_tunnel` |
| TCP a `127.0.0.1:5673` | PASS | Alcanzó listener RabbitMQ mediante `127.0.0.1:5672` de Oracle |
| Shell/sesión SSH | DENEGADA | Intento remoto rechazado; `MaxSessions 0`/`nologin` verificados |
| Forwarding inverso SSH | DENEGADO | Intento `-R` rechazado |
| Agent/X11, sudo/Docker | DENEGADOS | Política efectiva y pertenencia a grupos verificadas |
| Autenticación AMQP y vhost | PASS | `g5_ventas` en `g6-productos-ofertas` |
| Lectura de `po.ventas.q` | PASS | `checkQueue` pasivo; no consume mensajes |
| Lectura cruzada `po.promociones.q` | DENEGADA | `ACCESS_REFUSED` esperado |
| Declarar cola o exchange | DENEGADO | `ACCESS_REFUSED` esperado |
| Publicar al exchange por defecto u otro exchange | DENEGADO | `ACCESS_REFUSED` esperado |
| Publicar routing key distinta en `po.comandos.x` | DENEGADO | `ACCESS_REFUSED` esperado |
| Publicar los dos comandos autorizados | PASS | Sintéticos con `messageId`/`correlationId`, TTL de 2 s, `mandatory` y publisher confirms |
| Reconexión AMQP | PASS | Reconexión incluida en smoke |
| Reconexión SSH | PASS | Túnel interrumpido y reabierto por el supervisor; listener local respondió después |
| Management `15672` por túnel | DENEGADO | No está reenviado; conexión local rechazada |
| Retry/DLX | NO EJECUTADO | Fuera de alcance; permanece bloqueado |

**Pre/postcondición de publish:** inmediatamente antes del smoke, `po.ventas.q` y `po.promociones.q` tenían cero mensajes y cero consumidores. Después de esperar expiración, ambas conservaron cero mensajes y cero consumidores. No hubo purga ni limpieza destructiva. ID del smoke: `7e737d39-bb7a-433c-887b-e8e138a54ec9`.

## Pendientes

- G5 debe documentar formalmente su aceptación de la candidata rc.3, incluidos nombres físicos, vhost, ACL, capacidad inherente de purge de su propia cola, conexión por túnel, clave/login grupales y revocación, dos comandos y exclusión actual de retry/DLX.
- Marco debe indicar representante autorizado y canal privado para distribuir paquete y contraseña por vías separadas.
- Instalar/probar el paquete desde al menos una PC G5 y validar conexión local del microservicio; el smoke desde la PC administrativa no acredita la PC G5 ni integración E2E.
- Mantener en revisión la relación entre contrato rc.2 de `master` y rc.3 candidata. La provisión runtime de las identidades no convierte rc.3 en contrato oficialmente homologado.
