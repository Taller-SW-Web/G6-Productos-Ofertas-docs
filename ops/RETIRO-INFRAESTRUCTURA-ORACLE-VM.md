# Retiro de CI/CD Oracle y de la infraestructura VM/Compose

**Estado:** retirada operativa fusionada mediante merge normal en [Backend PR #245](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/245). El merge commit es [`a5f4be09f039e2116cc55e55e1862f6164f5431e`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/commit/a5f4be09f039e2116cc55e55e1862f6164f5431e), incorporado en `origin/master`. La revisión auditó el HEAD [`14a9b42eb0de12793ac9c6d949a22938b2f4ae58`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/commit/14a9b42eb0de12793ac9c6d949a22938b2f4ae58); su CI de PR [44406770758](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/44406770758) pasó sobre ese SHA. La CI posmerge [44409230233](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/44409230233) también pasó sobre el merge commit. Esta retirada de infraestructura no demuestra por sí sola la migración completa a Service Bus, la homologación de G1–G5 ni el cumplimiento integral de Hito 5.

## Corte histórico

El punto de partida del trabajo fue [`b1edcf7fe70e98354239290fb5847c49c75d9107`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/tree/b1edcf7fe70e98354239290fb5847c49c75d9107). Antes de publicar el PR, la rama integró el `master` actualizado a [`ce5ef039a67be4890eb960833459eb4281dd80f2`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/tree/ce5ef039a67be4890eb960833459eb4281dd80f2), y el HEAD del PR es el SHA indicado arriba. Las auditorías, actas, manifiestos y procedimientos conservados describen únicamente sus fechas, SHA, artefactos y ambientes observados. No son instrucciones de operación actual ni prueba del estado remoto presente.

## Alcance de la retirada

El cambio fusionado elimina del árbol operativo el workflow de despliegue Oracle, sus scripts operativos y la infraestructura Azure VM/Compose heredada del Backend. Los archivos retirados siguen recuperables mediante el historial Git en los commits anteriores al merge; ya no forman parte del árbol vigente. Las reglas neutrales requeridas por los builds y la publicación manual de imágenes se trasladan a `ops/shared`; Azure Container Apps H5, Service Bus y Caddy como sidecar de Container Apps permanecen en sus rutas vigentes.

La retirada no modifica los contratos HTTP/OpenAPI ni AsyncAPI, los fixtures históricos H4, las migraciones, los handlers de microservicios, seguridad, identidad G7, APIM o la topología Service Bus. Tampoco declara que todos los flujos internos hayan migrado a Service Bus, que exista homologación externa o que los nueve servicios estén desplegados en Azure.

## Conservación y uso de la documentación histórica

Se conservan los contratos y pruebas H4, los documentos de evidencia, los acuerdos y las guías vigentes de Supabase. Sus resultados siguen ligados a su SHA y entorno originales. La infraestructura Oracle/VM/Compose retirada es recuperable desde el historial Git, aunque sus archivos ya no estén en el árbol operativo actual. La documentación histórica H4 no constituye una instrucción de operación vigente; para CI/CD y despliegue actuales, consultar los workflows activos del Backend y las instrucciones Azure Container Apps H5.

La CI de PR y la CI posmerge citadas arriba corresponden, respectivamente, al HEAD revisado y al merge commit. La retirada es un cambio operativo de CI/infraestructura; no modifica ni acredita la implementación de Service Bus, la homologación externa ni el cumplimiento completo del Hito 5. Los estados de aprovisionamiento, implementación, pruebas runtime, homologación G1–G5 y autorización G7 se mantienen independientes y requieren su propia evidencia.
