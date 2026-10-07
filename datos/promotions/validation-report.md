# Evidencia local — promotions-svc / #53

Fecha: **2026-10-03**, America/Lima. Responsable: Axel Cueva. Estado: **VALIDADO LOCALMENTE; DESPLIEGUE COMPARTIDO PENDIENTE**. Rama de entrega: `cueva`. La implementación y su evidencia se conservaron íntegramente al retirar la rama auxiliar.

## Entorno y artefacto

- PostgreSQL **17.11 (Debian 17.11-1.pgdg13+2)**, imagen `postgres:17`, contenedor desechable local sin puerto publicado.
- Schema nuevo, bootstrap común, owner `po_promotions_owner` y runtime `po_promotions_runtime` separados.
- Migraciones `0001_promotions_persistence.sql`, `0002_promotions_global_price_projection.sql` y `0003_promotions_timestamps_and_delete_rules.sql`. Las dos primeras conservan su historia/checksums; 0003 incorpora la revisión mediante SQL versionado compatible con el runner común. La generación inicial utilizó Supabase CLI 2.119.0; no se atribuye esa generación a la nueva migración manual.
- SHA-256 canónico UTF-8/LF de 0001: `ccb75886b2ff993717b46cb923e7983ab4af9038cb1db0af394f997962dac796`.
- SHA-256 canónico UTF-8/LF de 0002: `ee6c36562c81b6a65682845b01d71c2e10763374c904ea5cb88c9b069f2a5f42`.
- SHA-256 canónico UTF-8/LF de 0003: `2e3eaf61ffc96b02d6e6bd25c76dcaded3b9a0c6698e306914811c6c912b0eaa`.
- El catálogo posterior contiene **12 tablas del servicio + ledger**, **116 columnas**, **94 restricciones**, **31 índices**, **15 funciones** y **26 triggers de usuario**, todos bajo el schema propio. Seis FK exclusivamente internas e indexadas, con `ON DELETE RESTRICT`.
- Resultado capturado sin secretos: [validation-result.json](validation-result.json). El código asociado es la revisión de esta rama que contiene ese checksum; no sustituirlo por un hash de un commit anterior al SQL.

## Ejecución reproducible

```text
python bd/promotions/tests/verify.py --container CONTENEDOR_LOCAL_VACIO --report bd/promotions/validation-result.json
```

La prueba exige que `promotions` aún no exista; no borra ni reinicia un schema preexistente. Aplica bootstrap/provisión/migración con el runner real. Las carreras con commits usan otra base efímera recién creada dentro del contenedor y la eliminan al terminar; los fixtures de `validation.sql` usan ROLLBACK. El schema original termina sin datos de prueba.

## Resultados reales

**PASS: 122 assertions SQL y 47 comprobaciones de integración.** Ejecución final en el contenedor desechable `po-promotions-review-final-20261003`, sin puertos publicados ni conexión al proyecto Supabase.

| Grupo | Evidencia / resultado |
|---|---|
| Instalación limpia | DDL del servicio y ledger se aplican satisfactoriamente desde una base vacía. |
| Repetición | Mismo checksum, versión y applied_at; no reaplicar ni duplicar objetos. |
| Checksum adulterado | Ejecutor lo rechaza antes de aplicar el archivo alterado. |
| Migración inválida | Error SQL detiene ejecución; tabla de fixture y registro 0004 no persisten. |
| Timestamps obligatorios | Cada tabla del servicio posee created_at timestamptz NOT NULL DEFAULT now(); diez tablas tienen updated_at y BEFORE UPDATE habilitado; inbox/outbox conservan la exención autorizada. |
| FK y retención | Seis FK RESTRICT explícitas e indexadas; borrar promoción/regla/cupón con dependencias falla; no hay cascada que elimine consumos. |
| Protección de fechas | Actualizar scope sustituye un timestamp enviado por el reloj técnico y conserva creación; restitución conserva created_at e identidad; editar creación del uso se rechaza. |
| Validador ante regresiones | Ocho mutaciones aisladas: columna ausente, nullable, timestamp sin zona, default/trigger ausente, FK implícita, customer_ref text y renombre fuera del inventario. Todas fallan con la assertion esperada y se revierten. |
| Upgrade de 0001 a 0003 con datos | Filas sembradas en las siete tablas afectadas conservan todos sus campos previos; se completan timestamps a partir de datos existentes, precio recibe ID y consumos mantienen UUID/política/fecha de restitución. |
| Precio global / override | Coexisten global NULL y RETAIL para un SKU; se rechazan segundo global y segundo override del mismo canal. Upgrade conserva snapshot anterior y asigna ID técnico. |
| Configuración comercial | Código normalizado/único, límites, monto mínimo, fechas, canales, XOR/duplicados, alcance/política obligatorios. |
| Modalidad | Cambio inicial válido, primera activación persistente después de desactivar, transición histórica bloqueada. |
| Recomendaciones | No autorrecomendación/duplicados, criterio UPSELL incluso al cambiar tipo, candidatos obligatorios, orden positivo. |
| Consumo | Vigencia/canal/identidad/cuota; mismo pedido/cupón devuelve mismo ID, identidad diferente es conflicto. |
| Restitución | RESTORED una vez, fecha histórica conservada; NO_RESTAURAR mantiene consumo, NO_CONSUMPTION no libera cupos inexistentes. |
| Historia | Prohibición de borrar/cambiar pedido y restitución incompatible. Edición posterior del cupón no modifica política capturada. |
| Proyecciones | Antiguas ignoradas, misma versión/timestamp ambiguos rechazados, ID de mensaje con otro contenido rechazado. |
| Inbox/outbox | Deduplicación, envelope/resultado inmutables, envelope mínimo validado, rollback conjunto con negocio. |
| Concurrencia global | Dos pedidos por último cupo: exactamente uno termina; otro COUPON_GLOBAL_LIMIT; una fila. |
| Concurrencia cliente | Dos pedidos del mismo cliente por último cupo: exactamente uno termina; otro COUPON_CUSTOMER_LIMIT; una fila. |
| Reentrega concurrente | Ambas solicitudes idénticas responden con el mismo ID; un solo uso persistido. |
| Permisos runtime reales | Puede guardar agregado/consumir/restituir/deduplicar; no puede DDL, otro schema, ledger, borrar historia ni editar identidad/envelope. |
| Regresiones de precisión | 100.001 no se redondea a 100; mínimo 0.001 conservado; Infinity/NaN rechazados. |
| Límites de Hito 2 | Solo las doce tablas del contexto y ledger; montos propios sin escala rígida; snapshots conservan PEN/USD y precisión sin imponer moneda única ni conversión. |
| Regresiones de trim | Mayúsculas ASCII, espacios Unicode extremos y letra v conservada correctamente. |
| Windows UTF-8 | SQL con comentarios y literales Unicode enviado con encoding explícito; runner probado con PYTHONUTF8=0. |

Las excepciones COUPON_* citadas son diagnósticos internos de persistencia; el backend debe traducirlas a los contratos públicos existentes.

## Límites de la evidencia

No se ejecutó SQL ni deploy en Supabase. La prueba PostgreSQL no acredita configuración de Data API, RLS/advisors del proyecto, conectividad del backend, consumidor RabbitMQ ni publicación real de eventos. El schema está diseñado como privado con privilegios explícitos, sin acceso PUBLIC/anon/authenticated.

El comando de consumo no incluye subtotal/líneas: el backend sigue siendo responsable de autorizar y comprobar el snapshot comercial de Ventas antes de la transacción. AsyncAPI mantiene GenericData para eventos de las proyecciones; acordar payload/versiones con los owners. D-REC-01 y D-REC-02 permanecen abiertas y no se resolvieron artificialmente.

La revisión incorporó 0003 y amplió validation.sql/verify.py sin editar 0001/0002. Se comprueba la ejecución desde cero, upgrade con registros anteriores y restauración de triggers después del backfill. El backfill utiliza timestamps disponibles como aproximación técnica: no acredita conocer la creación histórica que no se almacenó. Nuevas filas usan DEFAULT now(); actualizaciones mutables usan el reloj técnico del trigger.

No hay tablas/campos fiscales, de costo de envío, Pickup, fulfillment, pedidos/pagos o reservas. La restitución corresponde a cancelación del pedido; no resuelve devoluciones/reembolsos ni reparto de descuentos. Los snapshots monetarios son fixtures, no un nuevo contrato de Pricing. Los nombres plurales se conservan por la excepción vigente de Arquitectura; customer_ref permanece UUID. La adaptación del modelo físico sigue las 28 secciones de la plantilla vigente.

La validación acredita las correcciones y reglas locales examinadas, no cumplimiento automático de toda convención transversal. El ledger compartido, las claves/estructura heredadas de proyecciones/mensajes, CHECK frente a ENUM y las discrepancias de exposición/roles permanecen sujetos al dictamen BD/QA en physical-model §23; no se afirman excepciones aprobadas ni se modifica el runner de otros schemas.

## Pendientes para cerrar #53

- [ ] Revisión del modelo/SQL por Leonardo Lopez y QA de Marco Castilla.
- [ ] PR de entrega asociado al issue.
- [ ] Reunir SQL de **todo el sistema**, según indicación de Axel.
- [ ] Desplegar en el proyecto Supabase autorizado y comprobar versión/schema/permisos/advisors/ledger.
- [ ] Ejecutar validation y smoke test del servicio en el proyecto objetivo; adjuntar evidencia sin secretos.

El issue permanece abierto mientras falte el despliegue y su validación compartida.
