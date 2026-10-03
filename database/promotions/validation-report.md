# Evidencia local — promotions-svc / #53

Fecha: **2026-10-03**, America/Lima. Responsable: Axel Cueva. Estado: **VALIDADO LOCALMENTE; DESPLIEGUE COMPARTIDO PENDIENTE**. Rama de entrega: `cueva`. La implementación y su evidencia se conservaron íntegramente al retirar la rama auxiliar.

## Entorno y artefacto

- PostgreSQL **17.11 (Debian 17.11-1.pgdg13+2)**, imagen `postgres:17`, contenedor desechable local sin puerto publicado.
- Schema nuevo, bootstrap común, owner `po_promotions_owner` y runtime `po_promotions_runtime` separados.
- Migraciones `0001_promotions_persistence.sql` y `0002_promotions_global_price_projection.sql`, generadas con **Supabase CLI 2.119.0** y adaptadas al historial único del runner común. La primera permanece intacta; la segunda habilita precio global/override.
- SHA-256 canónico UTF-8/LF de 0001: `ccb75886b2ff993717b46cb923e7983ab4af9038cb1db0af394f997962dac796`.
- SHA-256 canónico UTF-8/LF de 0002: `ee6c36562c81b6a65682845b01d71c2e10763374c904ea5cb88c9b069f2a5f42`.
- El catálogo posterior contiene **12 tablas del servicio + ledger**, **108 columnas**, **94 restricciones**, **31 índices** y **15 funciones**, todos bajo el schema propio. Seis FK exclusivamente internas e indexadas.
- Resultado capturado sin secretos: [validation-result.json](validation-result.json). El código asociado es la revisión de esta rama que contiene ese checksum; no sustituirlo por un hash de un commit anterior al SQL.

## Ejecución reproducible

```text
python database/promotions/tests/verify.py --container CONTENEDOR_LOCAL_VACIO --report database/promotions/validation-result.json
```

La prueba exige que `promotions` aún no exista; no borra ni reinicia un schema preexistente. Aplica bootstrap/provisión/migración con el runner real. Las carreras con commits usan otra base efímera recién creada dentro del contenedor y la eliminan al terminar; los fixtures de `validation.sql` usan ROLLBACK. El schema original termina sin datos de prueba.

## Resultados reales

**PASS: 77 assertions SQL y 29 comprobaciones de integración.**

| Grupo | Evidencia / resultado |
|---|---|
| Instalación limpia | DDL del servicio y ledger se aplican satisfactoriamente desde una base vacía. |
| Repetición | Mismo checksum, versión y applied_at; no reaplicar ni duplicar objetos. |
| Checksum adulterado | Ejecutor lo rechaza antes de aplicar el archivo alterado. |
| Migración inválida | Error SQL detiene ejecución; tabla de fixture y registro 0003 no persisten. |
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
| Regresiones de trim | Mayúsculas ASCII, espacios Unicode extremos y letra v conservada correctamente. |
| Windows UTF-8 | SQL con comentarios y literales Unicode enviado con encoding explícito; runner probado con PYTHONUTF8=0. |

Las excepciones COUPON_* citadas son diagnósticos internos de persistencia; el backend debe traducirlas a los contratos públicos existentes.

## Límites de la evidencia

No se ejecutó SQL ni deploy en Supabase. La prueba PostgreSQL no acredita configuración de Data API, RLS/advisors del proyecto, conectividad del backend, consumidor RabbitMQ ni publicación real de eventos. El schema está diseñado como privado con privilegios explícitos, sin acceso PUBLIC/anon/authenticated.

El comando de consumo no incluye subtotal/líneas: el backend sigue siendo responsable de autorizar y comprobar el snapshot comercial de Ventas antes de la transacción. AsyncAPI mantiene GenericData para eventos de las proyecciones; acordar payload/versiones con los owners. D-REC-01 y D-REC-02 permanecen abiertas y no se resolvieron artificialmente.

## Pendientes para cerrar #53

- [ ] Revisión del modelo/SQL por Leonardo Lopez y QA de Marco Castilla.
- [ ] PR de entrega asociado al issue.
- [ ] Reunir SQL de **todo el sistema**, según indicación de Axel.
- [ ] Desplegar en el proyecto Supabase autorizado y comprobar versión/schema/permisos/advisors/ledger.
- [ ] Ejecutar validation y smoke test del servicio en el proyecto objetivo; adjuntar evidencia sin secretos.

El issue permanece abierto mientras falte el despliegue y su validación compartida.
