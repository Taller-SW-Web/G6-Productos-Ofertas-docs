# Plan de Mockup — MK-001

> **Propósito y rol documental:**  
> Este documento define la estrategia de ejecución de MK-001: cómo debe construirse, en qué orden, bajo qué restricciones y mediante qué Quality Gates.
>
> No redefine qué debe contener cada pantalla. Esa responsabilidad corresponde a `component-spec.md`.
>
> La ejecución está subordinada a SPEC, HU, WF, FLOW, contratos vigentes, UX transversal y Design System.

---

## 1. Identificación

- **Mockup:** MK-001
- **Funcionalidad:** Carga y exportación masiva de productos
- **Responsable:** Marco Renato Castilla Huanca
- **Rama funcional:** `castilla`
- **Versión:** v0.1
- **Estado:** Borrador
- **Component Spec de referencia:** `mockups/MK-001/component-spec.md`
- **Design System consumido:** `mockups/DESIGN.md` v1.0.0
- **UX transversal consumida:** v2.0
- **Contrato HTTP consumido:** OpenAPI 0.5.0

---

## 2. Contrato de ejecución

### 2.1. Entradas

La ejecución debe consultar obligatoriamente:

- `mockups/MK-001/component-spec.md`.
- `mockups/ux/propuesta-ux.md`.
- `mockups/ux/ux-decisions.md`.
- `mockups/ux/ux-guidelines.md`.
- `mockups/DESIGN.md`.
- `specs/SPEC-001-carga-exportacion-masiva-productos.md`.
- `hu/HU-001-carga-exportacion-masiva-productos.md`.
- `wireframes/flows/WF-001-carga-exportacion-masiva-productos.md`.
- `flujos/FLOW-001-carga-exportacion-masiva-productos.md`.
- `api/openapi.yaml`.
- `Contrato_Api.md`.
- `mockups/prototipo/README.md`.

El `component-spec.md` concentra la especificación concreta de pantallas, componentes específicos, estados, fixtures y decisiones `LUX-XX`; las fuentes superiores prevalecen si se detecta una contradicción.

---

### 2.2. Salidas esperadas

Al completar este plan deben existir:

- Las cinco pantallas P0 de MK-001:
  - MK-001-S01.
  - MK-001-S02.
  - MK-001-S03.
  - MK-001-S04.
  - MK-001-S05.
- Rutas directas:
  - `/MK001/S01`
  - `/MK001/S02`
  - `/MK001/S03`
  - `/MK001/S04`
  - `/MK001/S05`
- Navegación integral compatible con FLOW-001.
- Estados deterministas reproducibles mediante fixtures.
- Componentes específicos de MK-001 implementados sin duplicar componentes compartidos.
- Código contenido bajo:

```text
mockups/prototipo/src/pantallas/MK001/
```

- Uso del tema y componentes compartidos del prototipo.
- Autovalidación funcional, UX, UI, PC y accesibilidad registrada.
- `validation-report.md` completado hasta el punto correspondiente a la ejecución.
- Revisión transversal posterior de Leonardo Vera Rodríguez.
- Versión final aprobada para traslado a Figma.
- Correspondencia final entre prototipo aprobado y Figma.

---

### 2.3. Restricciones de ejecución

Durante la implementación queda prohibido:

- Modificar SPEC-001, HU-001, WF-001, FLOW-001, OpenAPI, UX transversal o Design System para acomodarlos al mockup.
- Inventar campos o controles ausentes del `component-spec.md`.
- Inventar un endpoint de prevalidación general de Catálogo.
- Presentar revisión local de archivo como validación completa de negocio.
- Mostrar `202 Accepted` como éxito terminal.
- Inventar estados backend como `COMPLETED_CON_ERRORES`.
- Inventar porcentajes de progreso, ETA o duración.
- Inventar rollback entre Catálogo, Pricing e Inventario.
- Reenviar automáticamente una escritura cuyo resultado sea desconocido.
- Implementar `Reintentar` como operación genérica.
- Reanudar mediante un lote nuevo cuando la operación corresponde al mismo `batch_id`.
- Añadir filtros a la exportación completa del catálogo.
- Añadir PDF como formato de exportación.
- Exponer nombres de eventos internos RabbitMQ.
- Exponer `message_id` u `operation_id` al Gestor Comercial como contenido principal.
- Crear selección múltiple o acciones masivas en la tabla de resultado.
- Crear mobile/tablet.
- Crear un Design System particular para MK-001.
- Agregar librerías o dependencias externas únicamente para resolver MK-001.
- Fijar una versión propia de React, Mantine, router u otra dependencia si la baseline transversal aún no está definida.
- Adoptar defaults visuales de Mantine que contradigan `DESIGN.md`.
- Introducir `@mantine/dropzone` u otra dependencia de carga por conveniencia si no forma parte del entorno común aprobado.

---

### 2.4. Condiciones de parada y escalamiento

Una tarea pasa a `BLOCKED` si ocurre cualquiera de estos casos:

1. El comportamiento necesario contradice SPEC/HU/FLOW/API.
2. El `component-spec.md` requiere una capacidad HTTP inexistente.
3. Se necesita decidir una regla comercial no documentada.
4. Se necesita introducir un nuevo patrón UX transversal.
5. Un componente requerido del Design System resulta ambiguo o incompatible.
6. El entorno común React/TypeScript/Mantine/routing todavía no está disponible y continuar implicaría crear infraestructura paralela.
7. Implementar una pantalla requiere modificar otro MK.
8. El prototipo exige añadir una dependencia no aprobada.
9. Un fixture necesita datos o estados que el contrato no permite afirmar.
10. No puede verificarse objetivamente un Quality Gate.

Un bloqueo local de una pantalla no autoriza a inventar la solución. Las demás tareas independientes pueden continuar únicamente si no dependen de la decisión bloqueada.

---

## 3. Entradas obligatorias y Gate 0

| Entrada | Referencia | Estado requerido antes de implementar |
|---|---|---|
| Propuesta UX | `mockups/ux/propuesta-ux.md` | Vigente |
| UX Decisions | `mockups/ux/ux-decisions.md` | Vigente |
| UX Guidelines | `mockups/ux/ux-guidelines.md` | Vigente |
| Design System | `mockups/DESIGN.md` v1.0.0 | Vigente |
| Component Spec | `mockups/MK-001/component-spec.md` | Aprobado |
| SPEC | SPEC-001 | Vigente |
| HU | HU-001 | Vigente |
| WF | WF-001 | Vigente |
| Flow | FLOW-001 | Vigente |
| HTTP | OpenAPI 0.5.0 | Vigente |
| Entorno del prototipo | Baseline común React + TypeScript + Mantine + routing | Disponible |

### Gate 0 — Ready for Implementation

Antes de implementar código deben cumplirse simultáneamente:

- `component-spec.md` en estado `Aprobado`.
- Sin preguntas abiertas bloqueantes.
- LUX-01, LUX-02 y LUX-03 aceptadas.
- Confirmado que S02 es una revisión preliminar local.
- Confirmado que S04-E es un estado de S04.
- Confirmado que no se implementará progreso ficticio.
- Confirmado que OpenAPI 0.5.0 es el contrato HTTP consumido.
- Baseline transversal del prototipo disponible.

Si falta únicamente infraestructura común del prototipo, MK-001 permanece listo documentalmente pero bloqueado técnicamente.

---

## 4. Objetivo

Construir un prototipo desktop completo y reproducible de la carga y exportación masiva de productos que permita demostrar:

1. selección y revisión preliminar del archivo;
2. admisión de la importación;
3. seguimiento asíncrono verificable;
4. resultado total o parcial por fila y dominio;
5. recuperación mediante reanudación del mismo lote;
6. descarga de reporte;
7. exportación asíncrona del catálogo;
8. descarga exclusivamente después de confirmación.

El resultado debe permitir que un evaluador inspeccione directamente cualquier pantalla y estado sin depender de un backend real ni de recorrer previamente el flujo completo.

---

## 5. Pantallas y orden constructivo

El orden de implementación **no coincide con el recorrido del usuario**.

| ID | Pantalla | Prioridad | Orden constructivo |
|---|---|---:|---:|
| MK-001-S04 | Resultado del lote | P0 | 1 |
| MK-001-S03 | Seguimiento de importación | P0 | 2 |
| MK-001-S05 | Descargas y exportación | P0 | 3 |
| MK-001-S01 | Cargar archivo | P0 | 4 |
| MK-001-S02 | Revisar archivo | P0 | 5 |

### Justificación del orden

S04 concentra:

- resultado completo;
- resultado parcial;
- tabla;
- dominios;
- reconciliación;
- estados semánticos;
- recuperación;
- descarga de reporte;
- mayor densidad de componentes DS;
- mayor riesgo de contradicción UX/contrato.

S03 reutiliza inmediatamente:

- panel de seguimiento;
- badges;
- contadores;
- tabla/detalle;
- estados asíncronos.

S05 reutiliza:

- `Solicitud recibida`;
- `Procesando`;
- resultado terminal;
- loaders localizados;
- descarga condicionada.

S01 y S02 son más aisladas y simples desde el punto de vista contractual.

---

## 6. Pantalla ancla

- **Pantalla:** MK-001-S04 — Resultado del lote.
- **Prioridad:** P0.

### Motivo

Es la pantalla que mejor representa la complejidad funcional y UX de MK-001.

Debe resolver correctamente:

- éxito total;
- fallo parcial;
- fallo general;
- dominios aplicados;
- dominio fallido;
- reconciliación;
- conservación de resultados confirmados;
- tabla administrativa;
- descarga de reporte;
- reanudación;
- mensajes accesibles;
- ausencia de rollback ficticio.

Si esta pantalla es incorrecta, el mockup puede aparentar una atomicidad o un nivel de certeza que la arquitectura real no posee.

### Qué debe establecer

S04 fija para MK-001:

- jerarquía de estados;
- semántica de badges;
- patrón de resultado persistente;
- tabla de filas/dominios;
- copy de errores parciales;
- patrón de acciones primarias/secundarias;
- uso de `PO/Result`;
- uso de `PO/Alert`;
- tratamiento de loading/error/unknown;
- densidad de datos;
- lenguaje de negocio;
- accesibilidad de tablas y estados.

---

## 7. Estrategia de ejecución

### Fase 0 — Congelar contrato funcional del mockup

Antes de código:

1. cerrar `component-spec.md`;
2. verificar las tres LUX;
3. confirmar las cinco rutas;
4. verificar OpenAPI 0.5.0;
5. registrar preguntas no bloqueantes;
6. confirmar que ninguna contradicción pendiente afecta una acción visible.

**Salida:** MK-001 documentalmente preparado para implementación.

---

### Fase 1 — Verificar baseline del prototipo

Comprobar que el entorno común dispone de:

- React;
- TypeScript;
- Mantine;
- tema central;
- componentes compartidos;
- Tabler Icons;
- routing interno;
- estructura:

```text
src/componentes/
src/pantallas/
src/tema/
```

No asumir:

```text
localhost:5173
```

ni ningún host/puerto.

Si no existe baseline común:

```text
BLOCKED — infraestructura transversal del prototipo no disponible
```

MK-001 no crea una aplicación React paralela.

---

### Fase 2 — Preparar fixtures contract-first

Crear fixtures antes de las pantallas.

Cobertura mínima:

```text
upload-empty
upload-selected-csv
upload-invalid-format

precheck-ok
precheck-warning

batch-queued
batch-processing
batch-completed
batch-partial
batch-catalog-failed
batch-inventory-failed
batch-pricing-failed
batch-failed-general
batch-status-unavailable
batch-resume-accepted

export-empty
export-queued
export-processing
export-completed
export-failed
export-status-unavailable
```

Cada fixture debe:

- corresponder a un estado descrito en el component-spec;
- usar únicamente propiedades compatibles con el contrato;
- contener datos ficticios;
- ser determinista;
- no depender de red;
- no generar valores aleatorios;
- no usar datos personales;
- poder ser seleccionado directamente para revisión.

---

### Fase 3 — Implementar pantalla ancla S04

Construir primero el caso:

```text
batch-partial
```

porque fuerza a resolver simultáneamente:

- resultado warning;
- filas completadas;
- filas fallidas;
- reconciliación;
- dominios aplicados;
- dominio fallido;
- tabla;
- reporte;
- reanudación.

Después añadir:

```text
batch-completed
batch-failed-general
batch-status-unavailable
```

### Criterio de salida

S04 no avanza al siguiente gate hasta demostrar que:

- éxito parcial no se representa como fallo total;
- éxito parcial no se representa como éxito total;
- no desaparecen dominios ya confirmados;
- reanudar aparece exclusivamente cuando corresponde;
- no existe rollback visual ficticio;
- el estado puede reconocerse sin color.

---

### Fase 4 — Implementar S03 reutilizando S04

Extraer únicamente las piezas que realmente son compartibles.

Reutilizar:

- representación del lote;
- estados;
- contadores;
- tabla/detalle si corresponde;
- alert de consulta fallida.

No duplicar componentes solo para modificar copy.

Estados prioritarios:

```text
batch-queued
batch-processing
batch-status-unavailable
```

### Restricción

`QUEUED` debe verse claramente como:

```text
Solicitud recibida
```

y nunca como:

```text
Importación completada
```

---

### Fase 5 — Implementar S05 y patrón de trabajo asíncrono

Construir primero:

```text
export-queued
export-processing
export-completed
export-failed
```

Reutilizar el lenguaje visual establecido en S03/S04.

Validar especialmente:

```text
download disabled/unavailable
```

mientras:

```text
QUEUED
PROCESSING
FAILED_GENERAL
```

Solo `COMPLETED` permite descargar.

No agregar filtros.

No agregar PDF.

---

### Fase 6 — Implementar S01

Construir:

- selector de archivo;
- archivo seleccionado;
- error de formato;
- acceso a plantilla;
- acceso a exportación.

El selector se implementa con capacidades disponibles del entorno común y controles nativos/componentes existentes.

No añadir dependencia dropzone únicamente para esta funcionalidad.

Si se soporta drag-and-drop, selección tradicional de archivo continúa disponible.

---

### Fase 7 — Implementar S02

Implementar revisión preliminar local.

El mensaje principal debe establecer el límite:

```text
Esta revisión comprueba el archivo y su estructura antes del envío.
El resultado definitivo se confirma durante el procesamiento del lote.
```

Validar que ningún texto diga:

```text
Validación de negocio completada
```

antes del POST de importación.

Estados:

- revisión sin observaciones;
- observaciones locales;
- error local;
- envío/loading;
- error HTTP inicial.

---

### Fase 8 — Conectar navegación integral

Después de tener todas las pantallas aisladas:

```text
S01 → S02 → S03 → S04
```

y:

```text
S01 → S05
S04 → S03  [reanudar]
S04 → S01  [nueva carga]
S05 → S01
```

La navegación debe coexistir con las rutas directas.

Nunca depender del flujo para poder inspeccionar una pantalla.

---

### Fase 9 — Reproducción determinista

Todas las rutas deben permitir inspeccionar estados relevantes.

La implementación concreta puede usar:

- query parameters;
- configuración del entorno de prototipado;
- selector interno de fixtures;
- mecanismo equivalente.

Ejemplo conceptual:

```text
/MK001/S04?estado=partial
/MK001/S04?estado=completed
/MK001/S03?estado=processing
/MK001/S05?estado=completed
```

La sintaxis concreta no queda impuesta por este plan.

Sí queda impuesto que cada estado pueda reproducirse sin manipular código fuente.

---

### Fase 10 — Normalización

Una vez funcionales las cinco pantallas:

- sustituir componentes ad hoc por componentes compartidos;
- eliminar colores arbitrarios;
- eliminar spacing arbitrario;
- eliminar iconos externos;
- eliminar mensajes técnicos;
- revisar labels;
- revisar estructura semántica;
- revisar rutas;
- revisar imports;
- eliminar duplicación innecesaria.

La normalización no puede alterar el comportamiento aprobado.

---

### Fase 11 — Accesibilidad

Verificar:

- navegación completa mediante teclado;
- foco visible;
- foco no oculto por elementos sticky;
- labels visibles;
- errores asociados;
- estados comprensibles sin color;
- tablas semánticas;
- loader con texto;
- mensajes de estado anunciables;
- controles solo-icono con nombre accesible;
- aumento de texto sin corte crítico;
- ausencia de trampa de teclado.

---

### Fase 12 — Autovalidación y revisión

Orden:

```text
Implementación
↓
Autovalidación Marco
↓
Correcciones locales
↓
Cero bloqueantes/importantes
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

No solicitar revisión transversal antes de completar la autovalidación.

---

## 8. Reutilización

| Componente | Origen | Pantallas | Acción |
|---|---|---|---|
| `PO/Button` DS-C01 | Design System | S01-S05 | Reutilizar |
| `PO/Select` DS-C06 | Design System | S05 | Reutilizar |
| `PO/Badge` DS-C14 | Design System | S03-S05 | Reutilizar |
| `PO/Table` DS-C17 | Design System | S03-S04 | Reutilizar |
| `PO/Card` DS-C19 | Design System | S01-S05 | Reutilizar |
| `PO/Alert / PO/Result` DS-C22 | Design System | S02-S05 | Reutilizar |
| `PO/Skeleton / PO/Loader` DS-C24 | Design System | S03-S05 | Reutilizar |
| `PO/EmptyState` DS-C25 | Design System | S03-S04 | Reutilizar cuando aplique |
| `PO/Breadcrumbs` DS-C28 | Design System | S01-S05 | Reutilizar |
| MK-001-C01 Selector de archivo | MK-001 | S01 | Construir específico |
| MK-001-C02 Resumen preliminar | MK-001 | S02 | Construir específico |
| MK-001-C03 Seguimiento del lote | MK-001 | S03-S04 | Construir y reutilizar localmente |
| MK-001-C04 Estado fila/dominio | MK-001 | S03-S04 | Construir y reutilizar localmente |
| MK-001-C05 Exportación | MK-001 | S05 | Construir específico |

### Regla de promoción

Si un componente específico resulta útil para otros MK, no se mueve automáticamente a `src/componentes/`.

Primero debe comprobarse que:

- su semántica sea realmente transversal;
- no contenga reglas particulares de MK-001;
- su promoción no cree una UX nueva;
- exista coordinación con la arquitectura común.

---

## 9. Normalización técnica

La implementación final debe alinearse con:

- React.
- TypeScript.
- Mantine.
- Tabler Icons.
- tema central.
- Design System 1.0.0.
- UX 2.0.
- desktop 1440 px.

### Estructura esperada

Como mínimo, el código específico reside bajo:

```text
prototipo/src/pantallas/MK001/
```

Puede organizar internamente:

```text
MK001/
├── componentes/
├── fixtures/
├── pantallas/
└── ...
```

siempre que dicha organización:

- no altere rutas públicas;
- no duplique infraestructura común;
- permanezca confinada a MK-001;
- mantenga imports claros.

La estructura interna exacta se concreta en `tasks.md` según la baseline disponible.

### Routing

Cada pantalla debe resolver directamente:

```text
/MK001/S01
/MK001/S02
/MK001/S03
/MK001/S04
/MK001/S05
```

No fijar dominio, puerto o servidor.

---

## 10. Matriz de estados

| Estado | Pantalla | Prioridad | Fixture | Evidencia |
|---|---|---:|---|---|
| Sin archivo | S01 | P0 | `upload-empty` | Selector disponible |
| Archivo válido preliminar | S01 | P0 | `upload-selected-csv` | Nombre/formato visibles |
| Archivo inválido | S01 | P0 | `upload-invalid-format` | Error localizado |
| Revisión local OK | S02 | P0 | `precheck-ok` | Resumen + límite explícito |
| Revisión con observaciones | S02 | P0 | `precheck-warning` | Warning accionable |
| Solicitud recibida | S03 | P0 | `batch-queued` | No éxito terminal |
| Procesando | S03 | P0 | `batch-processing` | Contadores reales |
| Consulta no disponible | S03 | P0 | `batch-status-unavailable` | Último contexto conservado |
| Completado | S04 | P0 | `batch-completed` | Result success |
| Completado con observaciones | S04 | P0 | `batch-partial` | Result warning + tabla |
| Catálogo fallido | S04 | P0 | `batch-catalog-failed` | Sin falsas dependencias |
| Inventario fallido | S04 | P0 | `batch-inventory-failed` | Catálogo/Precios conservados |
| Pricing fallido | S04 | P0 | `batch-pricing-failed` | Catálogo/Inventario conservados |
| Fallo general | S04 | P0 | `batch-failed-general` | Error general sin rollback ficticio |
| Reanudación aceptada | S03 | P0 | `batch-resume-accepted` | Mismo lote |
| Exportación inicial | S05 | P0 | `export-empty` | CSV/XLSX |
| Exportación recibida | S05 | P0 | `export-queued` | Descarga bloqueada |
| Exportando | S05 | P0 | `export-processing` | Descarga bloqueada |
| Exportación lista | S05 | P0 | `export-completed` | Descarga habilitada |
| Exportación fallida | S05 | P0 | `export-failed` | Sin descarga |
| Estado desconocido | S05 | P0 | `export-status-unavailable` | Último contexto conservado |

---

## 11. Orden de ejecución y gates

| Fase | Salida | Actor | Gate |
|---|---|---|---|
| Gate 0 | Documentación cerrada | Marco | Spec aprobado |
| Baseline | Entorno común comprobado | Marco / responsable técnico | Infraestructura disponible |
| Fixtures | Dataset determinista | Marco | Cobertura contractual |
| Pantalla ancla | S04 | Marco | Gate A1 |
| Seguimiento | S03 | Marco | Gate A2 |
| Exportación | S05 | Marco | Gate A3 |
| Entrada | S01 | Marco | Gate A4 |
| Revisión | S02 | Marco | Gate A5 |
| Navegación | Flow completo | Marco | Gate A6 |
| Normalización | Código alineado DS | Marco | Gate C |
| Estados/A11y | Matriz P0 completa | Marco | Gate D |
| Autovalidación | Evidencia local | Marco | Gate E0 |
| Revisión transversal | Observaciones | Leonardo Vera Rodríguez | Gate E |
| Correcciones | Cero hallazgos requeridos | Marco | Gate E |
| Visto bueno | APROBADO PARA FIGMA | Leonardo Vera Rodríguez | Gate E |
| Figma | Frames sincronizados | Marco | Gate F1 |
| Fidelidad | Comparación aprobada | Marco | Gate F2 |
| Cierre | Resultado APROBADO | Marco | Todos |

---

## 12. Riesgos

| ID | Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|---|
| R-01 | Baseline React/Mantine/routing todavía no implementada | Media | Alto | Bloquear implementación y esperar infraestructura común; no crear app paralela |
| R-02 | S02 se interpreta como prevalidación backend completa | Alta | Alto | Copy explícito + LUX-03 + test de contenido |
| R-03 | `202` se presenta visualmente como éxito | Media | Alto | Validar QUEUED/PROCESSING/terminal por separado |
| R-04 | Se inventa progreso porcentual | Media | Alto | Usar contadores/estados contractuales únicamente |
| R-05 | Resultado parcial parece rollback o fallo total | Media | Alto | S04 ancla + fixtures multidominio |
| R-06 | Reanudar se implementa como nueva importación | Media | Alto | Mantener mismo lote y fixture específico |
| R-07 | Tabla demasiado ancha en 1440 px | Alta | Medio | Jerarquizar columnas; detalle complementario; scroll solo regional si resulta imprescindible |
| R-08 | Información técnica domina la interfaz | Media | Medio | Copy de negocio y normalización final |
| R-09 | S01 introduce dependencia dropzone propia | Media | Medio | Usar baseline existente/native file input; no añadir dependencias |
| R-10 | Exportación permite descargar antes de `COMPLETED` | Media | Alto | Gate específico en S05 |
| R-11 | Fixtures inventan datos contractualmente inexistentes | Media | Alto | Revisarlos contra OpenAPI antes de implementar |
| R-12 | `rows[]` ausente rompe S03/S04 | Media | Medio | Diseñar degradación a resumen/reporte según component-spec |
| R-13 | UI adopta defaults Mantine inconsistentes | Media | Medio | Tema central + Design System como referencia |
| R-14 | Estados por color no accesibles | Media | Alto | Texto + iconografía + contraste + validación teclado |
| R-15 | Componentes locales se convierten prematuramente en shared | Baja | Medio | Mantenerlos en MK001 hasta demostrar reutilización transversal |
| R-16 | Referencia histórica OpenAPI 0.4.0 de SPEC confunde implementación | Media | Medio | Consumir explícitamente OpenAPI 0.5.0 y registrar discrepancia documental |
| R-17 | Orden de construcción se confunde con navegación final | Baja | Medio | Documentar ambas secuencias por separado |

---

## 13. Quality Gates

### Gate A0 — Contrato documental

- Component Spec aprobado.
- Cinco pantallas P0 identificadas.
- LUX-01/02/03 aceptadas.
- Sin pregunta abierta bloqueante.
- API 0.5.0 confirmada.

---

### Gate A1 — Pantalla ancla S04

Debe demostrar:

- éxito completo;
- resultado parcial;
- fallo general;
- resultado desconocido;
- tabla por fila/dominio;
- conservación de confirmados;
- reconciliación;
- descarga de reporte;
- reanudación contractual.

No pasa si:

- se muestra rollback;
- se inventa estado;
- se pierde detalle confirmado;
- reanudar carece de condición.

---

### Gate A2 — Seguimiento S03

Debe demostrar:

```text
Solicitud recibida ≠ Procesando ≠ Resultado confirmado
```

Y:

- contadores válidos;
- loader localizado;
- consulta fallida sin falsificar resultado;
- ninguna barra ficticia.

---

### Gate A3 — Exportación S05

Debe demostrar:

- CSV y XLSX exclusivamente;
- ningún filtro inventado;
- solicitud recibida;
- procesamiento;
- éxito;
- fallo;
- descarga únicamente en `COMPLETED`.

---

### Gate A4 — Entrada S01

Debe demostrar:

- archivo seleccionable con teclado;
- CSV/XLSX;
- error localizado;
- plantilla accesible;
- acceso a exportación;
- ninguna dependencia técnica innecesaria.

---

### Gate A5 — Revisión S02

Debe demostrar que:

- la revisión es preliminar/local;
- no promete validación de negocio;
- observaciones permanecen corregibles;
- errores HTTP iniciales tienen copy entendible.

---

### Gate A6 — Navegación

Debe comprobar:

```text
S01 → S02 → S03 → S04
S01 → S05
S04 → S03
S04 → S01
S05 → S01
```

y acceso directo independiente a todas las rutas.

---

### Gate B — UX

Verificar:

- UX-P01 aplicada.
- UX-P02 aplicada únicamente donde corresponde.
- UX-P03 aplicada.
- UXD-003, 004, 005, 007, 008, 009 y 012 cubiertas.
- UXG aplicables cubiertas.
- LUX-01/02/03 respetadas.
- No aparece una nueva LUX no documentada.

---

### Gate C — UI / Design System

- DS-CXX correctos.
- Sin colores arbitrarios.
- Sin tipografías arbitrarias.
- Sin radios/espaciados arbitrarios.
- Sin estilos inline huérfanos.
- Tabler Icons únicamente.
- Componentes comunes reutilizados.
- Componentes específicos confinados a MK-001.
- Sin dependencia nueva innecesaria.

---

### Gate D — PC y accesibilidad

- 1440 px sin overflow horizontal de página.
- Tabla usable.
- Texto aumentado sin corte crítico.
- Foco visible.
- Navegación por teclado.
- Errores perceptibles sin color.
- Estados perceptibles sin color.
- Labels visibles.
- Loader con texto.
- Semántica de tabla correcta.
- Sin trampas de teclado.

---

### Gate E0 — Autovalidación del owner

Marco debe comprobar:

- SPEC-001.
- HU-001 CA-01 a CA-15.
- WF-001.
- FLOW-001.
- API 0.5.0.
- Component Spec.
- UX 2.0.
- Design System 1.0.0.

No solicitar revisión transversal mientras exista un hallazgo bloqueante o importante requerido abierto.

---

### Gate E — Revisión transversal

- **Revisor:** Leonardo Vera Rodríguez.
- Autovalidación previamente cerrada.
- Revisión UX transversal realizada.
- Hallazgos importantes/bloqueantes corregidos.
- Nueva inspección completada.
- Estado registrado:

```text
APROBADO PARA FIGMA
```

---

### Gate F — Figma y cierre

- La versión aprobada para Figma es la única trasladada.
- Frames de revisión 1440×900 o altura ampliada según contenido.
- Mismos tokens.
- Mismos componentes.
- Mismos fixtures representativos.
- Mismos estados.
- Mismo copy.
- Mismas acciones.
- Cinco pantallas P0 presentes.
- Enlace canónico registrado.
- Validación de fidelidad completada.

Solo entonces:

```text
validation-report.md
Resultado general = APROBADO
```

---

## 14. Criterios de ejecución satisfactoria

Este plan queda completado cuando:

- [ ] Gate 0 cerrado.
- [ ] Baseline transversal disponible.
- [ ] Fixtures contractuales creados.
- [ ] S04 implementada y validada como pantalla ancla.
- [ ] S03 reutiliza correctamente los patrones de seguimiento.
- [ ] S05 representa correctamente el trabajo de exportación.
- [ ] S01 permite iniciar el flujo sin dependencias innecesarias.
- [ ] S02 no promete prevalidación backend inexistente.
- [ ] Las cinco rutas son directas y reproducibles.
- [ ] Todos los estados P0 son deterministas.
- [ ] La navegación integral respeta FLOW-001.
- [ ] No se añadieron capacidades funcionales.
- [ ] No se añadieron dependencias no aprobadas.
- [ ] Normalización terminada.
- [ ] Accesibilidad básica verificada.
- [ ] Autovalidación completada.
- [ ] Revisión transversal completada.
- [ ] Estado `APROBADO PARA FIGMA` obtenido.
- [ ] Figma sincronizado.
- [ ] Fidelidad comprobada.
- [ ] `validation-report.md` registra `APROBADO`.
