# Auditoría HTTP en curso

Última ejecución nueva `node tests/h5/certify-158-endpoints.mjs`: 158/158 PASS, Bulk/N01 COMPLETED, authChecksPass=true. Reporte HTTP_158_PAGINACION_CORREGIDA.json. No equivale a dos regresiones integrales ni Azure.

Las negativas adicionales de listarCategoriasAdmin, listarMarcasAdmin, listarPromocionesAdmin y listarTrasladosInventario revelaron400 de proveedor transformado503 en Gateway: faltaba400VALIDACION en OpenAPI y tabla de rutas. Se alinean con paginación minimum1 ya vigente, sin debilitar rechazo. Regresión Gateway con upstreams HTTP controlados y JWT RS256 real:7/7PASS. Paridad y generador:10/10PASS. Build Backend PASS. YAML sin claves duplicadas; cuatro respuestas/error map400 comprobadas.

Persistencia Inventory: resolución verificada por incidencia_id/tipo_resolucion/estado RESUELTA; recepción por receipt_id→recepcion_id, cantidad_recibida, disposicion y es_recepcion_final. Las consultas locales preexistentes usaban columnas inexistentes; se corrigieron conforme al esquema.

El generador de rutas sobre el contrato entero rechazó metadatos históricos faltantes de obtenerDefinicionPrecioProductoAdministracion; se preservó su fail-closed y se aplicó cambio puntual a cuatro rutas. No se declaró regeneración global satisfactoria. Pendiente auditar resto de aserciones genéricas, paridad completa de respuestas y matrices canónicas, suite completa y dos regresiones limpias.
