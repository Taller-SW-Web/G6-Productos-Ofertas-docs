# Correcciones funcionales locales — WF-005, WF-006 y WF-007

Responsable: Axel Andree Cueva Alcalá. Fecha: 2026-10-02.

## Alcance y resultado

Corregidos los ocho hallazgos de la auditoría local de las funcionalidades 005–007 en sus wireframes y documentación administrativa. La comprobación se realizó en Chrome con Playwright, viewport 1440×900, usando datos locales en memoria.

| Hallazgo | Corrección | Evidencia de comprobación |
|---|---|---|
| R1: promociones pierde acciones al cambiar campos | Eventos delegados en el contenedor; las reconstrucciones conservan Guardar/Cancelar | Cambiar campos, cancelar, provocar errores, corregir y guardar; editar y volver a guardar |
| R2: recomendaciones sin vigencia/estado/origen tipado | Inicio y fin obligatorios, estado inicial elegible, origen Producto/Categoría con ID | Rechazo sin fechas, rechazo de rango invertido, guardado con estado explícito, cambio a categoría |
| R3: orden/justificación inválidos | Orden/prioridad enteros positivos; justificación hasta 500 caracteres | Orden 0, negativo o fraccionario rechazado; 501 caracteres rechazados incluso al omitir maxlength |
| R4: detalle de otro cupón | Detalle por ID seleccionado con sus propios valores | SETIEMBRE10 muestra su código, límites y política, sin BIENVENIDA20 |
| R5: cupón comunica éxito sin guardar | Crear/editar actualiza fixtures y valida código, unicidad y valores opcionales | Código vacío/duplicado rechazado; límites inválidos rechazados; código normalizado; vacíos como null; edición propia y cambio de estado conservan usos |
| R6: alcance por producto convertido en SKU actuales | productIds y skus separados; coincidencias deduplicadas | Producto completo conserva ID; SKU nuevo queda cubierto; SKU específico y deselección siguen independientes |
| R7: canales/modalidad inconsistentes | Canales explícitos, únicos y no vacíos; capacidad administrativa calculada por servicio | Schema rechaza omisión/vacío/duplicados al crear; PATCH conserva si omite; modalidad permitida sin historia y bloqueada con activación/cupones/usos |
| R8: precio/saldo inventados | Información comercial ausente hasta alinear D-REC-01/02 | Detalle muestra No disponible; no introduce precio ni cantidades al añadir recomendado |

## Pruebas ejecutadas

- `validate-005-007.cjs`: **28 grupos de comprobaciones aprobados**; sin errores de consola ni solicitudes HTTP a servicios externos. Incluye fallos de guardado con entradas conservadas y estados de carga, vacío, permiso y sesión.
- `validate-contracts.cjs`: **7 grupos de comprobaciones aprobados**. OpenAPI/AsyncAPI analizados sin errores de YAML ni claves duplicadas; **1.222** referencias locales HTTP y **273** referencias locales de mensajería resueltas.
- `node --check`: JavaScript de los tres wireframes sin errores de sintaxis.
- Validación de flujos: **13 diagramas** analizados/renderizados; **20 operaciones HTTP**, **10 eventos** y **26 enlaces** coherentes con sus fuentes.
- `git diff --check`: sin errores de espacios o conflictos.

Los scripts de esta carpeta permiten reproducir la validación del comportamiento y los contratos. Las capturas y los resultados JSON de esta ejecución se conservaron fuera del repositorio durante la revisión local.

## Límites y revisión pendiente

El resultado acredita correcciones de wireframes, fixtures y documentación. No es aprobación UX de mockups, APROBADO PARA FIGMA, validación de fidelidad ni cierre de issues. No hay backend, SQL o despliegue acreditados por estas pruebas.

`puedeCambiarModalidad` es un campo administrativo de respuesta de solo lectura; el servicio futuro debe calcularlo y revalidar el cambio sin confiar en un valor enviado por el cliente. Los consumidores de los contratos provisionales deben incorporar este ajuste al integrarse. Los canales ya no admiten un default implícito «todos».

D-REC-01/02 y los enriquecimientos comerciales siguen pendientes de coordinación con sus owners. El prototipo no resuelve esas decisiones ni realiza una agregación de inventario. La persistencia y la integración real de consumption/restoration, Pricing, Inventario, Catálogo y Ventas requieren sus pruebas correspondientes.

La publicación en la rama `cueva` conserva este alcance de validación; las revisiones e integraciones pendientes siguen abiertas.
