# Plan de Mockup — MK-016

> **Instanciación:** Copiar a `mockups/MK-016/plan.md`. Los enlaces relativos de esta plantilla se interpretan desde ese destino; el Design System está en `../DESIGN.md`.

> **Propósito y rol documental:**
> Define la estrategia de ejecución (cómo debe construirse la funcionalidad).
> Establece fases, orden constructivo, restricciones operativas y Quality Gates.
> Puede ser seguido por un desarrollador o por un agente de forma determinista.
> No redefine el contenido detallado de las pantallas (especificado en `component-spec.md`) ni la UX del módulo.

## 1. Identificación

- **Mockup:** MK-016
- **Funcionalidad:** Dashboard analítico y alertas de stock
- **Responsable:** Miguel Ángel Taco Zavala
- **Versión:** 1.0.0
- **Estado:** Aprobado

## 2. Contrato de ejecución

Establece las condiciones formales, compromisos y límites de la ejecución técnica.

### Entradas

Referencias documentales oficiales que deben consultarse obligatoriamente antes y durante la ejecución del plan:
- `component-spec.md` (especificación principal del resultado esperado del mockup, subordinada a las fuentes oficiales).
- UX Guidelines (`mockups/ux/ux-guidelines.md`).
- UX Decisions (`mockups/ux/ux-decisions.md`).
- Propuesta UX Integral del módulo (`mockups/ux/propuesta-ux.md`).
- Wireframe oficial (`WF-016`).
- Flujo de navegación oficial (`FLOW-016`).
- Design System de mockups ([mockups/DESIGN.md](../DESIGN.md), versión 1.0.0, tokens y componentes DS-C01–DS-C29).

*(Ver detalle de estados requeridos en la sección 3. Entradas obligatorias).*

### Salidas esperadas

Entregables concretos y verificables que deben existir al finalizar la ejecución del plan:
- Pantalla prioritaria P0 `MK-016-S01` implementada, normalizada y operativa.
- Una ruta individual relativa y directa accesible en `/MK016/S01`.
- Código normalizado y modular en `prototipo/src/pantallas/MK016` alineado al Design System y Mantine.
- Estados P0 operativos y reproducibles de forma determinista (default, loading, error, empty).
- Autovalidación del owner completada con evidencias objetivas registradas en `validation-report.md`.

### Restricciones de ejecución

Reglas estrictas que gobiernan la ejecución para preservar la integridad del módulo:
- **No modificar fuentes de verdad** (SPEC, HU, WF, FLOW, API Contract, Design System) sin una corrección documental explícita y aprobada.
- **No inventar reglas de negocio** ni asumir lógicas no descritas en los documentos oficiales.
- **No inventar campos, botones, filtros ni estados funcionales** ausentes en `component-spec.md`.
- **No crear nuevos patrones UX transversales sin registrarlos** (cualquier excepción justificada debe documentarse como `LUX-XX` en `component-spec.md`).
- **No modificar otros MK** fuera del alcance asignado a esta funcionalidad (`MK-016`).
- **No introducir dependencias nuevas**, librerías externas ni utilidades ad hoc sin justificación y aprobación técnica.
- **No redefinir el contenido detallado de pantallas** en este plan si ya reside en `component-spec.md`.
- **No permitir mutaciones de stock ni botones de edición** en este dashboard (especificación estricta de solo lectura según SPEC-016).

### Condiciones de parada / escalamiento

Detener inmediatamente la ejecución, marcar la tarea como `BLOCKED` y escalar al responsable correspondiente cuando:
- Exista contradicción irreconciliable entre fuentes de verdad (ej. discrepancia entre SPEC, WF y Contrato API).
- Falte información necesaria para tomar una decisión funcional o de negocio crítica.
- Sea necesario inventar comportamiento de interfaz o flujos alternativos no especificados.
- Una dependencia externa requerida (servicio, contrato, componente compartido) no esté definida o disponible.
- Un Quality Gate no pueda verificarse objetivamente debido a ambigüedad en los criterios o bloqueos técnicos.

## 3. Entradas obligatorias

| Entrada | Referencia | Estado requerido |
|---|---|---|
| Propuesta UX módulo | `mockups/ux/propuesta-ux.md` | Vigente |
| UX Decisions | `mockups/ux/ux-decisions.md` | Vigente |
| UX Guidelines | `mockups/ux/ux-guidelines.md` | Vigente |
| Component Spec | `component-spec.md` | Aprobado |
| SPEC/HU | [SPEC-016](../specs/SPEC-016-dashboard-alertas-stock.md) / [HU-016](../hu/HU-016-dashboard-alertas-stock.md) | Vigentes |
| WF | [WF-016](../wireframes/flows/WF-016-dashboard-alertas-stock.md) | Vigente |
| Flow | [FLOW-016](../flujos/FLOW-016-dashboard-alertas-stock.md) | Vigente |
| Design System | [mockups/DESIGN.md](../DESIGN.md), versión 1.0.0 | Vigente y coherente con el component-spec |

## 4. Objetivo

Construir la pantalla analítica del dashboard de inventario y alertas de stock (`MK-016-S01`), garantizando que el gestor comercial supervise en tiempo real saldos físicos, disponibles, bloqueados y traslados sin mutar el inventario ni exponer nombres técnicos de bases de datos.

## 5. Pantallas

Inventario de pantallas a construir con su orden de ejecución. El contenido detallado se especifica en `component-spec.md`.

| ID | Nombre | Prioridad | Orden |
|---|---|---|---:|
| MK-016-S01 | Dashboard analítico y alertas de stock | P0 | 1 |

## 6. Pantalla ancla

- **Pantalla:** MK-016-S01
- **Motivo:** Es la pantalla única integral que consolida las métricas globales, el panel de alertas de discrepancias, la distribución por almacén/tienda y la tabla detallada de inventario por SKU.
- **Qué debe establecer:**
  - Disposición armónica de tarjetas KPI superiores (`DS-C19`).
  - Barra de filtrado reactivo (`DS-C13`).
  - Cuadrícula analítica de dos columnas (Alertas críticas vs Distribución geográfica).
  - Tabla de inventario con cálculo autoritativo de disponible y badges semánticos (`DS-C14`).

La pantalla ancla no crea una UX independiente; aplica la UX global del módulo a esta funcionalidad.

## 7. Estrategia

1. Preparar contexto y fixtures deterministas para estados default, loading, empty y error.
2. Implementar la pantalla ancla `MK-016-S01` conforme al `component-spec.md`.
3. Validarla contra fuentes oficiales (`SPEC-016`, `HU-016`, `WF-016`) y la UX transversal del módulo.
4. Normalizar el código con React, TypeScript, Mantine, Tabler Icons y el tema central.
5. Ejecutar la autovalidación local de Miguel Ángel Taco Zavala en `validation-report.md`.
6. Solicitar y atender la revisión transversal UX de Leonardo Vera Rodríguez.
7. Reflejar la versión aprobada en Figma y cerrar Quality Gates.

## 8. Componentes compartidos

Componentes del Design System que deben ser consumidos sin duplicación:
- `DS-C19 PO/Card/KPI`: Métricas numéricas de disponibilidad y traslados.
- `DS-C17 PO/Table`: Tabla principal de inventario y tabla de distribución por ubicación.
- `DS-C14 PO/Badge`: Badges de estado `DISPONIBLE`, `STOCK_BAJO`, `AGOTADO`.
- `DS-C13 PO/FilterBar`: Búsqueda y filtros combinados.
- `DS-C15 PO/Alert/Notice`: Avisos de alertas críticas de stock y traslados.

## 9. Calidad y normalización

- **Código:** Modular, tipado estricto en TypeScript, sin dependencias huérfanas.
- **Tokens:** Colores, espaciados y radios extraídos exclusivamente de las variables oficiales de `DESIGN.md`.
- **Tipografía:** Escala Inter oficial para desktop.
- **Iconos:** Exclusivamente Tabler Icons.
- **Terminología:** Eliminación estricta de términos como `on_hand`, `reserved`, `blocked`, `available` de las vistas del usuario final.

## 10. Estados

Garantizar la inspección directa y determinista de los 4 estados principales:
- `/MK016/S01?estado=default`: Datos completos con inventario en Tienda Miraflores y Almacén Central.
- `/MK016/S01?estado=loading`: Skeletons en KPIs y tablas.
- `/MK016/S01?estado=empty`: Estado sin coincidencias con mensaje claro y botón de reset.
- `/MK016/S01?estado=error`: Alerta de error en servicio con opción de reintentar.

## 11. Estrategia de revisión

- Autovalidación por Miguel Ángel Taco Zavala documentada en `validation-report.md`.
- Revisión transversal por Leonardo Vera Rodríguez para obtener `APROBADO PARA FIGMA`.
- Verificación de fidelidad entre la pantalla aprobada y el archivo en Figma.

## 12. Quality Gates

| Gate | Condición de aprobación | Verificación |
|---|---|---|
| Gate A — Requisitos | SPEC-016, HU-016, WF-016 y FLOW-016 alineados sin contradicciones | Inspección cruzada |
| Gate B — Especificación | `component-spec.md` aprobado con todas las pantallas P0 e inventario de rutas | Revisión formal |
| Gate C — Construcción | Pantalla operativa en `/MK016/S01` normalizada con Design System a 1440 px | Inspección visual y código |
| Gate D — Autovalidación | Cero hallazgos bloqueantes en autovalidación de primera línea | `validation-report.md` |
| Gate E — Revisión UX | Visto bueno formal de Leonardo Vera Rodríguez | `APROBADO PARA FIGMA` |
| Gate F — Cierre | Traslado validado en Figma y DoR/DoD cerrado | `validation-report.md` = APROBADO |
