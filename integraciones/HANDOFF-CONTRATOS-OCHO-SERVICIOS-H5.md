# Handoff contractual H5 — ocho servicios

Los contratos de este PR están `APPROVED_G6` dentro de G6 por el acta del 22/11/2026. `SEMIFINAL_G6` describe su baseline técnica, no una aprobación jerárquica pendiente. La aprobación o merge documental no implementa, habilita, homologa ni despliega rutas o mensajes.

| Owner | Siguiente trabajo luego del merge Docs | Gateway / G7 / externo pendiente |
|---|---|---|
| Castilla — Bulk | Implementar R02 solo tras SKU inicializado, ubicación autoritativa y stock inicial > 0; mantener importador de precio fuera de Bulk v2; retener bytes/hash/content-length conforme claim-check. | No exponer claim-check; G7 debe confirmar identidad técnica privada Catalog. |
| Poma — Catalog | Implementar `POST /interno/productos/skus/filtrar` con cursor estable, solo SKU vendibles y prueba de paginación. | Registrar scope/client allowlist privada de Inventory en G7; no publicar por APIM. |
| Castilla — Combos | Confirmar compatibilidad de operaciones actuales y consumidores, sin duplicar endpoints. | Sin permisos nuevos definidos. |
| Cueva — Promotions | Implementar consulta interna de evidencia de reserva antes de evaluar el consumo H5; GET no muta. | G7 debe autorizar únicamente `promotions-svc`; homologación G5 de cupón y evidencia comercial siguen pendientes. |
| López — Taxonomy | Mantener las operaciones y semántica 202/consulta de estado; validar errores terminales. | No se solicitan grants nuevos desde este PR. |
| Vera — Pricing | Mantener importador HTTP de #233 como vía de cargas; no activar R03/R14 para Bulk v2. | Confirmar grants/importación con G7 según PR existente. |
| Vera — Price Audit | Preservar append-only y consumidor idempotente; piloto no equivale a habilitación global. | Verificar acceso por identidad técnica y despliegue en ambiente objetivo. |
| Taco — Inventory | Implementar endpoints HTTP de alertas/ubicaciones con contrato, reparar semántica de NULL, paginación/flag; ajustar R02 Inbox, atomicidad stock/Kardex/Outbox y resultados durables. | Solicitar grants humanos para nuevas lecturas y grant M2M solo a Promotions. Mantener Reserva H5 externa limitada a `modulo-ventas`. |
| Axel — Azure H5 | Revisar envelope, entrega estable, Inbox/Outbox y relay/receiver para R02 después de que handlers y contrato estén acordados. | No crear cola/receiver hasta aprobación de integración y recursos autorizados; Basic no tiene topics. |

## Solicitudes G7 pendientes

| Operación | Owner que solicita | Identidad y permiso candidato | Estado / desbloqueo |
|---|---|---|---|
| Filtrar SKU vendibles | Inventory → Catalog | client `inventory-svc`; scope candidato a registrar según política G7 | `PENDIENTE_G7`; G7 registra la identidad técnica y aprueba la allowlist interna. |
| Evidencia de reserva para cupón | Promotions → Inventory | `promotions-svc`, `inventario:reservas:estado:leer` | `PENDIENTE_G7`; G7 registra scope/cliente. No concede `modulo-ventas` a Promotions. |
| Lecturas humanas Inventory | Inventory | `userBearer`, rol `GESTOR_COMERCIAL`, capacidad local validada | `PENDIENTE_VERIFICACION`; G7 confirma claims/capability mapping antes de habilitar UI. |
| Cupón con evidencia comercial G5 | Promotions / owner G5 | Sin permiso inferido en este contrato | `PENDIENTE_HOMOLOGACION_EXTERNA`; G5 homologa evidencia de pago/orden y secuencia. |

Rutas `x-internal: true` quedan fuera de Gateway público y APIM. `modulo-ventas` conserva sus scopes y endpoints de reserva/cupón existentes; no se activa consumo de cupón por este documento.
