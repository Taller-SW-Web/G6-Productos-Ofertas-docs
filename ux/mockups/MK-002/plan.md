# Plan de Mockup — MK-002

> **Propósito y rol documental:**  
> Define la estrategia de ejecución de MK-002: cómo debe construirse la funcionalidad, en qué orden, bajo qué restricciones y mediante qué Quality Gates.
>
> Puede ser seguido por un desarrollador o agente de forma determinista.
>
> No redefine el contenido detallado de las pantallas, especificado en `component-spec.md`, ni redefine la UX transversal del módulo.

---

## 1. Identificación

- **Mockup:** MK-002
- **Funcionalidad:** Gestión de combos de productos
- **Responsable:** Marco Renato Castilla Huanca
- **Versión:** v0.1
- **Estado:** Borrador
- **Rama funcional:** `castilla`
- **Component Spec:** `component-spec.md`
- **Design System consumido:** `mockups/DESIGN.md` v1.0.0
- **UX transversal consumida:** v2.0
- **Contrato HTTP consumido:** OpenAPI 0.5.0

---

## 2. Contrato de ejecución

### Entradas

Antes y durante la ejecución deben consultarse obligatoriamente:

- `component-spec.md`.
- `mockups/ux/ux-guidelines.md`.
- `mockups/ux/ux-decisions.md`.
- `mockups/ux/propuesta-ux.md`.
- `specs/SPEC-002-gestion-combos-productos.md`.
- `hu/HU-002-gestion-combos-productos.md`.
- `wireframes/flows/WF-002-gestion-combos-productos.md`.
- `flujos/FLOW-002-gestion-combos-productos.md`.
- `api/openapi.yaml`.
- `Contrato_Api.md`.
- `api/kit-integracion.md`.
- `mockups/DESIGN.md`.
- `mockups/prototipo/README.md`.

El `component-spec.md` define el resultado concreto de MK-002.

Las fuentes funcionales y contractuales superiores prevalecen ante contradicción.

---

### Salidas esperadas

Al finalizar la ejecución deben existir:

- MK-002-S01 — Gestión de combos.
- MK-002-S02 — Crear o editar combo.
- MK-002-S03 — Detalle del combo.
- MK-002-S04 — Combo no disponible.

Rutas directas:

```text
/MK002/S01
/MK002/S02
/MK002/S03
/MK002/S04
```

Además:

- fixtures deterministas para todos los estados P0;
- navegación coherente con FLOW-002;
- componentes específicos contenidos bajo MK-002;
- reutilización del Design System;
- estados loading/error/empty/default verificables;
- selector producto → SKU funcional;
- comparación económica reproducible;
- autovalidación documentada;
- revisión transversal cerrada;
- versión aprobada trasladada posteriormente a Figma.

El código específico debe permanecer bajo:

```text
mockups/prototipo/src/pantallas/MK002/
```

salvo componentes compartidos ya existentes en la baseline común.

---

### Restricciones de ejecución

Durante MK-002 queda prohibido:

- modificar silenciosamente SPEC, HU, WF, FLOW, OpenAPI o Design System;
- inventar reglas comerciales;
- inventar endpoint global `/skus`;
- inventar búsqueda de combos si OpenAPI no la publica;
- inventar combos anidados;
- permitir SKU duplicado;
- seleccionar automáticamente una variante arbitraria;
- tratar `variant_id` como SKU;
- editar Pricing desde Combos;
- editar Inventario desde Combos;
- reservar stock desde administración;
- representar disponibilidad como garantía;
- convertir disponibilidad `null` en cero;
- convertir disponibilidad cero en `INACTIVO`;
- incorporar Checkout;
- incorporar carrito/pedido/pago;
- incorporar gestión de cupón o promoción;
- mostrar un campo `estado` en creación;
- introducir `Reactivar combo`;
- introducir canal editable en el formulario;
- introducir consulta histórica de Pricing;
- presentar comparación frontend como validación definitiva;
- borrar el formulario ante `COMBO_PRECIO_INVALIDO`;
- sobrescribir silenciosamente un `VERSION_CONFLICT`;
- afirmar qué SKU causó una no elegibilidad sin una fuente contractual;
- introducir dependencias externas exclusivamente para MK-002;
- crear un tema, router o infraestructura paralela por funcionalidad;
- modificar otros MK.

---

### Regla temporal de Pricing para MK-002

Hasta que la documentación contractual superior formalice explícitamente la regla, la construcción aplica el supuesto documentado A-06 del `component-spec.md`:

```text
Precio efectivo vigente de alcance global
canal omitido
channel_id = null
```

Para cada SKU:

```text
precio público vigente
=
precio_oferta vigente, si existe
o
precio_regular
```

La implementación del mockup debe mantener esta regla encapsulada en fixtures/utilidades de MK-002 y no dispersarla por múltiples componentes.

Una formalización futura diferente obliga a revisar el cálculo, pero no justifica inventar alternativas durante esta ejecución.

---

### Condiciones de parada / escalamiento

Marcar la tarea correspondiente como `BLOCKED` cuando:

1. una capacidad necesaria contradiga SPEC/HU/FLOW/OpenAPI;
2. implementar exija inventar un endpoint;
3. Catálogo no permita resolver un SKU vendible de forma verificable;
4. Pricing no permita representar una referencia requerida;
5. se necesite inventar el motivo específico de no elegibilidad;
6. la baseline común del prototipo no esté disponible y continuar implique crear infraestructura propia;
7. un componente del Design System sea insuficiente y resolverlo implique crear un nuevo patrón transversal;
8. sea necesaria una dependencia no aprobada;
9. un fixture requiera estados o propiedades inexistentes;
10. un Quality Gate no pueda demostrarse objetivamente.

Un bloqueo en una parte no autoriza a reinterpretar el contrato.

---

## 3. Entradas obligatorias

| Entrada | Referencia | Estado requerido |
|---|---|---|
| Propuesta UX módulo | `mockups/ux/propuesta-ux.md` | Vigente |
| UX Decisions | `mockups/ux/ux-decisions.md` | Vigente |
| UX Guidelines | `mockups/ux/ux-guidelines.md` | Vigente |
| Component Spec | `component-spec.md` | Aprobado antes de implementar |
| SPEC | SPEC-002 | Vigente |
| HU | HU-002 | Vigente |
| WF | WF-002 | Vigente |
| FLOW | FLOW-002 | Vigente |
| OpenAPI | 0.5.0 | Vigente |
| Design System | `mockups/DESIGN.md` v1.0.0 | Vigente |
| Baseline prototipo | React + TypeScript + Mantine + routing + tema compartido | Disponible antes de código |

### Gate 0 — Ready for Implementation

Antes de escribir código deben cumplirse:

- `component-spec.md` aprobado;
- sin preguntas abiertas bloqueantes;
- LUX-01 a LUX-05 aceptadas;
- supuesto A-06 explícitamente conocido;
- selector producto → SKU definido;
- S04 no inventa causa de indisponibilidad;
- OpenAPI 0.5.0 confirmado;
- baseline transversal disponible.

Si solo falta la baseline común:

```text
DOCUMENTACIÓN LISTA
IMPLEMENTACIÓN BLOCKED
```

---

## 4. Objetivo

Construir un prototipo desktop reproducible de la gestión administrativa de combos que permita demostrar:

1. consulta de combos;
2. selección de componentes a nivel de SKU vendible;
3. resolución explícita de variante cuando corresponda;
4. validación estructural de composición;
5. consulta y comparación de precios;
6. creación y edición;
7. conflicto de versión;
8. disponibilidad informativa;
9. desactivación administrativa;
10. estado de no disponibilidad sin inventar causa o rollback.

El resultado debe poder inspeccionarse mediante rutas directas y fixtures sin backend real.

---

## 5. Pantallas

El orden de implementación no coincide con el orden habitual de navegación.

| ID | Nombre | Prioridad | Orden |
|---|---|---:|---:|
| MK-002-S02 | Crear o editar combo | P0 | 1 |
| MK-002-S03 | Detalle del combo | P0 | 2 |
| MK-002-S04 | Combo no disponible | P0 | 3 |
| MK-002-S01 | Gestión de combos | P0 | 4 |

### Justificación

S02 concentra:

- búsqueda de productos;
- resolución de SKU;
- variantes;
- composición;
- cantidades;
- Pricing;
- comparación económica;
- errores;
- creación;
- edición;
- concurrencia.

S03 reutiliza composición, precios y disponibilidad.

S04 reutiliza identidad, estado y disponibilidad, pero obliga a separar correctamente `INACTIVO`, agotamiento y dato desconocido.

S01 reutiliza los patrones ya estabilizados para producir una vista administrativa resumida.

---

## 6. Pantalla ancla

- **Pantalla:** MK-002-S02 — Crear o editar combo.

### Motivo

Es el punto donde coinciden prácticamente todas las reglas relevantes de MK-002.

Una implementación incorrecta puede provocar que el prototipo:

- seleccione productos en lugar de SKUs;
- seleccione automáticamente variantes;
- acepte duplicados;
- valide precios con referencias equivocadas;
- invente canal;
- invente disponibilidad garantizada;
- pierda datos ante rechazo;
- ignore conflictos de versión.

### Qué debe establecer

S02 fija:

- patrón producto → SKU;
- tratamiento de productos con variantes;
- tabla editable de componentes;
- cantidades;
- comparación económica;
- feedback de Pricing;
- errores de composición;
- errores de servidor;
- comportamiento ante conflicto;
- preservación de datos;
- jerarquía de acciones;
- copy principal de MK-002.

La pantalla ancla aplica la UX global; no crea una UX independiente.

---

## 7. Estrategia

### Fase 0 — Cerrar contrato del mockup

Antes de implementación:

1. aprobar `component-spec.md`;
2. confirmar LUX-01 a LUX-05;
3. confirmar OpenAPI 0.5.0;
4. registrar A-06;
5. confirmar las cuatro rutas;
6. revisar que no exista pregunta bloqueante.

**Salida:** MK-002 listo documentalmente.

---

### Fase 1 — Verificar baseline transversal

Comprobar disponibilidad de:

- React;
- TypeScript;
- Mantine;
- Tabler Icons;
- router;
- tema común;
- componentes compartidos;
- estructura base del prototipo.

No instalar infraestructura particular de MK-002.

Si no existe:

```text
BLOCKED — baseline transversal no disponible
```

---

### Fase 2 — Preparar fixtures contract-first

Crear antes de las pantallas.

Grupos mínimos:

```text
list-*
catalog-*
create-*
edit-*
pricing-*
detail-*
availability-*
deactivate-*
unavailable-*
```

Todos deben:

- ser deterministas;
- usar datos ficticios;
- no usar red;
- no usar aleatoriedad;
- respetar schemas;
- poder abrirse directamente;
- diferenciar cero/null/error.

---

### Fase 3 — Construir resolución producto → SKU

Antes del formulario completo, implementar el mecanismo conceptual de selección.

#### Producto simple

```text
GET /productos?q=...
↓
tiene_variantes = false
↓
sku_base
```

#### Producto con variantes

```text
GET /productos?q=...
↓
tiene_variantes = true
↓
GET /productos/{productoId}
↓
variants[].sku
↓
elección explícita
```

### Validaciones

- no seleccionar producto padre con variantes como componente;
- no usar `variant_id`;
- no inventar `/skus`;
- no repetir SKU ya añadido;
- no introducir combo como candidato.

### Gate A1

No continuar a Pricing hasta que el selector produzca exclusivamente identidades SKU válidas.

---

### Fase 4 — Construir composición del combo

Implementar MK-002-C01 y MK-002-C04.

Resolver:

- añadir SKU;
- quitar SKU;
- cantidad;
- duplicado;
- mínimo dos componentes;
- producto simple;
- variante seleccionada;
- loading/error de Catálogo.

El estado del formulario debe mantenerse aunque falle una nueva consulta de Catálogo.

---

### Fase 5 — Implementar Pricing y comparador económico

Construir MK-002-C02.

Para cada SKU seleccionado, preparar:

```text
precio_regular
precio_oferta
currency
channel_id
```

Con la regla A-06:

```text
scope = global
canal omitido
```

Calcular:

```text
sumaRegular =
Σ(precio_regular × cantidad)
```

y:

```text
precioPublico =
precio_oferta ?? precio_regular

sumaPublicaVigente =
Σ(precioPublico × cantidad)
```

Luego comparar:

```text
precioCombo > 0
precioCombo < sumaRegular
precioCombo < sumaPublicaVigente
```

### Restricción

El frontend puede detectar anticipadamente una infracción, pero no convierte el resultado local en confirmación definitiva.

### Gate A2

Probar obligatoriamente:

- sin oferta;
- con oferta;
- falla suma regular;
- falla suma pública;
- Pricing no disponible;
- precio faltante;
- cambio de cantidad recalcula;
- quitar componente recalcula.

---

### Fase 6 — Completar creación

Construir modo:

```text
/MK002/S02?modo=crear
```

Campos:

- nombre;
- descripción;
- componentes;
- precio.

No añadir:

```text
estado
canal
vigencia
cupón
promoción
stock
```

Implementar:

- `Crear combo`;
- loading localizado;
- resultado confirmado;
- `COMBO_PRECIO_INVALIDO`;
- error general.

### Gate A3

Un rechazo backend debe conservar completamente el formulario.

---

### Fase 7 — Completar edición y concurrencia

Construir modo:

```text
/MK002/S02?modo=editar
```

Preservar `version` de la lectura.

Implementar `VERSION_CONFLICT`.

Ante conflicto:

1. no sobrescribir;
2. conservar propuesta local;
3. informar que existe versión nueva;
4. ofrecer consulta segura de versión actual.

No implementar “Forzar guardado” si el contrato no lo publica.

### Gate A4

El fixture de conflicto debe demostrar que la propuesta del usuario no desaparece.

---

### Fase 8 — Implementar S03 detalle

Reutilizar:

- tabla de componentes;
- precios;
- badges;
- disponibilidad;
- comparador en modo lectura.

Estados mínimos:

```text
detail-active
detail-active-zero
detail-stale
detail-incomplete
detail-unverifiable
detail-inactive
```

### Acciones

ACTIVO:

```text
Editar
Desactivar
```

INACTIVO:

```text
Editar
```

No Reactivar.

---

### Fase 9 — Implementar desactivación

Añadir modal de confirmación.

Debe comunicar:

```text
qué combo
qué ocurrirá
qué se conserva
```

Ejemplo conceptual:

```text
El combo dejará de ofrecerse para nuevas ventas.
Su configuración administrativa se conservará.
```

Respuesta HTTP confirmada:

```text
200
```

No introducir:

```text
QUEUED
PROCESSING
```

porque la operación es síncrona.

---

### Fase 10 — Implementar S04 no disponible

Separar tres categorías:

#### Agotado

```text
status = ACTIVO
cantidadInformativa = 0
```

Resultado:

```text
Activo
Agotado actualmente
```

#### Inactivo

```text
status = INACTIVO
```

Resultado:

```text
No disponible para nuevas ventas
```

#### Desconocido/incompleto

```text
verificable = false
o
cantidadInformativa = null
o
estadoActualizacion = INCOMPLETA
```

Resultado:

```text
No se puede confirmar la disponibilidad actual
```

### Gate A5

Nunca deben colapsarse estos tres casos en un mismo significado.

---

### Fase 11 — Implementar S01 listado

Construir al final porque reutiliza patrones ya resueltos.

Incluir:

- CTA crear;
- filtro ACTIVO/INACTIVO;
- tabla;
- paginación;
- detalle;
- edición;
- desactivación cuando corresponda.

No incorporar búsqueda de combos.

### Estados

```text
list-default
list-loading
list-empty
list-error
```

---

### Fase 12 — Navegación integral

Conectar:

```text
S01 → S02 crear
S01 → S03
S01 → S02 editar
S03 → S02 editar
S03 → S01 después de desactivar
S03 → S04 cuando corresponde
S04 → S03
S04 → S01
```

Todas las pantallas deben seguir accesibles directamente.

---

### Fase 13 — Reproducción determinista

Permitir inspeccionar estados sin editar código.

Ejemplos conceptuales:

```text
/MK002/S02?estado=price-invalid-public
/MK002/S02?estado=version-conflict
/MK002/S03?estado=active-zero
/MK002/S04?estado=inactive
/MK002/S01?estado=empty
```

La sintaxis exacta no se impone.

La capacidad de reproducción sí es obligatoria.

---

### Fase 14 — Normalización

Revisar:

- componentes;
- tokens;
- estilos;
- imports;
- copy;
- duplicación;
- accesibilidad;
- iconografía;
- estructura.

Eliminar:

- valores visuales arbitrarios;
- términos técnicos innecesarios;
- componentes ad hoc equivalentes a componentes DS;
- lógica de A-06 duplicada por pantalla.

---

### Fase 15 — Accesibilidad

Validar:

- teclado;
- foco visible;
- modal accesible;
- retorno de foco;
- labels;
- errores asociados;
- estados sin depender de color;
- tablas semánticas;
- botones solo-icono nombrados;
- contenido largo;
- texto aumentado;
- ausencia de trampas de teclado.

---

### Fase 16 — Autovalidación y revisión

Orden:

```text
Implementación
↓
Autovalidación Marco
↓
Correcciones
↓
Cero hallazgos bloqueantes/importantes
↓
Revisión transversal Vera
↓
Correcciones
↓
APROBADO PARA FIGMA
↓
Figma
↓
Validación de fidelidad
↓
APROBADO
```

---

## 8. Reutilización

| Componente | Origen | Pantallas | Acción |
|---|---|---|---|
| `PO/Button` DS-C01 | Design System | S01-S04 | Reutilizar |
| `PO/ActionIcon` DS-C02 | Design System | S01-S03 | Reutilizar cuando corresponda |
| `PO/TextInput` DS-C03 | Design System | S02 | Reutilizar |
| `PO/NumberInput` DS-C04 | Design System | S02 | Reutilizar |
| `PO/Textarea` DS-C05 | Design System | S02 | Reutilizar |
| `PO/Select` DS-C06 | Design System | S02 | Reutilizar |
| `PO/Search` DS-C12 | Design System | S02 | Reutilizar para producto |
| `PO/FilterBar` DS-C13 | Design System | S01 | Reutilizar |
| `PO/Badge` DS-C14 | Design System | S01-S04 | Reutilizar |
| `PO/Table` DS-C17 | Design System | S01-S03 | Reutilizar |
| `PO/Pagination` DS-C18 | Design System | S01 | Reutilizar |
| `PO/Card` DS-C19 | Design System | S02-S04 | Reutilizar |
| `PO/Modal` DS-C21 | Design System | S03 | Reutilizar |
| `PO/Alert / PO/Result` DS-C22 | Design System | S02-S04 | Reutilizar |
| `PO/Skeleton / PO/Loader` DS-C24 | Design System | S01-S03 | Reutilizar |
| `PO/EmptyState` DS-C25 | Design System | S01-S02 | Reutilizar |
| `PO/Breadcrumbs` DS-C28 | Design System | S01-S04 | Reutilizar |
| MK-002-C01 Selector SKU | MK-002 | S02 | Construir específico |
| MK-002-C02 Comparador económico | MK-002 | S02-S03 | Construir y reutilizar localmente |
| MK-002-C03 Disponibilidad informativa | MK-002 | S01-S04 | Construir y reutilizar localmente |
| MK-002-C04 Tabla de componentes | MK-002 | S02-S03 | Construir y reutilizar localmente |

### Regla de promoción

Un componente específico no se mueve automáticamente a shared.

Solo promover si:

- tiene semántica transversal;
- no incorpora reglas de MK-002;
- existe otra funcionalidad que realmente lo necesita;
- se coordina con la arquitectura común.

---

## 9. Normalización

La implementación final debe alinearse a:

- React.
- TypeScript.
- Mantine.
- tema central.
- Tabler Icons.
- Design System 1.0.0.
- UX transversal 2.0.
- desktop 1440 px.

### Estructura

El código específico debe concentrarse bajo:

```text
mockups/prototipo/src/pantallas/MK002/
```

Puede organizarse conceptualmente como:

```text
MK002/
├── componentes/
├── fixtures/
├── pantallas/
└── utilidades/
```

siempre que:

- no duplique componentes shared;
- no cree infraestructura propia;
- no exponga utilidades funcionales fuera de MK-002 sin coordinación.

### Regla especial del cálculo económico

La resolución de:

```text
precio público vigente
```

debe implementarse en un único lugar reutilizable dentro de MK-002.

No repetir:

```text
precio_oferta ?? precio_regular
```

en cada pantalla.

Esto facilita reemplazar A-06 cuando se formalice la regla contractual.

---

## 10. Estados

| Estado | Pantalla | Prioridad | Fixture | Evidencia esperada |
|---|---|---:|---|---|
| Lista normal | S01 | P0 | `list-default` | Combos con estados diversos |
| Loading lista | S01 | P0 | `list-loading` | Skeleton |
| Sin combos | S01 | P0 | `list-empty` | EmptyState |
| Error lista | S01 | P0 | `list-error` | Error accionable |
| Crear vacío | S02 | P0 | `create-empty` | Formulario inicial |
| Producto simple | S02 | P0 | `create-simple-product` | `sku_base` resoluble |
| Producto con variantes | S02 | P0 | `create-variant-product` | Selección explícita |
| Variante elegida | S02 | P0 | `create-variant-selected` | `variants[].sku` |
| Solo 1 componente | S02 | P0 | `create-one-component` | Error mínimo 2 |
| 2 componentes válidos | S02 | P0 | `create-valid-two-components` | Composición válida |
| Duplicado | S02 | P0 | `create-duplicate` | Error localizado |
| Precio válido | S02 | P0 | `create-price-valid` | Cumple ambas |
| Precio inválido regular | S02 | P0 | `create-price-invalid-regular` | Error comparación |
| Precio inválido público | S02 | P0 | `create-price-invalid-public` | Error comparación |
| Pricing no disponible | S02 | P0 | `create-pricing-unavailable` | Sin cifra ficticia |
| Rechazo servidor | S02 | P0 | `create-server-price-rejected` | Datos conservados |
| Edición | S02 | P0 | `edit-default` | Datos cargados |
| Conflicto | S02 | P0 | `edit-version-conflict` | Propuesta conservada |
| Activo disponible | S03 | P0 | `detail-active` | Estado + disponibilidad |
| Activo agotado | S03 | P0 | `detail-active-zero` | ACTIVO + 0 |
| Desactualizado | S03 | P0 | `detail-stale` | Warning |
| Incompleto | S03 | P0 | `detail-incomplete` | No afirmar cantidad |
| No verificable | S03 | P0 | `detail-unverifiable` | No convertir a cero |
| Inactivo | S03 | P0 | `detail-inactive` | Sin Reactivar |
| Confirmación baja | S03 | P0 | `deactivate-confirm` | Modal |
| Agotado | S04 | P0 | `unavailable-zero-stock` | No cambia status |
| Inactivo | S04 | P0 | `unavailable-inactive` | Causa genérica |
| Desconocido | S04 | P0 | `unavailable-unknown` | No inventa stock |

---

## 11. Orden de ejecución

| Fase | Salida | Actor / Revisor | Gate |
|---|---|---|---|
| Preparación | Fuentes y component-spec cerrados | Marco | Gate 0 |
| Baseline | Entorno común disponible | Marco / responsable técnico | Infraestructura |
| Fixtures | Dataset determinista | Marco | Contrato |
| Selector SKU | Producto → SKU resuelto | Marco | Gate A1 |
| Pricing | Comparación económica | Marco | Gate A2 |
| S02 creación | Alta completa | Marco | Gate A3 |
| S02 edición | Concurrencia resuelta | Marco | Gate A4 |
| S03 | Detalle completo | Marco | Gate A |
| Desactivación | Confirmación síncrona | Marco | Gate A |
| S04 | Indisponibilidad correcta | Marco | Gate A5 |
| S01 | Gestión/listado | Marco | Gate A |
| Navegación | Flow completo | Marco | Gate A6 |
| Normalización | Código/DS coherente | Marco | Gate C |
| Estados + A11y | Matriz P0 | Marco | Gate D |
| Autovalidación | Evidencias | Marco | Gate E0 |
| Revisión transversal | Observaciones | Leonardo Vera Rodríguez | Gate E |
| Correcciones | Hallazgos cerrados | Marco | Gate E |
| Aprobación Figma | Visto bueno | Leonardo Vera Rodríguez | Gate E |
| Figma | Frames sincronizados | Marco | Gate F |
| Cierre | Validation Report APROBADO | Marco | Todos |

---

## 12. Riesgos

| ID | Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|---|
| R-01 | Confundir producto con SKU vendible | Alta | Alto | Resolver producto → SKU antes de construir formulario |
| R-02 | Seleccionar automáticamente una variante | Media | Alto | Exigir elección explícita |
| R-03 | Inventar endpoint `/skus` | Media | Alto | Usar únicamente Catálogo publicado |
| R-04 | SKU duplicado en composición | Media | Alto | Validación local + fixture |
| R-05 | Usar `precio_regular` como única referencia | Media | Alto | Comparador con ambas sumas |
| R-06 | Interpretar mal precio público vigente | Media | Alto | Centralizar regla A-06 |
| R-07 | Formalización futura cambia A-06 | Media | Medio | Encapsular cálculo y fixtures |
| R-08 | Pricing falla y UI muestra cero | Media | Alto | Estado no verificable, nunca cero ficticio |
| R-09 | Comparación frontend parece validación definitiva | Media | Alto | Copy preventivo + backend autoritativo |
| R-10 | Rechazo borra formulario | Media | Alto | Estado del formulario persistente |
| R-11 | VERSION_CONFLICT sobrescribe cambios | Media | Alto | Conservar propuesta y consultar versión |
| R-12 | Disponibilidad 0 se convierte en INACTIVO | Alta | Alto | LUX-03 + fixture específico |
| R-13 | `null` se convierte en agotado | Media | Alto | Estados separados |
| R-14 | Se muestra SKU causante sin evidencia | Media | Medio | Mensaje genérico |
| R-15 | Se introduce Reactivar por simetría | Media | Medio | Prohibición contractual |
| R-16 | Desactivación se trata como operación async | Baja | Medio | Respetar respuesta 200 síncrona |
| R-17 | Selector se vuelve demasiado complejo | Media | Medio | Búsqueda de producto + elección de variante en segundo nivel |
| R-18 | Comparador ocupa demasiado espacio | Media | Medio | Card persistente según Design System |
| R-19 | Baseline común inexistente | Media | Alto | Bloquear; no crear aplicación paralela |
| R-20 | Dependencia externa se añade por comodidad | Media | Medio | Reutilizar Mantine/DS existente |

---

## 13. Quality Gates

### Gate A — Funcional

Debe cumplirse:

- SPEC-002 cubierto.
- HU-002 cubierto.
- WF-002 cubierto.
- FLOW-002 cubierto.
- OpenAPI 0.5.0 respetado.
- Sin capacidades inventadas.
- Cuatro rutas directas disponibles.
- Estados P0 reproducibles.

#### Gate A1 — Identidad SKU

- producto simple → `sku_base`;
- producto con variantes → selección explícita;
- no `variant_id`;
- no duplicados;
- no `/skus` ficticio;
- no combo anidado.

#### Gate A2 — Comparación económica

Debe demostrarse:

```text
sumaRegular
sumaPublicaVigente
precioCombo
```

y:

```text
precioCombo > 0
precioCombo < sumaRegular
precioCombo < sumaPublicaVigente
```

Además:

- oferta vigente aplicada cuando corresponda;
- regular como fallback;
- alcance Pricing global según A-06;
- fallo Pricing no produce cifra inventada.

#### Gate A3 — Creación

- formulario completo;
- sin campo estado;
- sin canal;
- sin stock editable;
- rechazo conserva datos;
- éxito solo tras respuesta confirmada.

#### Gate A4 — Edición

- `version` preservada;
- `VERSION_CONFLICT` visible;
- propuesta local conservada;
- sin sobrescritura silenciosa.

#### Gate A5 — Disponibilidad

Distinguir obligatoriamente:

```text
ACTIVO + disponible
ACTIVO + agotado
INACTIVO
DESACTUALIZADA
INCOMPLETA
NO VERIFICABLE
ERROR DE CONSULTA
```

#### Gate A6 — Navegación

Verificar:

```text
S01 → S02
S01 → S03
S03 → S02
S03 → S04
S04 → S03
S04 → S01
```

y rutas directas.

---

### Gate B — UX

Debe comprobarse:

- UX-P01 aplicada cuando corresponda.
- UX-P02 aplicada a progresive disclosure producto → SKU.
- UX-P03 aplicada a conservación/recuperación.
- errores junto a su punto de resolución;
- datos ingresados preservados;
- estados de disponibilidad diferenciados;
- decisiones LUX-01 a LUX-05 respetadas;
- ningún patrón UX transversal nuevo sin registrar.

---

### Gate C — UI

- Design System 1.0.0 respetado.
- Componentes DS reutilizados.
- Sin colores arbitrarios.
- Sin spacing arbitrario.
- Sin tipografías propias.
- Sin sombras decorativas no permitidas.
- Tabler Icons.
- Componentes específicos confinados a MK-002.
- Sin dependencia nueva innecesaria.

---

### Gate D — PC y accesibilidad

- viewport 1440 px;
- sin overflow horizontal de página;
- selector producto/SKU operable con teclado;
- modal accesible;
- foco visible;
- retorno de foco;
- errores asociados a controles;
- estados no dependen del color;
- precios legibles;
- texto aumentado no oculta acciones;
- tabla semántica;
- sin trampas de teclado.

---

### Gate E — Revisión Transversal y Aprobación para Figma

- **Revisor:** Leonardo Vera Rodríguez.
- Autovalidación cerrada.
- Cero bloqueantes abiertos.
- Cero hallazgos importantes requeridos abiertos.
- Correcciones reinspeccionadas.
- Visto bueno formal.

Estado final:

```text
APROBADO PARA FIGMA
```

---

### Gate F — Figma y cierre

- Solo trasladar la versión aprobada.
- Cuatro pantallas P0 presentes.
- S02 reproduce creación/edición.
- Estados críticos representados.
- Mismos componentes/tokens.
- Mismo copy.
- Mismos fixtures representativos.
- Mismas acciones.
- Fidelidad verificada.
- Enlace Figma registrado.

### Regla de cierre

Cuando Gate E y F estén completos y no existan hallazgos requeridos abiertos:

```text
validation-report.md
Resultado general = APROBADO
```
