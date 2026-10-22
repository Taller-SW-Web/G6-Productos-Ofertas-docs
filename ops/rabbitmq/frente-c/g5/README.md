# Acceso G5 a RabbitMQ desde Windows

## Estado al 15-10-2026

Se reutilizó el procedimiento de túnel del Frente C/Castilla. En Oracle están creados `g5_ventas` y la cuenta SSH grupal `g5_tunnel`. Se instaló una única clave pública Ed25519 compartida. La identidad RabbitMQ tiene los permisos de [`rbac-g5-ventas-rc3.json`](rbac-g5-ventas-rc3.json). La prueba desde la PC administrativa pasó; no se ha probado en una PC de G5.

Marco comunicó aceptación técnica de rc.3 y autorizó esta provisión. No se encontró un acuerdo externo verificable; por ello su estado formal sigue **pendiente de homologación**. El contrato ejecutable canónico de `master` es [`asyncapi.yaml`](../../../../contratos/eventos/asyncapi.yaml), versión `0.6.0-rc.2`. La provisión G5 del 2026-10-15 usó una instantánea histórica rc.3 conservada en el historial de PR #98 (commit [`184d0be`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/blob/184d0be54cb28b8178cba920e59c544c198348e4/contratos/eventos/asyncapi-0.6.0-rc.3-g5-candidate.yaml)); esa instantánea no es una fuente normativa vigente y D-02/adaptación G5 continúa pendiente de homologación externa. El runtime G5 aún no se integra como consumidor de negocio y no se otorgó acceso retry/DLX. Ver [compatibilidad](compatibilidad-rc3.md) y [evidencia](evidencia-aprovisionamiento-2026-10-15.md).

No se cambió Docker Compose, RabbitMQ 4.2.9 ni las nueve cuentas/ACL G6. Los servicios de Ventas/Postventa se ejecutan en las PC de G5; Oracle solo ofrece el listener loopback por el túnel.

## Matriz de acceso

| Recurso/acción | Acceso G5 |
|---|---|
| Vhost | `g6-productos-ofertas` |
| Usuario RabbitMQ | `g5_ventas`, sin tags administrativos |
| `configure` | Denegado |
| `read` | Solo `po.ventas.q` |
| `write` de recurso | Solo `po.comandos.x` |
| Topic write | `promotions.coupon.consumption.requested`; `promotions.coupon.restoration.requested` |
| Otros exchanges/colas, `amq.default`, retry/DLX, management API | Denegados |
| SSH | Login grupal `g5_tunnel`, Ed25519 compartida; forwarding local únicamente a `127.0.0.1:5672` |
| Puerto local de los microservicios | `127.0.0.1:5673` |

La matriz detallada y la aceptación pendiente están en [`matriz-acceso-g5.md`](matriz-acceso-g5.md). RabbitMQ asocia `queue.purge` al permiso de lectura: G5 puede purgar su propia cola. No existe una ACL nativa que permita leer y deniegue purge; el smoke no ejecuta purge.

## Instalación en cinco pasos

1. El representante autorizado recibe `g5_equipo.g5pkg` y `g5_equipo-installer.ps1` por un canal privado; recibe la contraseña del paquete por otro canal, después de validar su identidad.
2. Ejecuta en PowerShell 7: `pwsh -File .\g5_equipo-installer.ps1 -PackagePath .\g5_equipo.g5pkg` e ingresa la contraseña cuando se solicite.
3. Inicia el túnel con `%LOCALAPPDATA%\G6\RabbitMQ\g5_equipo\scripts\Start-G5RabbitMqTunnel.ps1`; mantiene la consola abierta mientras trabaja.
4. Copia `templates\g5_ventas.env.example` a `.env` ignorado por Git y configura `RABBITMQ_URL` usando `%LOCALAPPDATA%\G6\RabbitMQ\g5_equipo\Set-G5DeveloperRabbitMqUrl.ps1`.
5. Ejecuta `%LOCALAPPDATA%\G6\RabbitMQ\g5_equipo\Test-G5DeveloperAccess.ps1` y comprueba la conexión de su microservicio a `127.0.0.1:5673`.

El smoke completo con publicaciones autorizadas solo lo ejecuta G6 mediante `Invoke-G5RabbitMqSmoke.ps1`, que toma snapshots administrativos antes/después y se detiene si las colas no están aisladas. No se ejecutan pruebas de retry/DLX.

## Custodia y entrega

- El paquete de equipo ya está cifrado con AES-256-GCM; su contraseña y la contraseña de respaldo son independientes y están protegidas localmente con DPAPI. `Install-G5DeveloperPackage.ps1` se entrega como archivo acompañante, separado del paquete cifrado.
- La clave SSH privada tiene passphrase y permanece en el almacenamiento local de G6 y dentro del paquete cifrado. La bóveda DPAPI local está limitada por ACL NTFS a la cuenta Windows administrativa y SYSTEM.
- No distribuir por GitHub, logs, correo o chat los paquetes, passphrases, contraseña RabbitMQ ni claves privadas. Entregar el paquete y su contraseña por canales separados.
- **Entrega pendiente:** Marco debe identificar al representante autorizado de G5 y el canal privado del paquete; no se liberó contraseña ni se envió material a terceros.
- La cuenta SSH y clave son grupales. Una baja requiere eliminar/rotar la clave compartida y emitir un paquete nuevo para el equipo completo. No hay atribución individual de conexiones por clave.
- No subir un `.env` con credenciales. El archivo real se genera en la PC destino y debe permanecer ignorado por Git.

## Scripts reutilizados/adaptados

`Add-G5RabbitMqIdentity.ps1`, `Add-G5RabbitMqDeveloper.ps1`, `New-G5DeveloperKeys.ps1`, `New-G5DeveloperPackages.ps1`, `Install-G5DeveloperPackage.ps1`, `Start-G5RabbitMqTunnel.ps1`, `Test-G5RabbitMqTunnel.ps1`, `Test-G5RabbitMqTunnelReconnect.ps1`, `Test-G5DeveloperAccess.ps1`, `Invoke-G5RabbitMqSmoke.ps1` y los dos provisionadores Bash. La variante `-SharedTeamPackage` prepara un paquete grupal sin inventar destinatarios nominales; `-OwnerAuthorized` registra la autorización operativa de Marco y no cambia el estado formal de homologación.

No ejecutar los provisionadores de nuevo sobre identidades existentes: por defecto rehúsan reemplazar usuarios, claves o paquetes. La recuperación/rotación debe ser un cambio separado, coordinado y documentado.
