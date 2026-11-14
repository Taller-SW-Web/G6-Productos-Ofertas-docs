# HU-011 — Historia de Usuario: Gestión de marcas

**Responsable:** Leonardo Lopez  
**Rama:** lopez  
**Trazabilidad:** Spec [SPEC-011](../specs/SPEC-011-gestion-marcas.md) | Flow [WF-011](..\..\ux\wireframes\flows\WF-011-gestion-marcas.md)

**Como** gestor comercial, **quiero** crear, editar, desactivar y reactivar marcas, **para** clasificar productos y habilitar navegación por marca.

## Criterios de aceptación
| ID | Criterio |
|---|---|
| CA-01 | Crear con nombre único, descripción opcional, logo y país opcional. |
| CA-02 | La unicidad normalizada incluye marcas activas e inactivas. |
| CA-03 | Editar nombre, descripción, logo y país. |
| CA-04 | Baja lógica bloqueada si hay productos activos. |
| CA-05 | Reactivar una marca previamente inactiva. |
| CA-06 | Nunca eliminación física. |
| CA-07 | Exponer marcas activas a Catálogo/canales. |
| CA-08 | PNG/JPG/JPEG/WebP hasta 5 MB. |
| CA-09 | País opcional validado como ISO 3166-1. |
| CA-10 | Renombre duplicado se rechaza también frente a inactivas. |
| CA-11 | Solo `CLEAR` asíncrono bajo barrera confirma la baja. |
| CA-12 | Reactivación conserva ID/nombre. |
| CA-13 | Falta de respuesta conserva la marca activa. |
| CA-14 | Seguridad asigna acceso; esta HU no declara un rol global como contrato propio. |
| CA-15 | Crear, editar y reactivar marcas se representan por persistencia y consulta HTTP; no publican ningún mensaje propio. |
| CA-16 | La única mensajería de Marcas es el protocolo transversal publicado para la baja segura; no existen eventos genéricos de «actualización» ni de «estado» de marca. |

## Escenarios
1. Crear Nike válida → Activa.
2. Crear `NIKE` si Nike está activa o inactiva → rechazo.
3. Reemplazar logo válido → actualización.
4. Marca sin productos → baja solo tras confirmación segura.
5. Marca con productos → rechazo.
6. Logo >5 MB o MIME no admitido → rechazo.
7. Reactivación → mismo ID.
8. Verificación no concluyente → sigue Activa.
9. Editar una marca → el listado de marcas activas refleja el cambio sin ningún evento de marca.
10. Reactivar una marca → el canal la vuelve a ver en sus filtros sin ningún evento de estado.
