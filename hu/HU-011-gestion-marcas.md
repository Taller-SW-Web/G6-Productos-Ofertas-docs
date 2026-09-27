# HU-011 — Historia de Usuario: Gestión de marcas

**Responsable:** Leonardo Lopez  
**Rama:** lopez  
**Trazabilidad:** Spec [SPEC-011](../specs/SPEC-011-gestion-marcas.md) | Flow [WF-011](../wireframes/flows/WF-011-gestion-marcas.md)

**Como** **gestor comercial**,

**quiero** crear, editar, desactivar y reactivar las marcas del catálogo

**para** que los productos puedan clasificarse por marca y los clientes puedan navegar y filtrar el catálogo por esta dimensión.

## Criterios de aceptación

| **ID** | **Criterio** |
| --- | --- |
| **CA-01** | El sistema debe permitir crear una marca con nombre único, descripción opcional, logo y país de origen opcional. |
| **CA-02** | El sistema debe impedir nombres duplicados normalizados en marcas activas **o inactivas**, incluyendo creación y cambio de nombre; reactivar no crea otra marca. |
| **CA-03** | El sistema debe permitir actualizar nombre, descripción, logo y país de origen de una marca existente. |
| **CA-04** | El sistema debe permitir desactivar (baja lógica) una marca, impidiendo la desactivación si tiene productos activos asociados. |
| **CA-05** | El sistema debe permitir reactivar una marca previamente desactivada. |
| **CA-06** | El sistema NUNCA debe eliminar físicamente una marca; toda baja es lógica. |
| **CA-07** | El sistema debe exponer un endpoint de solo lectura con las marcas activas, para ser consumido por otros módulos y canales de venta. |
| **CA-08** | El sistema debe aceptar únicamente logos PNG, JPG/JPEG o WebP de hasta 5 MB; debe rechazar otros formatos o tamaños superiores indicando el motivo. |
| **CA-09** | Si se registra país de origen, debe seleccionarse o validarse contra un código ISO 3166-1; no se admite texto libre no normalizado. |
| **CA-10** | El nombre normalizado de una marca es globalmente único, incluso entre marcas inactivas; se rechazan renombres duplicados. |
| **CA-11** | Una solicitud de desactivación solo concluye tras confirmación asíncrona `CLEAR` de Catálogo bajo barrera concurrente; rechazo o falta de respuesta no desactiva. |
| **CA-12** | Una reactivación conserva el mismo ID y nombre, sin crear duplicados. |

## Escenarios dado-cuando-entonces

**Escenario 1: Creación exitosa de una marca**

* **DADO** que el gestor comercial está autenticado,
* **CUANDO** crea la marca "Nike" con descripción y logo válidos,
* **ENTONCES** el sistema registra la marca con estado ACTIVO.

**Escenario 2: Intento de crear una marca con nombre duplicado**

* **DADO** que ya existe una marca activa con el nombre "Nike",
* **CUANDO** el gestor comercial intenta crear otra marca con el mismo nombre,
* **ENTONCES** el sistema rechaza la operación e indica que el nombre de marca ya existe.

**Escenario 3: Actualización exitosa del logo de una marca**

* **DADO** que existe la marca "Nike" con un logo registrado,
* **CUANDO** el gestor comercial sube un nuevo archivo de logo,
* **ENTONCES** el sistema reemplaza el logo anterior y actualiza la fecha de modificación.

**Escenario 4: Desactivación exitosa de una marca sin productos activos**

* **DADO** que la marca "Wilson" no tiene productos activos asociados,
* **CUANDO** el gestor comercial solicita desactivarla,
* **ENTONCES** el sistema cambia su estado a INACTIVO y deja de mostrarla en los filtros de los canales.

**Escenario 5: Intento de desactivar una marca con productos activos**

* **DADO** que la marca "Nike" tiene productos activos asociados,
* **CUANDO** el gestor comercial solicita desactivarla,
* **ENTONCES** el sistema rechaza la operación e indica que primero deben desactivarse o reasignarse los productos asociados.

**Escenario 6: Intento de subir un logo que excede el tamaño máximo**

* **DADO** que el gestor comercial selecciona un archivo de logo de 8 MB,
* **CUANDO** intenta subirlo para la marca "Nike",
* **ENTONCES** el sistema rechaza el archivo e indica que el tamaño máximo permitido es 5 MB.

**Escenario 7: Reactivación exitosa de una marca**

* **DADO** que la marca "Wilson" está INACTIVA,
* **CUANDO** el gestor comercial solicita reactivarla,
* **ENTONCES** el sistema cambia su estado a ACTIVO y vuelve a mostrarla en los filtros de los canales.

**Escenario 8: Nombre reservado por marca inactiva**
* **DADO** que existe «Nike» inactiva,
* **CUANDO** se intenta registrar «NIKE»,
* **ENTONCES** se rechaza la creación por nombre normalizado duplicado.

**Escenario 9: Sin confirmación asíncrona de Catálogo**
* **DADO** una marca cuya baja fue solicitada,
* **CUANDO** Catálogo no confirma la inexistencia de productos activos,
* **ENTONCES** la marca conserva su estado activo y la operación informa pendiente o rechazada.

## Interacción con otros módulos

| **Módulo** | **Necesidad de interacción** | **Información que esta funcionalidad recibe** | **Información que esta funcionalidad entrega** |
| --- | --- | --- | --- |
| **Seguridad y Usuarios** | Verificar que quien crea, edita, desactiva o reactiva marcas tenga el rol de gestor comercial. | Identidad del usuario, token de sesión, roles y permisos. | Solicitudes de validación de permisos para las operaciones de escritura. |
| **Catálogo Core (Productos)** | Consultar marcas activas al momento de clasificar un producto. Al intentar desactivar una marca, Taxonomía solicita una verificación **asíncrona** a Catálogo; Catálogo bloquea las altas/activaciones/reasignaciones concurrentes y responde por identificador de operación. Sin confirmación `CLEAR` no se desactiva. | Identificador de marca a validar. | Listado de marcas activas vía API; resultado de verificación correlacionado, sin llamada síncrona interna. |
| **Canales de venta (Marketplace, Chatbot, Retail)** | Mostrar el filtro de marcas para la navegación y búsqueda de productos. | (No hay interacción directa; solo consume el resultado). | Listado de marcas activas para renderizar filtros. |

## Dependencias dentro de Productos y Ofertas

| **Funcionalidad interna** | **Información necesaria** |
| --- | --- |
| **Carga y Exportación Masiva (Excel/CSV)** | Nombres/identificadores de marcas declarados en el archivo, para validar su existencia antes de vincularlas a un producto. |

## Reglas resueltas (antes pendientes)

* **Tamaño máximo del logo:** 5 MB por archivo.
* **Validación de productos activos antes de desactivar:** se realiza mediante solicitud/respuesta asíncronas, barrera concurrente en Catálogo y confirmación correlacionada. Falta de respuesta implica operación pendiente o rechazada, nunca baja confirmada.

## Reglas resueltas adicionales

* **Formato del logo:** PNG, JPG/JPEG y WebP; máximo 5 MB. SVG queda fuera del alcance inicial.
* **País de origen:** se normaliza mediante ISO 3166-1.
