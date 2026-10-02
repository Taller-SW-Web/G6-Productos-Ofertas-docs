# Validation Report — MK-XXX

> **Propósito y rol documental:**
> Documento formal de evidencia y validación (cómo demostrar que el resultado cumple).
> Registra objetivamente la comprobación del mockup contra las fuentes de verdad oficiales.
> No es un plan de trabajo ni un gestor de tareas pendientes (responsabilidad exclusiva de `tasks.md`).

## 1. Identificación

- **Mockup:** MK-XXX
- **Funcionalidad:** [Nombre de la funcionalidad]
- **Responsable funcional (Owner):** [Nombre del owner funcional]
- **Revisor UX transversal:** Leonardo Vera Rodríguez
- **Commit / Versión del prototipo:** [SHA o referencia de versión]
- **Autovalidación completada:** Sí | No
- **Fecha de autovalidación:** [AAAA-MM-DD]
- **Fecha de revisión transversal:** [AAAA-MM-DD]
- **Resultado general:** PENDIENTE | REQUIERE CORRECCIONES | APROBADO

## 2. Pantallas

Inspección de disponibilidad y renderizado de cada pantalla inventariada.

| ID | Pantalla | Ruta del prototipo | Evidencia comprobada | Resultado |
|---|---|---|---|---|
| MK-XXX-S01 | [Nombre] | `/MKXXX/S01` | [Captura / Inspección directa a 1440 px] | PASS / FAIL |
| MK-XXX-S02 | [Nombre] | `/MKXXX/S02` | [Captura / Inspección directa a 1440 px] | PASS / FAIL |

## 3. Trazabilidad de ejecución

Relación directa entre las unidades de trabajo ejecutadas en `tasks.md`, las pantallas o componentes implementados, la evidencia comprobada y el resultado de verificación obtenido.

| Tarea (`Task`) | Pantalla / Componente | Qué se validó | Fuente de referencia | Evidencia objetiva | Resultado |
|---|---|---|---|---|---|
| MK-XXX-T10 | MK-XXX-S01 | Estructura de zonas y jerarquía | `component-spec.md` / `WF-XXX` | Inspección visual en ruta `/MKXXX/S01` en viewport 1440 px | PASS / FAIL |
| MK-XXX-T11 | MK-XXX-S01 / MK-XXX-C01 | Componentes específicos y compartidos | Design System / `component-spec.md` | Inspección visual de componentes y propiedades conceptuales | PASS / FAIL |
| MK-XXX-T12 | MK-XXX-S01 | Interacción y transición de flujo | `FLOW-XXX` | Prueba de interacción navegable hacia pantalla destino | PASS / FAIL |
| MK-XXX-T13 | MK-XXX-S01 | Estado default con datos | Fixture `default` | Renderizado con dataset estándar válido | PASS / FAIL |
| MK-XXX-T14 | MK-XXX-S01 | Estados Loading, Empty y Error | Fixtures correspondientes | Reproducción determinista de cada estado | PASS / FAIL |
| MK-XXX-T50 | Transversal | Normalización técnica (Mantine / tokens) | Design System | Código auditado en `prototipo/src/pantallas/MKXXX` | PASS / FAIL |

## 4. Trazabilidad de requisitos funcionales

| Requisito / Regla | Fuente | Pantalla / Componente | Qué se validó | Evidencia | Resultado | Observación |
|---|---|---|---|---|---|---|
| [Regla de negocio] | [SPEC-XXX] | [SXX / CXX] | [Validación funcional específica] | [Ruta / Datos de prueba] | PASS / FAIL | [Comentario técnico] |

## 5. UX del módulo

- [ ] Propuesta UX global aplicada de forma consistente.
- [ ] UX Guidelines normativas aplicadas rigurosamente.
- [ ] UX Decisions (`UXD-XXX`) relevantes aplicadas.
- [ ] No se creó una UX paralela o no documentada para esta funcionalidad.

## 6. Decisiones locales (LUX)

| ID | Decisión | Justificación en spec | Comportamiento aplicado | Evidencia | Resultado |
|---|---|---:|---:|---|---|
| LUX-01 | [Nombre] | Sí / No | Sí / No | [Ruta / Interacción comprobada] | PASS / FAIL |

## 7. UI y Design System

- **Referencia visual consumida:** [mockups/DESIGN.md](../../DESIGN.md), versión [versión consumida].
- [ ] Variantes, tamaños y estados de los componentes DS-CXX coinciden con el component-spec y el Design System.
- [ ] Colores aplicados estrictamente mediante tokens oficiales del tema.
- [ ] Escala tipográfica oficial respetada.
- [ ] Spacing y border-radius conforme a la escala del módulo.
- [ ] Iconografía implementada exclusivamente mediante Tabler Icons.
- [ ] Componentes compartidos del Design System reutilizados sin duplicación ad hoc.
- [ ] Sin estilos inline arbitrarios ni dependencias visuales no autorizadas.
- [ ] Sin términos técnicos ni identificadores de base de datos visibles al usuario final.

## 8. PC y layout

- [ ] Validado en viewport canónico de 1440 px de ancho.
- [ ] Sin overflow horizontal involuntario en ningún estado.
- [ ] Jerarquía visual clara y legible.
- [ ] Operabilidad completa con mouse y navegación por teclado.
- [ ] No contiene variantes ni elementos específicos de mobile/tablet fuera del alcance.

## 9. Accesibilidad básica

- [ ] Foco visualmente perceptible en todos los elementos interactivos.
- [ ] Nombres accesibles (aria-label o etiquetas) en botones e inputs.
- [ ] Labels visibles asociados a campos de formulario y controles.
- [ ] La información de estado no depende exclusivamente del color.
- [ ] Mensajes de error claros, comprensibles y accionables.

## 10. Autovalidación del owner funcional

> **Alcance de la autovalidación:**
> Verificación de primera línea realizada por el responsable funcional (owner) sobre su propia construcción antes de solicitar la revisión transversal.
> Permite detectar y resolver desvíos de forma temprana.

### Hallazgos de autovalidación

| ID | Severidad | Pantalla / Componente | Qué se validó | Fuente | Hallazgo | Acción requerida | Responsable de corrección | Estado |
|---|---|---|---|---|---|---|---|---|
| F-01 | Bloqueante / Importante / Menor | S01 | [Qué se validó] | [SPEC / WF / UX] | [Descripción del hallazgo] | [Acción correctiva] | [Owner funcional] | Abierto / Cerrado |

### Cierre de autovalidación
- [ ] Todos los hallazgos bloqueantes de autovalidación están cerrados.
- [ ] Todos los hallazgos importantes requeridos de autovalidación están cerrados.
- [ ] Autovalidación completada satisfactoriamente por el owner funcional.

## 11. Revisión UX transversal previa a Figma

> **Alcance de la revisión transversal:**
> Revisión UX transversal posterior a la autovalidación del owner, ejecutada por Leonardo Vera Rodríguez (Líder UI/UX).
> Certifica la consistencia global con la propuesta UX del módulo, UX Guidelines y Design System.
> Su visto bueno es el gate obligatorio para autorizar el paso a Figma (**APROBADO PARA FIGMA**).

- **Revisor transversal:** Leonardo Vera Rodríguez
- **Rol:** Revisor UX transversal de mockups
- **Fecha de revisión:** [AAAA-MM-DD]
- **Resultado de revisión transversal:** PENDIENTE | REQUIERE CORRECCIONES | APROBADO PARA FIGMA

### Observaciones del revisor transversal

[Observaciones de consistencia, ergonomía visual y alineación al módulo]

### Hallazgos de la revisión transversal

| ID | Severidad | Pantalla / Componente | Qué se validó | Fuente | Hallazgo | Acción requerida | Responsable de corrección | Estado |
|---|---|---|---|---|---|---|---|---|
| RV-01 | Bloqueante / Importante / Menor | [SXX / General] | [Patrón UX / DS] | [UX Guidelines / DS] | [Descripción del hallazgo] | [Acción correctiva] | [Owner funcional] | Abierto / Cerrado |

### Criterios de visto bueno formal
- [ ] Todos los hallazgos bloqueantes de la revisión transversal están cerrados.
- [ ] Todos los hallazgos importantes requeridos están cerrados.
- [ ] El mockup respeta rigurosamente la UX transversal del módulo.
- [ ] El mockup aplica fielmente el Design System.
- [ ] Visto bueno formal otorgado para reflejar el prototipo en Figma.

*Cuando todos los criterios anteriores se cumplen, el resultado de esta sección se declara formalmente como **APROBADO PARA FIGMA**.*

## 12. Figma y fidelidad

- [ ] La versión con visto bueno fue trasladada fielmente a Figma.
- [ ] Coincide punto a punto con la versión aprobada para Figma en el prototipo.
- [ ] Incluye todas las pantallas P0 requeridas sin omitir componentes ni zonas.
- [ ] No se alteró materialmente la composición ni la jerarquía visual.
- [ ] Enlace a Figma registrado: [URL de Figma].

## 13. Cierre y resultado general

> **Regla obligatoria de aprobación:**
> `validation-report.md` solo puede tener **Resultado general = APROBADO** cuando:
> 1. La autovalidación del owner esté completa y cerrada (cero bloqueos).
> 2. La Revisión transversal previa a Figma de Leonardo Vera Rodríguez tenga resultado **APROBADO PARA FIGMA**.
> 3. No existan hallazgos bloqueantes ni importantes requeridos abiertos (ni en autovalidación ni en revisión transversal).
> 4. Todos los criterios de la sección Figma estén completados satisfactoriamente y el enlace esté registrado.
> 5. Todos los Quality Gates del `plan.md` estén formalmente cerrados.

**Resultado general:** [PENDIENTE / REQUIERE CORRECCIONES / APROBADO]

**Justificación:**  
[Texto justificativo del resultado final conforme a las evidencias registradas.]

**Observaciones no bloqueantes**
> **Nota de gobernanza:** Este documento registra exclusivamente evidencia objetiva y observaciones de cierre. No gestiona tareas pendientes de desarrollo, las cuales deben residir y gestionarse exclusivamente en `tasks.md`.
- [Observación menor o mejora futura no bloqueante registrada para el backlog general].
