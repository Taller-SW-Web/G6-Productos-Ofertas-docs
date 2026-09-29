# Índice de funcionalidades y wireframes

**Módulo:** Productos y Ofertas  
**Estado documental:** Consolidado  
**Última sincronización:** 2026-09-28

Este índice registra la asignación final de las 16 funcionalidades del módulo, sus responsables y las rutas canónicas de SPEC, HU, wireframe y prototipo HTML.

Todos los identificadores `WF-001` a `WF-016` están asignados y cuentan con sus cuatro artefactos documentales principales. Las rutas de esta tabla son las que deben utilizarse para el empaquetado final y para la navegación dentro del repositorio.

## Responsables

| Rama | Autor | Área funcional asignada |
|---|---|---|
| `poma` | Gabriel Poma Gutierrez | Productos y variantes SKU |
| `castilla` | Marco Renato Castilla Huanca | Carga/exportación masiva y combos |
| `cueva` | Axel Andree Cueva Alcalá | Cupones, ofertas/promociones y venta cruzada |
| `lopez` | Leonardo Lopez | Taxonomía, características, tipos de producto, marcas y SEO |
| `vera` | Leonardo Vera Rodríguez | Precios y auditoría de precios |
| `taco` | Miguel Ángel Taco Zavala | Inventario, analítica y alertas de stock |

## Inventario final

| ID | Funcionalidad | Rama | Responsable | SPEC | HU | Flow | Prototipo HTML | Estado |
|---|---|---|---|---|---|---|---|---|
| WF-001 | Carga y exportación masiva de productos | `castilla` | Marco Renato Castilla Huanca | [SPEC](./specs/SPEC-001-carga-exportacion-masiva-productos.md) | [HU](./hu/HU-001-carga-exportacion-masiva-productos.md) | [Flow](flows/WF-001-carga-exportacion-masiva-productos.md) | [Prototipo](prototipos/WF-001-carga-exportacion-masiva-productos/index.html) | Completado |
| WF-002 | Gestión de combos de productos | `castilla` | Marco Renato Castilla Huanca | [SPEC](./specs/SPEC-002-gestion-combos-productos.md) | [HU](./hu/HU-002-gestion-combos-productos.md) | [Flow](flows/WF-002-gestion-combos-productos.md) | [Prototipo](prototipos/WF-002-gestion-combos-productos/index.html) | Completado |
| WF-003 | Gestión de productos (CRUD principal) | `poma` | Gabriel Poma Gutierrez | [SPEC](./specs/SPEC-003-gestion-productos-crud.md) | [HU](./hu/HU-003-gestion-productos-crud.md) | [Flow](flows/WF-003-gestion-productos-crud.md) | [Prototipo](prototipos/WF-003-gestion-productos-crud/index.html) | Completado |
| WF-004 | Gestión avanzada de variantes (SKUs) | `poma` | Gabriel Poma Gutierrez | [SPEC](./specs/SPEC-004-gestion-variantes-skus.md) | [HU](./hu/HU-004-gestion-variantes-skus.md) | [Flow](flows/WF-004-gestion-variantes-skus.md) | [Prototipo](prototipos/WF-004-gestion-variantes-skus/index.html) | Completado |
| WF-005 | Gestión de cupones de descuento | `cueva` | Axel Andree Cueva Alcalá | [SPEC](./specs/SPEC-005-gestion-cupones-descuento.md) | [HU](./hu/HU-005-gestion-cupones-descuento.md) | [Flow](flows/WF-005-gestion-cupones-descuento.md) | [Prototipo](prototipos/WF-005-gestion-cupones-descuento/index.html) | Completado |
| WF-006 | Gestión de ofertas y promociones | `cueva` | Axel Andree Cueva Alcalá | [SPEC](./specs/SPEC-006-gestion-ofertas-promociones.md) | [HU](./hu/HU-006-gestion-ofertas-promociones.md) | [Flow](flows/WF-006-gestion-ofertas-promociones.md) | [Prototipo](prototipos/WF-006-gestion-ofertas-promociones/index.html) | Completado |
| WF-007 | Reglas de venta cruzada y upselling | `cueva` | Axel Andree Cueva Alcalá | [SPEC](./specs/SPEC-007-reglas-venta-cruzada-upselling.md) | [HU](./hu/HU-007-reglas-venta-cruzada-upselling.md) | [Flow](flows/WF-007-reglas-venta-cruzada-upselling.md) | [Prototipo](prototipos/WF-007-reglas-venta-cruzada-upselling/index.html) | Completado |
| WF-008 | Gestión de categorías y subcategorías | `lopez` | Leonardo Lopez | [SPEC](./specs/SPEC-008-gestion-categorias.md) | [HU](./hu/HU-008-gestion-categorias.md) | [Flow](flows/WF-008-gestion-categorias.md) | [Prototipo](prototipos/WF-008-gestion-categorias/index.html) | Completado |
| WF-009 | Gestión de características y sus valores | `lopez` | Leonardo Lopez | [SPEC](./specs/SPEC-009-gestion-caracteristicas.md) | [HU](./hu/HU-009-gestion-caracteristicas.md) | [Flow](flows/WF-009-gestion-caracteristicas.md) | [Prototipo](prototipos/WF-009-gestion-caracteristicas/index.html) | Completado |
| WF-010 | Asociación entre tipos de producto y características | `lopez` | Leonardo Lopez | [SPEC](./specs/SPEC-010-asociacion-tipo-producto-caracteristica.md) | [HU](./hu/HU-010-asociacion-tipo-producto-caracteristica.md) | [Flow](flows/WF-010-asociacion-tipo-producto-caracteristica.md) | [Prototipo](prototipos/WF-010-asociacion-tipo-producto-caracteristica/index.html) | Completado |
| WF-011 | Gestión de marcas | `lopez` | Leonardo Lopez | [SPEC](./specs/SPEC-011-gestion-marcas.md) | [HU](./hu/HU-011-gestion-marcas.md) | [Flow](flows/WF-011-gestion-marcas.md) | [Prototipo](prototipos/WF-011-gestion-marcas/index.html) | Completado |
| WF-012 | Gestión de SEO y metadatos | `lopez` | Leonardo Lopez | [SPEC](./specs/SPEC-012-seo-metadatos.md) | [HU](./hu/HU-012-seo-metadatos.md) | [Flow](flows/WF-012-seo-metadatos.md) | [Prototipo](prototipos/WF-012-seo-metadatos/index.html) | Completado |
| WF-013 | Gestión de precios individuales y masivos | `vera` | Leonardo Vera Rodríguez | [SPEC](./specs/SPEC-013-gestion-precios-individuales-masivos.md) | [HU](./hu/HU-013-gestion-precios-individuales-masivos.md) | [Flow](flows/WF-013-gestion-precios-individuales-masivos.md) | [Prototipo](prototipos/WF-013-gestion-precios-individuales-masivos/index.html) | Completado |
| WF-014 | Historial de auditoría de precios | `vera` | Leonardo Vera Rodríguez | [SPEC](./specs/SPEC-014-historial-auditoria-precios.md) | [HU](./hu/HU-014-historial-auditoria-precios.md) | [Flow](flows/WF-014-historial-auditoria-precios.md) | [Prototipo](prototipos/WF-014-historial-auditoria-precios/index.html) | Completado |
| WF-015 | Control de stock y disponibilidad | `taco` | Miguel Ángel Taco Zavala | [SPEC](./specs/SPEC-015-control-stock-disponibilidad.md) | [HU](./hu/HU-015-control-stock-disponibilidad.md) | [Flow](flows/WF-015-control-stock-disponibilidad.md) | [Prototipo](prototipos/WF-015-control-stock-disponibilidad/index.html) | Completado |
| WF-016 | Dashboard analítico y alertas de stock | `taco` | Miguel Ángel Taco Zavala | [SPEC](./specs/SPEC-016-dashboard-alertas-stock.md) | [HU](./hu/HU-016-dashboard-alertas-stock.md) | [Flow](flows/WF-016-dashboard-alertas-stock.md) | [Prototipo](prototipos/WF-016-dashboard-alertas-stock/index.html) | Completado |

## Evidencia resumida por rama

| Rama | Funcionalidades asignadas |
|---|---|
| `castilla` | WF-001, WF-002 |
| `poma` | WF-003, WF-004 |
| `cueva` | WF-005, WF-006, WF-007 |
| `lopez` | WF-008, WF-009, WF-010, WF-011, WF-012 |
| `vera` | WF-013, WF-014 |
| `taco` | WF-015, WF-016 |

## Convenciones canónicas

- SPEC: `specs/SPEC-XXX-*.md`.
- HU: `hu/HU-XXX-*.md`.
- Flows: `wireframes/flows/WF-XXX-*.md`.
- Prototipos: `wireframes/prototipos/WF-XXX-*/index.html`.
- Cada prototipo es HTML/CSS/JavaScript estático, navegable y sin compilación.
- Los prototipos no forman parte de la implementación productiva del frontend.
- `DESIGN.md` gobierna la representación visual de baja fidelidad.
- SPEC/HU/WF gobiernan reglas y flujo; OpenAPI/AsyncAPI gobiernan contratos ejecutables.

## Regla de mantenimiento

Cuando una funcionalidad cambie, debe mantenerse alineada la cadena:

```text
SPEC -> HU -> WF -> HTML
              |
              +-> OpenAPI / AsyncAPI cuando corresponda
```

Una funcionalidad solo puede figurar como **Completado** cuando existen y están alineados sus cuatro artefactos principales.
