# WF-006 — Gestión de ofertas y promociones

> **Fuentes normativas:** `././specs/SPEC-006-gestion-ofertas-promociones.md`, `././hu/HU-006-gestion-ofertas-promociones.md`, `./DESIGN.md` y `./INDEX.md`. Prevalece SPEC → HU → WF.

## 0. Instrucciones para el agente

Genera un wireframe navegable para el **backoffice de promociones**.

Reglas:

- No mezclar Promociones con la gestión de precios.
- No agregar carga masiva, programación ni histórico de precios.
- No crear una pantalla administrativa «Evaluar compra».
- Tipo de descuento: porcentaje o monto fijo.
- Modalidad: automática o mediante cupón.
- Mostrar alcance, vigencia, prioridad, canales y combinabilidad.
- La política de combinación parte con todas las combinaciones deshabilitadas.
- Evitar lenguaje técnico visible como nombres de servicios, eventos, scopes o DTO.
- «Oferta de Pricing» se representa al usuario como **oferta vigente del producto**.
- No exponer códigos internos en la interfaz.
- Escala de grises, sin sombras, conforme a DESIGN.md.

## 1. Metadatos

| Campo | Valor |
|---|---|
| ID | WF-006 |
| Nombre | Gestión de ofertas y promociones |
| Versión | 0.5 |
| Estado | Alineado |
| Responsable | Axel Andree Cueva Alcalá |
| Última actualización | 2026-09-28 |

## 2. Trazabilidad

| Fuente | Aporte |
|---|---|
| SPEC-006 | Administración, evaluación y combinación |
| HU-006 | CA-01 a CA-17 |
| DESIGN.md | Diseño |
| OpenAPI `0.3.5-p0` | CRUD/evaluación HTTP vigentes |

## 3. Funcionalidades incluidas

- Listar, buscar y filtrar.
- Crear.
- Editar.
- Ver detalle.
- Activar/desactivar.
- Configurar:
  - modalidad;
  - tipo/valor;
  - estado;
  - vigencia;
  - prioridad;
  - canales;
  - política de combinación;
  - alcance por producto/SKU.

## 4. Fuera de alcance

- Códigos/usos de cupón.
- Precios base y oferta maestra.
- Programación/importación/histórico de Pricing.
- Combos.
- Stock.
- Checkout/pago/pedido.
- Simulador de evaluación administrativo.

## 5. Usuario

Gestor comercial autorizado.

La interfaz no debe mostrar nombres de permisos técnicos todavía no homologados.

## 6. Secuencia principal

### A — Listar

Mostrar:

- nombre;
- modalidad;
- descuento;
- vigencia;
- alcance;
- canales;
- combinación;
- estado.

### B — Crear

1. Nombre.
2. Modalidad.
3. Tipo de descuento.
4. Valor.
5. Estado inicial.
6. Inicio/fin.
7. Prioridad.
8. Canales.
9. Alcance.
10. Compatibilidad con:
    - oferta vigente del producto;
    - otras promociones automáticas;
    - cupones.
11. Guardar.

### C — Editar

Cargar configuración vigente.

La modalidad se bloquea cuando la promoción:

- ya fue activada;
- tiene cupones asociados;
- tiene usos históricos.

El resto de los campos se valida según SPEC.

### D — Activar/desactivar

Confirmar cambio. Desactivar impide nuevas evaluaciones, pero no cambia pedidos históricos.

## 7. Alternativas

| ID | Condición | Comportamiento |
|---|---|---|
| ALT-01 | Porcentaje <=0 o >100 | Error |
| ALT-02 | Monto fijo <=0 | Error |
| ALT-03 | Fin <= inicio | Error |
| ALT-04 | Sin alcance | Error |
| ALT-05 | Prioridad inválida | Error |
| ALT-06 | Modalidad bloqueada | Explicación + crear nueva promoción |
| ALT-07 | Error de guardado | Conservar formulario |
| ALT-08 | Sin permisos | Bloquear acciones |
| ALT-09 | Sesión expirada | Reingreso |

## 8. Pantallas

| ID | Pantalla |
|---|---|
| S-01 | Listado |
| S-01-E | Vacío/sin resultados/error |
| S-02 | Crear/Editar |
| S-02-V | Validación |
| S-03 | Detalle |
| S-04 | Confirmar cambio de estado |

## 9. Especificación de S-01

### Filtros

- búsqueda;
- estado;
- tipo de descuento;
- modalidad.

### Tabla

- promoción;
- descuento;
- modalidad;
- combinabilidad;
- canales;
- alcance;
- vigencia;
- estado;
- acción.

No mostrar endpoint, IDs técnicos o código de servicio.

## 10. Especificación de S-02

| Campo | Obligatorio | Regla |
|---|---:|---|
| Nombre | Sí | No vacío |
| Modalidad | Sí | Automática / Mediante cupón |
| Tipo | Sí | Porcentaje / Monto fijo |
| Valor | Sí | `(0,100]` o `>0` |
| Estado | Sí | Activa/Inactiva |
| Inicio | Sí | Fecha válida |
| Fin | Sí | > Inicio |
| Prioridad | Sí | Entero positivo |
| Canales | No | Vacío = todos |
| Alcance | Sí | Producto y/o SKU activo |
| Combinar con oferta vigente | Sí | Sí/No; default No |
| Combinar con otra promoción | Sí | Sí/No; default No |
| Combinar con cupón | Sí | Sí/No; default No |

### Alcance

El producto completo selecciona sus SKUs vendibles activos. Los SKUs específicos pueden seleccionarse individualmente.

No duplicar visualmente una misma unidad elegible cuando un producto completo ya la cubre.

### Modalidad

Copy cuando esté bloqueada:

> La modalidad ya no puede cambiarse para esta promoción. Para usar otra modalidad, crea una nueva promoción.

## 11. S-03 — Detalle

Mostrar:

- resumen;
- estado;
- modalidad;
- tipo/valor;
- vigencia;
- prioridad;
- canales;
- alcance;
- combinabilidad.

La política se presenta con lenguaje de negocio:

```text
Puede combinarse con oferta vigente del producto
Puede combinarse con otras promociones
Puede combinarse con cupón
```

No mostrar «Pricing» como etiqueta al usuario.

## 12. S-04 — Estado

### Desactivar

> Dejará de participar en nuevas evaluaciones. Los pedidos ya confirmados conservan el beneficio registrado.

### Activar

> Participará cuando esté vigente y corresponda al canal y alcance configurados.

## 13. Estados de interfaz

- cargando;
- datos;
- vacío;
- sin resultados;
- validación;
- guardando;
- éxito;
- error;
- sin permisos;
- sesión expirada.

## 14. Responsividad

- escritorio: tabla + formulario 2 columnas;
- tablet: 2 columnas adaptadas;
- móvil: tarjetas + formulario 1 columna;
- 320 px sin overflow del body;
- 44 px mínimo por control.

## 15. Accesibilidad

- H1 único.
- Labels persistentes.
- Radios/checkboxes con fieldset/legend.
- Errores asociados.
- `aria-live` para resultado.
- Foco contenido en diálogo.
- No depender del color.

## 16. Microcopy

| Contexto | Texto |
|---|---|
| CTA | `Crear promoción` |
| monto fijo | `Se aplica una vez al subtotal elegible.` |
| sin combinación | `Esta promoción se aplicará de forma exclusiva.` |
| combinación | `Puede combinarse con los beneficios seleccionados.` |
| modalidad cupón | `Se aplica cuando se presenta un cupón válido asociado.` |

## 17. Contratos técnicos

### OpenAPI

```text
GET  /api/v1/promociones
GET  /api/v1/promociones/administracion
POST /api/v1/promociones
GET  /api/v1/promociones/{promocionId}
PATCH /api/v1/promociones/{promocionId}
POST /api/v1/promociones/{promocionId}/activar
POST /api/v1/promociones/{promocionId}/desactivar
POST /api/v1/promociones/evaluar
```

La UI administrativa no simula `/evaluar`.

### Seguridad

La UI interpreta:

```text
401 -> sesión/token no válido
403 -> acceso insuficiente
```

sin mostrar los códigos internos al usuario.

## 19. Criterios del wireframe

- [x] Administración CRUD lógico.
- [x] Modalidad.
- [x] Descuento.
- [x] Vigencia.
- [x] Alcance.
- [x] Prioridad.
- [x] Canales.
- [x] Combinabilidad.
- [x] Estado.
- [x] Sin simulador de evaluación.
- [x] Sin carga/histórico/programación de Pricing.
- [x] Diseño responsive y accesible.

## 20. Registro de revisión

| Versión | Fecha | Cambio |
|---|---|---|
| 0.5 | 2026-09-28 | Actualización de la referencia contractual vigente a OpenAPI 0.3.5-p0, sin cambios funcionales en el flujo. |
| 0.4 | 2026-09-28 | Eliminación de contenido ajeno de Pricing y alineación integral con SPEC/HU/OpenAPI de Promociones. |
