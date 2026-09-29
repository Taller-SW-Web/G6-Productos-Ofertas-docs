# WF-007 — Reglas de venta cruzada y upselling

> Fuentes: SPEC-007, HU-007, DESIGN.md, INDEX.md.

## 0. Producción
Diferenciar Cross-sell/Upsell; origen producto/categoría; prioridad y orden positivos; no origen como recomendado; no duplicados; Upsell exige criterio sin valor por defecto; justificación opcional; **no pantalla “Probar recomendaciones”**.

Catálogo de criterios visible:
- Mayor rendimiento
- Mejor material
- Mayor capacidad
- Funcionalidad adicional

## 1. Metadatos
| Campo | Valor |
|---|---|
| ID | WF-007 |
| Versión | 0.7 |
| Estado | Alineado |
| Responsable | Axel Andree Cueva Alcalá |
| Última actualización | 2026-09-28 |

## 2. Pantallas
S-01 Listado; S-02 Crear/Editar; S-02-U Upsell; S-03 Seleccionar recomendado; S-04 Detalle; S-05 cambio de estado.

## 3. Formulario
Nombre, tipo, origen, prioridad, estado, inicio/fin, recomendados, orden; en Upsell criterio obligatorio y justificación opcional.

## 4. Selector
Solo productos activos; excluir origen específico y ya añadidos.

## 5. Detalle
Mostrar orden, criterio/justificación y precio/disponibilidad informativos.

Los criterios deben mostrarse siempre con etiquetas humanas:
- Mayor rendimiento
- Mejor material
- Mayor capacidad
- Funcionalidad adicional

El prototipo no debe renderizar constantes internas como `MAYOR_RENDIMIENTO`, `MEJOR_MATERIAL`, `MAYOR_CAPACIDAD` o `FUNCIONALIDAD_ADICIONAL`. Copy: **“Las recomendaciones no agregan ni reemplazan productos automáticamente.”**

## 6. Estados
Carga, vacío, validación, Upsell incompleto, error, permisos y sesión.

## 7. Responsividad
320 px, controles >=44 px, tarjetas en móvil, foco visible.

## 8. Registro
v0.7 completa S-05 con activación/desactivación navegable y confirmación en el prototipo, manteniendo copy humano.
v0.6 humaniza los criterios de Upsell en formulario y detalle; se eliminan constantes internas de la interfaz visible y del prototipo estático.

v0.5 elimina el simulador administrativo y los criterios inventados fuera del catálogo controlado.
