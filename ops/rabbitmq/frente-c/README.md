# Frente C — RabbitMQ de Oracle por túnel SSH

## Estado

**Frente C operativo desde esta PC Windows (2026-10-15).** El piloto original de Castilla sigue intacto: `C:\Users\marec\.ssh\g6_piloto`, alias `g6-dev`, local forward `127.0.0.1:5673`. Se prepararon seis cuentas SSH con claves individuales y seis paquetes cifrados para distribución; las seis cuentas y los ocho servicios RabbitMQ asignados se probaron desde esta PC. Esto no valida los equipos personales de los desarrolladores. El piloto `g6_piloto` conserva su huella `SHA256:oXYfHNfDD2Jxdx7IG0lOUaAQsCBwVxqt2ymyDfcmcMY` y no se incluyó en los paquetes.

Baseline antes de habilitar el túnel, observada por SSH el 2026-10-15:

- RabbitMQ `4.2.9-management` (`g6-po-rabbitmq-1`) está en la red Docker `g6-po_g6_backend`.
- Compose previo al patch: SHA-256 `bfa53d21ae661880bcab686e600ddb85abffdb0d4d875168f9119ee242e832fc`.
- Antes del patch `5672` no estaba publicado; `15672` ya estaba ligado a `127.0.0.1:15672`.
- El volumen nombrado `g6-po_rabbitmq_data` está montado en `/var/lib/rabbitmq`.
- Antes del cambio, esta PC no alcanzaba `157.137.205.218:5672` ni `:15672`. Después del cambio se repitió la prueba: ambos siguen sin aceptar TCP desde esta PC. Es evidencia del origen probado; no se inspeccionaron reglas OCI VCN/NSG.
- El SSH administrativo se conserva en su identidad independiente: `ssh -i "$env:USERPROFILE\.ssh\g6_oracle" -o IdentitiesOnly=yes ubuntu@157.137.205.218`. El alias del piloto se configuró con la clave separada; no se reutilizó `ubuntu` para el desarrollador.
- El `sshd` efectivo de `ubuntu` mantiene sus opciones anteriores (`AllowTcpForwarding yes`, `PermitOpen any`); las restricciones `Match Group` aplican solo a `g6-rabbitmq-tunnel`. El aprovisionador validó esa cuenta piloto con `AllowTcpForwarding local`, `PermitOpen 127.0.0.1:5672`, `MaxSessions 0` y agent/X11/reverse/túnel/shell deshabilitados.

## Aplicación y verificación del patch de Compose

El diff completo es [`compose-localhost-5672.patch`](compose-localhost-5672.patch): agrega únicamente `127.0.0.1:5672:5672` al servicio RabbitMQ y conserva `127.0.0.1:15672:15672`, el volumen, vhost, usuarios, exchanges, colas y configuración. La aprobación expresa de Marco precedió al cambio.

Antes de recrear el servicio se comprobó el backup archivado del volumen `g6-po_rabbitmq_data` (`rabbitmq-volume-20261013T084017Z.tar.gz`, SHA-256 `eb9a1ab098d61cf383210d639b03acd0e122e9bcf5ad26cb8f02968336ac831f`) y se generó una exportación fresca de definiciones con las ACL de Front B. La exportación se conservó fuera del repositorio con `root:root`, modo `0600`, SHA-256 `9d45487a796d53f198ccbbe7be0edad280da7c27f79416a585f5a3fa8efdab0a`. El backup de volumen es del 2026-10-13, anterior a Front A/B; se preservó intacto, pero no representa un snapshot actualizado de los mensajes/estado previos a esta recreación. No se detuvo el broker para crear una copia fría adicional.

El backup del Compose anterior quedó en `/opt/g6-productos-ofertas/backups/compose-frente-c-before-20261015.yaml`, `root:root`, modo `0600`; SHA-256 `bfa53d21ae661880bcab686e600ddb85abffdb0d4d875168f9119ee242e832fc`. Antes de reiniciar, se verificó byte por byte que al remover la única línea nueva el Compose coincidía con ese backup. `docker compose config --quiet` pasó. Se ejecutó exclusivamente `docker compose -f /opt/g6-productos-ofertas/compose.yaml up -d rabbitmq`; no se usó `down`, no se eliminó volumen y no se alteró la identidad del nodo.

Verificación posterior: contenedor `g6-po-rabbitmq-1` saludable (ID `ed7913c0be40a8b9aadf57ffc45c35c34715ea5a6e0066a11f6b3a983d03903c`), imagen `rabbitmq:4.2.9-management`, nodo `rabbit@g6-rabbitmq` y volumen `g6-po_rabbitmq_data:/var/lib/rabbitmq` conservados. El Compose aplicado tiene SHA-256 `b1b6e8bebd54534d726f311fccf1b461c73bf1fdfdeae9238598dd24cacad5fe`. Los vhosts `g6-productos-ofertas` y `g6`, las 11 identidades y las ACL se mantienen; en el vhost nuevo se contaron 9 permisos de recurso y 12 de tópico. Se observaron los cuatro exchanges de negocio/topología y las 11 colas durables; al cierre todas estaban vacías y sin consumidores. `rabbitmq-diagnostics check_running` y `check_local_alarms` pasaron. El host escucha `5672` y `15672` exclusivamente en `127.0.0.1`; la prueba de TCP desde esta PC Windows a la IP pública devolvió `False` en ambos puertos. Esa comprobación acredita solo el origen probado; no se inspeccionaron reglas OCI VCN/NSG ni se declara una auditoría desde otros orígenes.

El harness autenticado posterior a la recreación terminó con run ID `d6a77d56-3498-4a5f-ab60-98eef4b2fab4`: autenticación, consumo de cola propia, lectura cruzada denegada, `configure`/declaración denegado, publicación no autorizada denegada y reconexión pasaron en las nueve identidades. Publicación autorizada, publisher confirm y limpieza sintética pasaron para seis publishers. Para `g6_auditoria_precios`, `g6_combos` y `g6_pasarela`, esos dos casos se registraron `NO_APLICA`; las publicaciones negativas sí se probaron. El caso `mandatory` con alternate exchange también pasó. El harness removió el operador y el contenedor temporales.

## Cuentas SSH de desarrolladores

`provision-dev-tunnel-user.sh` acepta una cuenta individual `g6_<login>` y una clave pública `ssh-ed25519` por stdin. `Add-G6RabbitMqDeveloper.ps1` transfiere el aprovisionador y la clave pública desde Windows; está limitado a los seis logins aprobados y no copia ninguna clave privada. Instala una política de grupo que permite exclusivamente forwarding local a `127.0.0.1:5672`, deshabilita sesiones/TTY, contraseñas, agent forwarding, X11, forwarding Unix y túneles, valida `sshd -t` y la política efectiva antes de recargar SSH. Crea una cuenta sin grupos `sudo`, `docker` o `lxd`, con shell `nologin`, clave `authorized_keys` restringida (`restrict`, `port-forwarding`, `permitopen`). Rechaza reemplazar una cuenta existente. Para el segundo key Castilla, `Add-G6RabbitMqDeveloperKey.ps1` verifica la cuenta y anexa la clave sin reemplazar las entradas previas. La política no cambia la cuenta ni sesiones administrativas existentes.

Una cuenta/clave distinta por persona permite retirar ese acceso sin compartir el usuario `ubuntu`. El acceso RabbitMQ es una capa separada: cada paquete incluye únicamente las credenciales de los servicios asignados, dentro de su contenedor autenticado AES-256-GCM. La cuenta SSH no sustituye las ACL RabbitMQ; revocar una clave SSH tampoco rota una contraseña RabbitMQ ya conocida por su destinatario.

### Incorporar a cada integrante

1. El administrador envía un solo archivo autoinstalable `<g6_login>-installer.ps1`, que contiene el payload `.g6pkg` cifrado, y comunica su contraseña individual por un canal separado. No envía los paquetes a terceros automáticamente.
2. En PowerShell 7, ejecutar `pwsh.exe -ExecutionPolicy Bypass -File .\g6_<login>-installer.ps1` y escribir la contraseña en el prompt seguro. El instalador incluye el bootstrap y el paquete AES-GCM autenticado; instala la clave passphrase-protected, alias `g6-dev`, scripts, plantillas y credenciales locales DPAPI.
3. Ejecutar `Test-G6DeveloperAccess.ps1` (smoke de un comando) desde la ruta que imprime el instalador. Después usar `Start-G6RabbitMqTunnel.ps1` para NestJS.
4. Para cada servicio asignado, ejecutar `Set-G6DeveloperRabbitMqUrl.ps1 -Identity <g6_servicio> -Path <ruta-del-servicio>\.env`. Escribe solo `RABBITMQ_URL`, no muestra el valor y exige que el `.env` esté ignorado por Git.
5. El integrante confirma al administrador que el smoke pasó desde su PC. Registrar la entrega y confirmación con `Set-G6DeveloperDeliveryStatus.ps1`.
6. No enviar secretos por Git, chat ni argumentos de comandos. Nunca copiar `g6_oracle`, `ubuntu` ni una clave administrativa.

Las seis cuentas ya están preparadas usando claves centralizadas por autorización expresa posterior. Las pruebas de esta sección acreditan solamente la PC de Marco. No declarar que las seis PC personales tienen conectividad antes de que cada integrante ejecute y confirme su smoke.

Asignación aprobada por Marco:

| Desarrollador | Login SSH | Identidades RabbitMQ autorizadas |
|---|---|---|
| Castilla | `g6_castilla` | `g6_masivos`, `g6_combos` |
| Poma | `g6_poma` | `g6_catalogo` |
| Taco | `g6_taco` | `g6_inventario` |
| Vera | `g6_vera` | `g6_precios`, `g6_auditoria_precios` |
| Cueva | `g6_cueva` | `g6_promociones` |
| López | `g6_lopez` | `g6_taxonomia` |

`g6_pasarela` permanece bajo custodia administrativa de Marco, sin una séptima cuenta SSH. Una cuenta de desarrollador puede servir para varios microservicios asignados, pero cada proceso usa únicamente su propia identidad RabbitMQ.

## Windows: piloto

Cada paquete contiene su clave individual protegida con passphrase. El archivo autoinstalable `<g6_login>-installer.ps1` es un único artefacto para enviar: incluye el bootstrap común y el payload `.g6pkg` AES-256-GCM autenticado en Base64. El contenido descifrado incluye también una copia del instalador PowerShell, scripts, alias SSH, plantillas `.env` por servicio, instrucciones e identidades RabbitMQ asignadas. La passphrase de cada clave y contraseña del paquete son la misma cadena aleatoria individual, que se comunica fuera de banda. El script autoinstalable contiene solo código de bootstrap y datos cifrados; la clave privada nunca se copia a Oracle ni al repositorio.

Para abrir el túnel directamente, usar el comando requerido:

```powershell
ssh -N -o ExitOnForwardFailure=yes -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -L 127.0.0.1:5673:127.0.0.1:5672 g6-dev
```

Los paquetes asignan puertos locales `5673` a `5678` respectivamente para no colisionar si se necesitan varios. `Start-G6RabbitMqTunnel.ps1`, incluido en cada paquete, comprueba que el puerto asignado esté libre, mantiene el proceso foreground y reintenta si pierde conexión. `Test-G6RabbitMqTunnel.ps1` verifica TCP local. `Test-G6DeveloperAccess.ps1` abre y cierra el túnel, y valida autenticación AMQP, cola propia, lectura cruzada y escrituras no autorizadas con secretos DPAPI; evita publicaciones autorizadas para no inyectar mensajes durante el smoke del desarrollador. Las pruebas de publicación autorizada se hicieron por separado desde la PC administrativa con TTL de 2 segundos.

El servicio NestJS local debe apuntar solo a `127.0.0.1:5673`. La plantilla específica del microservicio está en `templates/`. No guardar el `.env` completado en Git.

## Piloto Windows ejecutado, separado de E2E

El piloto autorizado es Castilla (`g6_castilla`, identidad `g6_masivos`, vhost `g6-productos-ofertas`, puerto local `5673`). El verificador `Invoke-G6RabbitMqPilotSmoke.ps1` recuperó solo `g6_masivos` de DPAPI en memoria, exigió túnel TCP local y confirmó administrativamente que `po.masivos.q` y `po.catalogo.q` estaban vacías y sin consumidores antes del smoke. El mensaje autorizado tuvo TTL de 2 segundos; no se purgaron colas. La prueba posterior volvió a confirmar ambas vacías. La dependencia `amqplib` se instaló en un directorio temporal y se eliminó al finalizar.

Run ID AMQP `2d2373de-62de-4281-bd19-cc3a289418e2`: autenticación, lectura de cola propia, lectura cruzada denegada, configure denegado, publicaciones no autorizadas denegadas, publicación autorizada, publisher confirm y reconexión AMQP pasaron. El destino sintético fue `po.catalogo.q`; pre y post snapshots reportaron cero mensajes y cero consumidores en `po.masivos.q` y `po.catalogo.q`.

Hashes de artefactos usados: `verify-pilot-amqp.mjs` SHA-256 `DFCFC5FE22851468BDC33914C9BF5AC59FF031ACD1C92EF9C99A767D5DE59933`; manifiesto `rbac-rc3.json` SHA-256 `A33593038AC2899F1F9C7B149A7A188053104CC76DCDC26967AB4998A0536390`; wrapper de piloto `Invoke-G6RabbitMqPilotSmoke.ps1` SHA-256 `86A7D57F3FADFDF16CAA62ABBF780B69CBE205E451A4E27CF046322C0BD279B0`.

Pruebas SSH desde esta PC: autenticación por clave PASS; password/keyboard-interactive denegado PASS; shell/sesión denegada PASS; reenvío inverso denegado PASS; destino no permitido `127.0.0.1:22` denegado por `administratively prohibited` PASS. `sshd -T` efectivo y `authorized_keys restrict` verifican agent forwarding/X11/TTY/túnel/Unix forwarding deshabilitados. `Test-G6RabbitMqTunnel.ps1` verificó TCP local. `Test-G6RabbitMqTunnelReconnect.ps1` interrumpió el proceso SSH del túnel y observó recuperación automática del listener (PID `35424` → `33788`) y TCP local PASS. Después, el listener local quedó cerrado. Las pruebas TCP desde esta PC a `157.137.205.218:5672` y `:15672` dieron `False`; el host enlaza AMQP y management solo a `127.0.0.1`.

1. El piloto se ejecutó desde la PC Windows de Marco y verificó únicamente Castilla / `g6_castilla` / `g6_masivos`.
2. Para Poma, Taco, Vera, Cueva y López, generar una clave en la PC de cada persona, registrar únicamente la pública, aprovisionar mediante `Add-G6RabbitMqDeveloper.ps1` y repetir pruebas individuales desde esa PC.
3. Este smoke prueba transporte, credenciales y ACL del broker; no prueba handlers ni E2E NestJS.

El harness Front B `../verify-amqp.js` se ejecutó desde una red Docker autorizada. El presente run `2d2373de-62de-4281-bd19-cc3a289418e2` añade evidencia de una sola PC Windows y no se extrapola a las otras cinco.

## Inventory y estado de integración

AsyncAPI `0.6.0-rc.3` sigue candidata interna y G5 no está homologado. `inventory-svc` usa actualmente `po.events.x`/`po.results.x`, incompatibles con los nombres físicos `po.eventos.x`/`po.resultados.x`; no se ampliarán permisos para compensarlo. Los otros servicios no productivos de RabbitMQ continúan pendientes de integración de código. `g6_auditoria_precios`, `g6_combos` y `g6_pasarela` se mantienen consumer-only; no inventar productores.

Retry/DLX permanece bloqueado por `RECUPERACION_DLQ_SATURADA_NO_VERIFICADA`. Este túnel solo habilita conectividad a 5672 y no elimina esa dependencia funcional.

## Distribución, revocación y rotación

- La custodia actual DPAPI local no es un secret manager multiusuario. Se validaron sin revelar sus valores las nueve entradas: todas se descifraron para el usuario Windows y coinciden con el vhost/manifiesto rc.3. `Get-G6RabbitMqCredential.ps1 -Identity <g6_identity>` consulta una credencial y la copia al clipboard local sin mostrarla; pegar únicamente en un secret store local aprobado y limpiar el clipboard. Para automatizar el smoke, `Invoke-G6RabbitMqPilotSmoke.ps1` descifra `g6_masivos` en memoria sin mostrarlo.
- El nuevo almacén local de onboarding es `%LOCALAPPDATA%\G6\RabbitMQ\onboarding\admin-vault.dpapi.json`, cifrado con DPAPI para la cuenta Windows actual y con DACL NTFS restringida. Guarda solamente las contraseñas de paquetes/passphrases bajo DPAPI, fingerprints, rutas y estados de entrega. Las claves privadas de etapa están en `keys\` como claves OpenSSH cifradas por passphrase; cada archivo tiene ACL NTFS para la cuenta local y SYSTEM. La configuración EFS de carpeta no está disponible en este entorno (`cipher /E` devuelve “Solicitud no compatible”); por eso el cifrado de cada clave OpenSSH y AES-GCM de los paquetes es el cifrado efectivo en reposo. No se verificó BitLocker.
- `New-G6DeveloperKeys.ps1` es idempotente: conserva los seis pares existentes y no toca `C:\Users\marec\.ssh\g6_piloto`. El secreto de cada clave es aleatorio, único y guardado por DPAPI; no aparece en argumentos ni logs. Para paquetes, la misma cadena aleatoria es la contraseña AES-GCM del paquete y la passphrase de la clave privada que contiene. Cada contenedor `.g6pkg` usa AES-256-GCM autenticado, KDF PBKDF2-HMAC-SHA256 con 600 000 iteraciones, nonce/ salt aleatorios y etiqueta de autenticación. Los ZIP internos se crean y cifran en memoria; no se escriben como archivos sin cifrar.
- Los seis instaladores `<g6_login>-installer.ps1` y payloads `<g6_login>.g6pkg` están en `%LOCALAPPDATA%\G6\RabbitMQ\onboarding\packages\`. El payload cifrado contiene clave privada y pública, alias `g6-dev`, scripts PowerShell, smoke AMQP, manifiesto rc.3, plantillas `.env` por servicio, instrucciones e identidades RabbitMQ asignadas. Las contraseñas RabbitMQ existen en el contenido interno solo hasta que el instalador las convierte a DPAPI local en la PC destinataria; fuera del proceso permanecen cifradas en el payload. Los paquetes no incluyen `g6_pasarela`.
- `Get-G6DeveloperPackagePassword.ps1 -Login <g6_login>` copia una sola contraseña al clipboard local sin mostrarla. Pegar solo en el canal privado separado y limpiar el clipboard. El password permanece protegido por DPAPI en el equipo administrativo.
- No existe un gestor multiusuario conectado y no se enviaron paquetes, contraseñas ni credenciales a terceros. Para entregar, enviar el archivo autoinstalable `<g6_login>-installer.ps1` por un medio privado y transmitir su contraseña por un canal separado. El instalador incluye el payload `.g6pkg` autenticado y el bootstrap. Tras observar la entrega y confirmación del smoke, actualizar el estado con `Set-G6DeveloperDeliveryStatus.ps1`. El inventario local lo imprime `Get-G6OnboardingInventory.ps1`.
- Para revocar a un desarrollador, quitar su clave `authorized_keys` (o retirar su cuenta del grupo permitido), verificar rechazo y cerrar su conexión/túneles. No borrar datos RabbitMQ.
- Si el destinatario conoció la contraseña de una identidad de servicio, coordinar la rotación de esa identidad con todos los consumidores autorizados: actualizar el secret store aprobado, cambiar contraseña mediante stdin, reconectar y probar ACL; revocar el secreto anterior. Una clave SSH revocada no invalida un secreto RabbitMQ que se haya copiado.
- Para rotación de clave SSH, instalar y validar la nueva clave primero, comprobar el túnel permitido, luego retirar la clave antigua y registrar huellas/fecha sin guardar la privada.

## Incorporación centralizada y evidencias 2026-10-15

Se registraron seis claves Ed25519 independientes. Castilla recibió una segunda clave pública por anexado; su clave piloto original y su acceso `g6_piloto` se conservaron. Todas las claves privadas nuevas siguen protegidas por passphrase en el directorio local restringido, fuera del repositorio; sus passphrases aleatorias son distintas. Las fingerprints públicas se mantienen en el inventario DPAPI, no se guardan claves privadas en Git.

`Test-G6OnboardingSsh.ps1` pasó para los seis logins: autenticación pública individual, túnel positivo a `127.0.0.1:5672` y rechazo a `127.0.0.1:22`. Se verificó además el rechazo de canales de shell/sesión y forwarding inverso en los seis logins; `sshd -t`, `sshd -T`, `authorized_keys`, grupo y `nologin` se comprobaron durante aprovisionamiento. Las cuentas existentes de desarrolladores no incluyen `sudo`, Docker ni otros grupos administrativos. La cuenta `ubuntu` se mantuvo utilizable.

`Test-G6OnboardingAmqp.ps1` probó desde esta PC las ocho identidades de servicio asignadas a las seis personas: autenticación, lectura de cola propia, lectura cruzada denegada, configure denegado y publicaciones negativas denegadas. Publicación autorizada con publisher confirm pasó para `g6_masivos`, `g6_catalogo`, `g6_inventario`, `g6_precios`, `g6_promociones` y `g6_taxonomia`; `g6_combos` y `g6_auditoria_precios` quedaron `NO_APLICA`. Cada publicación sintética usó TTL 2 s. Se validaron colas destino vacías y sin consumidores antes y después; no se purgaron colas. Run IDs por identidad: masivos `2f2d6421-7687-4d72-bb51-3085b7d7e5c4`, combos `4ef84b1a-0508-4901-910f-a3b978ae6ae5`, catálogo `2a4e5b7c-42e5-4854-9154-55b9edf5bf2b`, inventario `e5bf7327-80d5-4737-8a93-905c6ea026c3`, precios `bb1a52ed-db1a-45de-b1d6-afb9fd22307d`, auditoría `362a049a-38de-4179-b55b-4d129e2ad209`, promociones `b02671a2-944e-4cff-a69b-618c5ebc10c6`, taxonomía `a6fee5f7-24b4-4170-8d4a-ff15c04e53a0`. El smoke local del instalador Poma también pasó desde este PC con run ID `711209b1-3d73-4f76-9a77-35e23f74c87e`; valida autenticación, lectura y ACL, y omite publicación autorizada.

Los seis paquetes AES-256-GCM se abrieron mediante una prueba aislada del instalador. Se verificó autenticidad, pareja pública/privada y passphrase de cada clave; todos los secretos asignados quedaron en DPAPI local de prueba, y las plantillas y scripts se instalaron correctamente. `Set-G6DeveloperRabbitMqUrl.ps1` generó archivos `.env` temporales en un directorio de prueba no versionado sin imprimir valores secretos. Esta prueba no cuenta como entrega ni como prueba en PCs personales.

| Desarrollador | Clave pública registrada | Túnel desde esta PC | Instalador / payload | SHA-256 del instalador | Entregado | PC personal confirmada |
|---|---|---|---|---|---|---|
| Castilla | Sí; añadida sin reemplazar clave piloto | Sí | `packages/g6_castilla-installer.ps1` / `g6_castilla.g6pkg` | `8E7FE3437C15A2579BDD86B440D2D8D8E4FEFB730C58188FDD3B5B2F6550C629` | No | No |
| Poma | Sí | Sí | `packages/g6_poma-installer.ps1` / `g6_poma.g6pkg` | `A7111F4A3A7162877A5112E39DAFF6A3C8353DFEFA51F7539517867F763F9140` | No | No |
| Taco | Sí | Sí | `packages/g6_taco-installer.ps1` / `g6_taco.g6pkg` | `13756831F0F17D08394301D42110A097079F3485F70A4B30ACC98700A9E9D80F` | No | No |
| Vera | Sí | Sí | `packages/g6_vera-installer.ps1` / `g6_vera.g6pkg` | `4E5975731D3B2D64EBE39651E91CD3445056A9B79F109BB4073B4EF16DDB0EAC` | No | No |
| Cueva | Sí | Sí | `packages/g6_cueva-installer.ps1` / `g6_cueva.g6pkg` | `45C035E83B03B59FFEC75EF0A72E37790DAA2D074A232AA278521BA00273F1C2` | No | No |
| López | Sí | Sí | `packages/g6_lopez-installer.ps1` / `g6_lopez.g6pkg` | `BF8470E9EF5A65A883F276DB7CA59D7DD0F8991FBD1DC106584D96A12D3CA760` | No | No |

El instalador requiere PowerShell 7, OpenSSH cliente, Node.js/npm y acceso a npm para el smoke AMQP. Cada integrante sigue pendiente de recibir su instalador y contraseña, ejecutar el smoke en su propia PC y comunicar el resultado. No se modificaron Docker Compose, RabbitMQ, identidades ni permisos para hacer el onboarding.

## Pendientes / bloqueos

| Trabajo | Estado | Criterio de cierre |
|---|---|---|
| Publicar AMQP solo en loopback | COMPLETADO; evidencia anterior | Diff exacto; servicio recreado; health/topología/ACL/volumen y prueba AMQP validados; loopback y puertos públicos negativos desde esta PC |
| Crear/provisionar seis cuentas SSH | COMPLETADO; Castilla conserva la clave piloto y tiene una clave adicional | `sshd -t/-T`, autenticación, forward exacto, destino y canales de sesión denegados desde esta PC |
| Probar seis logins desde esta PC | COMPLETADO | No representa verificación de las PCs de los integrantes |
| Probar ocho identidades RabbitMQ asignadas | COMPLETADO desde esta PC; publicación consumer-only `NO_APLICA` | Pruebas AMQP de auth/lectura/ACL; productores con publicación sintética TTL+confirm |
| Crear seis paquetes cifrados | COMPLETADO; seis AES-256-GCM autenticados | Instalador aislado, fingerprints, credenciales DPAPI y plantillas validadas |
| Entregar paquete/contraseña | PENDIENTE; no se envió nada | Marco entrega paquete y bootstrap por medio privado, password por canal separado |
| Validar PCs personales | PENDIENTE para las seis personas | Cada desarrollador ejecuta `Test-G6DeveloperAccess.ps1` y confirma; actualizar inventario |
| Inventory rc.3 | Incompatible en código | Owner adapta exchanges y prueba frontend, sin elevar ACL |
| Retry/DLX | `BLOQUEADO_ESPECÍFICO` | Resolver el gate de recuperación y versionar/homologar cambios si aplican |

Referencias para las restricciones SSH: [sshd_config(5)](https://man.openbsd.org/sshd_config.5) y [sshd(8), authorized_keys](https://man.openbsd.org/sshd.8).

## Incorporación G5 (acceso implementado; homologación formal pendiente)

El kit separado de Ventas/Postventa se encuentra en [`g5/README.md`](g5/README.md). El 2026-10-15 se aprovisionaron `g5_ventas` y la cuenta SSH grupal `g5_tunnel` usando la candidata rc.3, bajo autorización operativa de Marco. El smoke desde la PC administrativa pasó; la aceptación técnica fue reportada, pero no hay evidencia externa verificable y no se declara homologación formal. El paquete cifrado está preparado y la entrega está pendiente de representante/canal. La prueba de Frente C/Castilla permanece como evidencia distinta y no se atribuye a PCs G5. No se modificó la allowlist G6 ni los nueve usuarios/ACL G6.