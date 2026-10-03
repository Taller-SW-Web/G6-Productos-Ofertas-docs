# Plan de Mockup — MK-007

## 1. Identificación
Reglas de venta cruzada y upselling · Axel Cueva · v1.0 · Preparación documental; implementación pendiente de base inicial.

## 2. Contrato de ejecución
Entradas: [component-spec](component-spec.md) y fuentes §2. Salidas: pantallas P0 y rutas §5; código `../prototipo/src/pantallas/MK007`; fixtures; build y evidencia 1440 en validation-report. Restricciones: no modificar fuentes/otros MK, no inventar reglas o permisos, no simular checkout. Detener estado afectado si falta dato contractual, registrar BLOCKED en tasks; respetar gates de revisión/Figma.

## 3. Entradas obligatorias
SPEC/HU/WF/FLOW vigentes en cueva; UX2.0 y DS1.0 en master dc8fc6d; gates #59/#60 cerrados. Documentos principales creados en orden: component-spec → plan → tasks. D-REC-01/02 no se resuelven por UX. Stack requerido React/TypeScript/Mantine/Tabler; Vite solo sirve/construye el entorno, Fontsource distribuye Inter/Oswald localmente sin depender de red en runtime. Sin router/form/datagrid adicional. Lockfile registra versiones reproducibles; justificación técnica: entorno compartido estaba vacío, estas dependencias materializan el stack/fuentes exigidos por DESIGN §15.

## 4. Objetivo
Construir exclusivamente lo especificado y entregar evidencia revisable; el cierre depende del visto bueno UX y Figma.

## 5. Pantallas

| ID | Pantalla | Propósito | Entrada | Acción principal | Salida | Prioridad | Ruta |
|---|---|---|---|---|---|---|---|
| MK-007-S01 | Listado de reglas | list | Navegación/entrada directa | Consultar / elegir / confirmar | Retorno al contexto | P0 | `/MK007/S01` |
| MK-007-S02 | Crear venta cruzada | create | Navegación/entrada directa | Guardar | Retorno al contexto | P0 | `/MK007/S02` |
| MK-007-S03 | Editar regla | edit | Navegación/entrada directa | Guardar | Retorno al contexto | P0 | `/MK007/S03` |
| MK-007-S04 | Crear upselling | upsell | Navegación/entrada directa | Guardar | Retorno al contexto | P0 | `/MK007/S04` |
| MK-007-S05 | Seleccionar recomendado | selector | Navegación/entrada directa | Consultar / elegir / confirmar | Retorno al contexto | P0 | `/MK007/S05` |
| MK-007-S06 | Detalle de regla | detail | Navegación/entrada directa | Consultar / elegir / confirmar | Retorno al contexto | P0 | `/MK007/S06` |
| MK-007-S07 | Cambiar estado | state | Navegación/entrada directa | Consultar / elegir / confirmar | Retorno al contexto | P0 | `/MK007/S07` |

## 6. Pantalla ancla
S01 fija shell, tabla, estado/filtros y jerarquía según DS. Formularios reutilizan el mismo lenguaje, sin UX nueva.

## 7. Estrategia
1. Completar documentos y fuentes. 2. Recibir de Leonardo Vera la base visual inicial de las pantallas especificadas; contrastar con fuentes. 3. Refinar shell/S01. 3. Configuración y selección. 4. Detalle/estado. 5. Normalización. 6. Estados y accesibilidad. 7. Autovalidación. 8. Revisión Leonardo. 9. Correcciones/visto bueno. 10. Figma fiel y validación. No ejecutar fases posteriores a gate pendiente.

## 8. Reutilización
Shell, navegación, tabla, estado, feedback, formulario base, confirmación, botones y tokens comunes en `src/componentes`/`src/tema`; configuración por MK en su carpeta. No incorporar código de otros owners.

## 9. Normalización
React/TS/Mantine9.6.2/Tabler; dimensiones del DS prevalecen sobre defaults de biblioteca. Tema único; Inter/Oswald; semántica y foco, ruta directa por pantalla. Sin estilos visuales arbitrarios en MK.

## 10. Estados
Consumir §13 de spec. Carga/vacío/error sobre región de lectura; validación al guardar con datos conservados; confirmación estado sin éxito prematuro; 401/403 bloquean mutación. Datos agregados desconocidos permanecen desconocidos.

## 11. Orden de ejecución
Owner construye/normaliza/autovalida → Leonardo revisa → owner corrige → Leonardo otorga APROBADO PARA FIGMA → owner traslada/valida → reporte APROBADO. tasks gestiona avance; reporte registra evidencia.

## 12. Riesgos
Fuentes provisionales (API Admin): no integrar backend; D-REC abiertos: no inferir enriquecimientos; pérdida de borrador: prueba de salida/selector; desvío de DS: medición1440 y captura; dependencia de revisor: entregar artefactos concretos y esperar visto bueno.

## 13. Quality Gates
- A Funcional: inventario/rutas, reglas y fixtures trazables, cero funciones inventadas.
- B UX: UXD/UXG aplicables y LUX justificada.
- C UI: DS/tokens/componentes/stack alineados.
- D PC: 1440, sin overflow, foco/teclado.
- E Revisión: Leonardo, hallazgos cerrados, APROBADO PARA FIGMA formal.
- F Figma/cierre: fidelidad, todas P0 y enlace; entonces reporte APROBADO.
