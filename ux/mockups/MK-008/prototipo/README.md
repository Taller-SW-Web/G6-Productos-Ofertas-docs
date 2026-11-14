# MK-008 — Prototipos HTML de categorías

Se implementan las nueve pantallas definidas en [component-spec](../component-spec.md), [plan](../plan.md) y [tasks](../tasks.md), consumiendo SPEC/HU/WF/FLOW-008 y los DTOs publicados en OpenAPI. Se conserva el logo, shell, tipografía, espaciado y los tres bloques CSS de [MK-009-S01](../../MK-009/prototipo/mk_009_s01.html); el HTML tiene prioridad visual frente a DESIGN.md según la instrucción del usuario.

| Archivo | Nombre para Figma |
|---|---|
| [mk_008_s01.html](mk_008_s01.html) | MK-008-S01 - Categorías y subcategorías |
| [mk_008_s02.html](mk_008_s02.html) | MK-008-S02 - Crear categoría |
| [mk_008_s02_c.html](mk_008_s02_c.html) | MK-008-S02-C - Confirmar slug de categoría |
| [mk_008_s03.html](mk_008_s03.html) | MK-008-S03 - Editar categoría |
| [mk_008_s04.html](mk_008_s04.html) | MK-008-S04 - Solicitar desactivación de categoría |
| [mk_008_s04_p.html](mk_008_s04_p.html) | MK-008-S04-P - Verificando dependencias de categoría |
| [mk_008_s04_b.html](mk_008_s04_b.html) | MK-008-S04-B - Desactivación de categoría bloqueada |
| [mk_008_s05.html](mk_008_s05.html) | MK-008-S05 - Detalle de categoría |
| [mk_008_s05_r.html](mk_008_s05_r.html) | MK-008-S05-R - Reactivación bloqueada por padre inactivo |

Cada archivo contiene su CSS y lógica para importar individualmente con html.to.design. Las fuentes y Tailwind se cargan desde los mismos proveedores que la referencia. [Visor de taxonomía](../../prototipo/taxonomia.html).

## Flujos y fixtures

- S01: árbol de dos niveles, expansión/colapso, búsqueda con contexto jerárquico y filtros por estado. Estados adicionales: `?state=loading`, `?state=empty`, `?state=error`.
- S02: nombre no único, orden entero no negativo, descripción/imagen/padre opcionales. S03: slug de solo lectura; bloquea padre inactivo, autorreferencia, descendientes y tercer nivel.
- S02-C: `?fixture=FX-008-02` propone `deportes-de-montana`; `FX-008-03` propone `futbol-2`; `FX-008-04` rechaza la primera confirmación por concurrencia, permite consultar `futbol-3` y exige una segunda confirmación. Volver a editar conserva el borrador. No se crea antes de confirmar ni se cambia el slug silenciosamente.
- S04: `?id=calzado` bloquea la solicitud por subcategorías activas. `?id=running` permite solicitar comprobación de productos.
- S04-P: `?fixture=FX-008-05`; `?result=blocked` rechaza por 34 productos, `?result=success` representa una comprobación confirmada, `?result=error` mantiene la solicitud pendiente. Sin temporizadores que confirmen una baja. S04-B: `?fixture=FX-008-06`.
- S05/S05-R: `?fixture=FX-008-07` representa Running y Calzado inactivos. S05 también incluye una pareja inactiva estable (`?id=temporada`, padre `colecciones`) para recorrer padre → reactivar → hija.

## Alcance de la simulación

Es un prototipo HTML local; no realiza llamadas reales ni acredita implementación del backend o React/Mantine. Las respuestas de SEO son fixtures predefinidos, no un generador de slug en el formulario. Los nombres con respuestas preparadas son Deportes de Montaña, Fútbol, Running, Calzado, Ropa, Casual y Accesorios. Otros nombres muestran un error recuperable de resolución manteniendo el formulario. La integración real deberá consumir `POST /seo/categorias/slug/resolver` y crear con `slugConfirmado`; al editar se conserva el slug vigente.

Los cambios usan el mismo almacenamiento de sesión del conjunto MK-009/010/011/012 (`po-taxonomy-prototypes-v1`, campo `categories`); las categorías nuevas se añaden a los fixtures SEO para conservar el contexto entre módulos. El borrador usa sessionStorage. «Restablecer datos de ejemplo» en el visor reinicia los datos del conjunto. Las aprobaciones del owner, UX y Figma permanecen pendientes.

## Comprobaciones realizadas — 03/10/2026

- Inventario: 9 de 9 HTML presentes, integrados al visor de 35 pantallas.
- Fidelidad base: mismo logo y los tres bloques CSS originales de MK-009-S01 intactos; enlaces locales válidos, scripts con sintaxis válida y sin IDs duplicados.
- Navegador: nueve vistas revisadas en 1440 × 900 y 390 × 844, sin desbordamiento global; tablas amplias contenidas con desplazamiento horizontal.
- Interacción: expandir/contraer y teclado de nodos; búsqueda con contexto del padre; bloqueo de autorreferencia, descendientes, padre inactivo y tercer nivel; slug de edición de solo lectura; borrador conservado al volver a editar.
- Creación: respuesta sin colisión, sufijo destacado y carrera concurrente que exige consultar otra propuesta y confirmar nuevamente; no persiste antes de la confirmación.
- Baja/reactivación: bloqueo por subcategorías activas; solicitud pendiente; rechazo por 34 productos; error conserva pendiente; reactivación de hija bloqueada hasta reactivar su padre.
- Evidencia: nueve capturas de pantalla guardadas en el directorio de evidencias local de esta sesión.

Estas son comprobaciones del prototipo HTML con fixtures. No constituyen autovalidación del owner ni aprobación de UX/Figma, y no cierran las tareas de integración con el backend.