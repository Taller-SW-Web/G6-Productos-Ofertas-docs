# MK-012 — Prototipos HTML

Referencia visual: `../../MK-009/prototipo/mk_009_s01.html`, remoto `fa0bc52`. Su logo, cabecera, sidebar, espaciado y estilos tienen prioridad frente a `../../DESIGN.md`, según la solicitud de esta entrega. Cada pantalla conserva el mismo shell y contiene sus estilos y lógica de prototipado para permitir importación individual en html.to.design.

## Pantallas y nombres para Figma

| Archivo | Nombre del frame |
|---|---|
| [mk_012_s01.html](mk_012_s01.html) | MK-012-S01 - SEO por categoría |
| [mk_012_s02.html](mk_012_s02.html) | MK-012-S02 - Configurar SEO de categoría |
| [mk_012_s03.html](mk_012_s03.html) | MK-012-S03 - Historial de redirecciones |

## Revisión e importación

Abra el [visor de taxonomía](../../prototipo/taxonomia.html) desde un servidor local o abra los HTML directamente. Revisión desktop: 1440 × 900 px. Se conserva la navegación responsive de la referencia. Las fuentes Inter/Oswald y Tailwind se cargan desde los mismos proveedores externos que el ejemplo. Para conservar lo renderizado, importe un archivo o capture desde el navegador con html.to.design.

## Alcance del prototipo

Los registros son fixtures locales, no datos de un backend. Las acciones simulan guardados y verificaciones; al servir todos los archivos en el mismo origen, los cambios de la sesión se conservan en localStorage bajo `po-taxonomy-prototypes-v1`. Los controles de navegación ajenos a MK-009/010/011/012 se muestran como contexto del shell sin ofrecer rutas inexistentes. Esta entrega no declara aprobación UX ni cierre de Figma.

Escenarios de revisión por URL:

- Listados: `?state=loading`, `?state=empty`, `?state=error`.
- Configuración SEO: `?id=running`, `?id=accesorios` o `?id=futbol`; `?state=long` muestra advertencias 70/160 no bloqueantes; `?id=futbol&state=collision` muestra la propuesta `futbol-2` y exige confirmación antes de reemplazar. Historial: `?state=empty`.

Las pantallas de baja distinguen solicitud recibida, comprobación pendiente, rechazo y error. Una respuesta no concluyente conserva el estado previo. Los estados se controlan mediante fixtures documentados; no se representa una conexión real con Catálogo.

## Fuentes funcionales y comprobaciones

El inventario, los campos, las validaciones y los estados se tomaron de `../component-spec.md`, `../plan.md` y `../tasks.md`, además de las especificaciones de dominio enlazadas. Los planes de React/Mantine se interpretan aquí como requisitos de interacción para una entrega de prototipos HTML independientes; esta entrega no implementa backend ni marca como terminadas esas tareas de integración.

Se verificaron las 26 pantallas del conjunto en escritorio (1440 × 900) y móvil (390 × 844). Las tablas amplias mantienen desplazamiento horizontal dentro de su contenedor. La comprobación estructural confirmó el logo idéntico, los tres bloques CSS originales intactos, los enlaces locales existentes, la sintaxis de los scripts y la ausencia de identificadores duplicados.

Se probaron los campos condicionales, el bloqueo del tipo de dato, los filtros, el alta y asociación del esquema, el cambio de obligatoriedad y deshacer, los estados de baja, la unicidad entre marcas inactivas, la carga de logos y las advertencias SEO no bloqueantes. En el visor, «Restablecer datos de ejemplo» permite volver a los fixtures iniciales después de revisar los flujos. Las aprobaciones de UX, Figma y validación del equipo siguen pendientes.