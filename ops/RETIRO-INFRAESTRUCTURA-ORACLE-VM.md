# Retiro de CI/CD Oracle y de la infraestructura VM/Compose

**Estado:** retirada operativa propuesta en [Backend PR #245](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/245), Draft, rama `trabajo/castilla/retiro-oracle-h5`, HEAD `f1d632802644ddb7a18b5fbfe4c1dead564aba63`. No está fusionado y no afirma que una migración funcional haya terminado.

## Corte histórico

El punto de partida del trabajo fue [`b1edcf7fe70e98354239290fb5847c49c75d9107`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/tree/b1edcf7fe70e98354239290fb5847c49c75d9107). Antes de publicar el PR, la rama integró el `master` actualizado a [`ce5ef039a67be4890eb960833459eb4281dd80f2`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/tree/ce5ef039a67be4890eb960833459eb4281dd80f2), y el HEAD del PR es el SHA indicado arriba. Las auditorías, actas, manifiestos y procedimientos conservados describen únicamente sus fechas, SHA, artefactos y ambientes observados. No son instrucciones de operación actual ni prueba del estado remoto presente.

## Alcance de la retirada

El cambio propuesto elimina el workflow de despliegue Oracle, sus scripts operativos y la infraestructura Azure VM/Compose heredada del Backend. Las reglas neutrales requeridas por los builds y la publicación manual de imágenes se trasladan a `ops/shared`; Azure Container Apps H5, Service Bus y Caddy como sidecar de Container Apps permanecen en sus rutas vigentes.

La retirada no modifica los contratos HTTP/OpenAPI ni AsyncAPI, los fixtures históricos H4, las migraciones, los handlers de microservicios, seguridad, identidad G7, APIM o la topología Service Bus. Tampoco declara que todos los flujos internos hayan migrado a Service Bus, que exista homologación externa o que los nueve servicios estén desplegados en Azure.

## Conservación y uso de la documentación histórica

Se conservan los contratos y pruebas H4, los documentos de evidencia, los acuerdos, las guías RabbitMQ de compatibilidad y las guías vigentes de Supabase. Sus resultados siguen ligados a su SHA y entorno originales. Para CI/CD y despliegue actuales, consultar los workflows activos del Backend y las instrucciones Azure Container Apps H5; no ejecutar recetas VM/Compose archivadas como procedimientos vigentes.

El PR registra los comandos ejecutados y sus resultados asociados al SHA, incluido que las suites que requieren Docker no pudieron completarse localmente porque el daemon no estaba disponible. Los checks integrales de GitHub siguen pendientes del ciclo Draft → Ready. Hasta su aprobación y merge, la retirada está propuesta y los estados de implementación H5 permanecen independientes.
