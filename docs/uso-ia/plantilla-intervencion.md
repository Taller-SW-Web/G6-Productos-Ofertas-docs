# Plantilla de registro de intervención de IA

Copiar este contenido a un documento de intervención cuando exista información para completarlo. Los campos entre llaves son pendientes de completar, no hechos ni resultados. Al guardar una copia en otra carpeta, ajustar sus enlaces relativos.

## 1. Identificación

| Campo | Valor |
|---|---|
| ID del registro | {identificador documental único} |
| Tarea / issue / funcionalidad | {referencia existente} |
| Responsable humano | {nombre confirmado} |
| Fecha de la intervención | {fecha real o desconocida} |
| Fecha de documentación | {fecha en que se prepara este registro} |
| Herramienta / modelo | {herramienta conocida; modelo desconocido si no se conserva} |
| Tipo de aporte | {generación, modificación, revisión, explicación, pruebas o documentación} |
| Base de atribución | {conversación original, reporte existente o declaración del participante} |
| Estado del registro | {completo o parcial; indicar faltantes} |
| Estado operativo, si aplica | {IMPLEMENTAR_AHORA, IMPLEMENTAR_PARCIAL o BLOQUEADO_ESPECÍFICO y su fuente} |

## 2. Objetivo y contexto efectivamente entregado

- Problema y criterio de aceptación: {descripción concreta}.
- Archivos proporcionados o leídos por la IA: {rutas y revisión de cada repositorio}.
- Fuentes aplicables y restricciones: {SPEC/HU/FLOW, DEC-F/ADR, contratos, UX, persistencia y pruebas que correspondan}.
- Frontera pendiente: {operación, owner que debe responder y criterio de desbloqueo, si aplica}.

## 3. Instrucción y evidencia de la sesión

- Naturaleza del texto: {prompt original / resumen retrospectivo confirmado / reconstrucción explicativa}.
- Fuente: {título e ID de conversación, turno, exportación o referencia de acceso}.
- Texto: {instrucción conservada o descripción del objetivo; identificar omisiones}.
- Confirmación humana del resumen, si aplica: {persona y fecha o pendiente}.

Una reconstrucción explicativa no sustituye el prompt original. Si no se conserva la conversación, indicar qué puede explicar el participante y qué queda sin verificar.

## 4. Aporte de IA e intervención humana

| Archivo / componente | Aporte identificado de IA | Decisión o cambio humano | Destino de la propuesta | Evidencia |
|---|---|---|---|---|
| {ruta existente} | {qué generó, corrigió o revisó} | {criterio, edición, aceptación o rechazo confirmado} | {incorporada, modificada, descartada o pendiente} | {diff, conversación, revisión} |

Registrar errores y propuestas descartadas cuando expliquen una corrección relevante. Si no se conoce la autoría de una parte, dejarla sin atribución específica. Distinguir generación por IA de archivos producidos por generadores deterministas.

## 5. Código incorporado

| Repositorio | SHA base | SHA resultante o árbol sin commit | Archivos | Diff / referencia |
|---|---|---|---|---|
| {repositorio real} | {SHA} | {SHA o estado explícito sin commit} | {rutas} | {enlace existente} |

Registrar separadamente versiones de Docs, backend y frontend. No tratar el SHA de la fuente contractual como el SHA del código ejecutado.

## 6. Validación

| Comprobación / comando | Entorno y revisión probada | Resultado | Evidencia | Procedencia |
|---|---|---|---|---|
| {comprobación concreta} | {versión/árbol y entorno} | {PASS, FAIL, OMITIDA o NO EJECUTADA} | {log, reporte, captura o artefacto} | {ejecución de esta intervención o reporte histórico consultado} |

Separar UI con mocks, contrato estático, pruebas aisladas, integración autenticada y E2E. Una prueba definida sin ejecución conserva `NO EJECUTADA`.

## 7. Revisión humana, estado y límites

- Revisor y dictamen: {evidencia de revisión o pendiente}.
- Estado interno / externo / implementación / pruebas / despliegue: {cada estado por separado, si aplica}.
- Qué demuestra este registro: {alcance concreto}.
- Qué información falta: {faltantes y persona que puede aportarlos}.
- Evidencias adjuntas: {rutas o referencias; retirar credenciales y datos privados}.

Volver a la [guía de uso de IA](README.md) y actualizar la [matriz](matriz-trazabilidad.md) cuando se incorpore evidencia relevante.
