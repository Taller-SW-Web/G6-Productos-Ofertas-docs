# Resultados — Swagger Studio, 2026-11-05 Lima

Base: `poma@2f1346f04f9b772fbde7dd7db094a9e5671dfb15`, master `a7778ec1a22811c1213a94ef096ab905911342cc`. Creación 2026-11-06T00:27:36Z, 5 de noviembre en Lima.

- Organización autorizada y búsqueda sin APIs verificadas. Creación efectiva mediante `create_or_update_api`; versión devuelta y recuperada `0.6.0-rc.3`, sin bootstrap 1.0.0 pese al descriptor de herramienta.
- Definición completa recuperada tras crear y modificar solo servidor de presentación: idéntica a la derivación autorizada (`info.title`, `servers`), 136 operaciones/13 tags/177 schemas. Parámetros, cuerpos, respuestas, ejemplos, seguridad y extensiones intactos.
- Lectura posterior de metadatos: `private=true`, `published=false`. URL oficial en [evidencia](studio-2026-11-05.json). `validate_api` persistida: cero errores/advertencias.
- Corrección YAML: cinco líneas redundantes retiradas con autorización y comparación semántica antes/después idéntica. `npm run validate`, `npm run export`, `npm test`: PASS. No cambios de reglas/allowlist/scopes.
- GET HTTPS directos sin tokens: categorías 200/1149 ms, marcas 503/100 ms, productos 200/12085 ms, ficha por slug real 200/2046 ms. DNS/TLS verificados; cuerpos 200 pasan schema estructural sin validación adicional de formatos. [Resumen sin datos de negocio](runtime-summary-2026-11-05.json).
- Sin JWT real, SHA desplegado, CORS funcional ni ejecución Try it out de navegador acreditados. Sin proxy SmartBear ni mocks usados para estas sondas. Preferencia de conexión no expuesta por complemento.
- Cuerpos completos solo en `reports/`, excluido de Git. La revisión automática rechazó copiarlos al PR por exposición potencial; se guardó resumen sin registros de negocio.
- Regresión de 61 pruebas: fallo preexistente `InventoryStockChanged`; no se cambia AsyncAPI ni expectativas para obtener verde.

La [documentación oficial](https://support.smartbear.com/swagger/studio/docs/en/edit-apis/interactive-api-documentation.html) describe la interfaz de Studio. Su visualización y modo directo requieren revisión manual del usuario; no se utilizó Computer Use ni otra automatización de navegador.

El workflow valida/exporta y adjunta evidencias; consultar su estado remoto en PR #116. Las ejecuciones anteriores no acreditan este HEAD. Integración persistente unidireccional implementada con el complemento; sincronización Git automática no disponible/configurada. No se crearon portales ni recursos públicos ni se desplegaron servicios.
