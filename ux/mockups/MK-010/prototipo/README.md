# MK-010 — Prototipos HTML

Referencia visual: `../../MK-009/prototipo/mk_009_s01.html`, remoto `fa0bc52`. Su logo, cabecera, sidebar, espaciado y estilos tienen prioridad frente a `../../DESIGN.md`, según la solicitud de esta entrega. Cada pantalla conserva el mismo shell y contiene sus estilos y lógica de prototipado para permitir importación individual en html.to.design.

## Pantallas y nombres para Figma

| Archivo | Nombre del frame |
|---|---|
| [mk_010_s01.html](mk_010_s01.html) | MK-010-S01 - Tipos de producto |
| [mk_010_s02.html](mk_010_s02.html) | MK-010-S02 - Crear tipo de producto |
| [mk_010_s03.html](mk_010_s03.html) | MK-010-S03 - Configurar esquema |
| [mk_010_s04.html](mk_010_s04.html) | MK-010-S04 - Asociar característica |
| [mk_010_s05.html](mk_010_s05.html) | MK-010-S05 - Desasociar característica |
| [mk_010_s06.html](mk_010_s06.html) | MK-010-S06 - Desactivar tipo de producto |
| [mk_010_s07.html](mk_010_s07.html) | MK-010-S07 - Reactivar tipo de producto |

## Revisión e importación

Abra el [visor de taxonomía](../../prototipo/taxonomia.html) desde un servidor local o abra los HTML directamente. Revisión desktop: 1440 × 900 px. Se conserva la navegación responsive de la referencia. Las fuentes Inter/Oswald y Tailwind se cargan desde los mismos proveedores externos que el ejemplo. Para conservar lo renderizado, importe un archivo o capture desde el navegador con html.to.design.

## Alcance del prototipo

Los registros son fixtures locales, no datos de un backend. Las acciones simulan guardados y verificaciones; al servir todos los archivos en el mismo origen, los cambios de la sesión se conservan en localStorage bajo `po-taxonomy-prototypes-v1`. Los controles de navegación ajenos a MK-009/010/011/012 se muestran como contexto del shell sin ofrecer rutas inexistentes. Esta entrega no declara aprobación UX ni cierre de Figma.

Escenarios de revisión por URL:

- Listados: `?state=loading`, `?state=empty`, `?state=error`.
- Esquema/asociación: `?id=calzado`; `?state=limit` representa el límite configurado alcanzado. El fixture usa el límite inicial de 20 de SPEC-010. Bajas S05/S06: `?state=pending`, `?state=blocked`, `?state=error`; `?result=success` representa comprobación confirmada, sin temporizadores falsos.

Las pantallas de baja distinguen solicitud recibida, comprobación pendiente, rechazo y error. Una respuesta no concluyente conserva el estado previo. Los estados se controlan mediante fixtures documentados; no se representa una conexión real con Catálogo.

## Fuentes funcionales y comprobaciones

El inventario, los campos, las validaciones y los estados se tomaron de `../component-spec.md`, `../plan.md` y `../tasks.md`, además de las especificaciones de dominio enlazadas. Los planes de React/Mantine se interpretan aquí como requisitos de interacción para una entrega de prototipos HTML independientes; esta entrega no implementa backend ni marca como terminadas esas tareas de integración.

Se verificaron las 26 pantallas del conjunto en escritorio (1440 × 900) y móvil (390 × 844). Las tablas amplias mantienen desplazamiento horizontal dentro de su contenedor. La comprobación estructural confirmó el logo idéntico, los tres bloques CSS originales intactos, los enlaces locales existentes, la sintaxis de los scripts y la ausencia de identificadores duplicados.

Se probaron los campos condicionales, el bloqueo del tipo de dato, los filtros, el alta y asociación del esquema, el cambio de obligatoriedad y deshacer, los estados de baja, la unicidad entre marcas inactivas, la carga de logos y las advertencias SEO no bloqueantes. En el visor, «Restablecer datos de ejemplo» permite volver a los fixtures iniciales después de revisar los flujos. Las aprobaciones de UX, Figma y validación del equipo siguen pendientes.