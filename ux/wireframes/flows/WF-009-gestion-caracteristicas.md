# WF-009 — Gestión de características y sus valores

> Fuentes: SPEC-009, HU-009, DESIGN.md, INDEX.md.

## 0. Producción
- Tipos exactos `TEXTO`, `NUMERO`, `LISTA`.
- TEXTO: límite inicial 100.
- NUMERO: unidad obligatoria.
- LISTA: límite inicial 50 activos.
- Tipo inmutable.
- Renombrado conserva ID.
- Esquema de producto depende del **tipo de producto**, nunca de categoría.
- Baja de valor LISTA no es inmediata: mostrar `Comprobando uso`.
- Ante uso activo o falta de confirmación, conservar el valor.
- El `202 Accepted` de la baja significa solo admisión: nunca `Completado`.
- La característica completa se desactiva/reactiva sin cambiar su ID; una inactiva no aparece entre las características ofrecibles para nuevas asociaciones.
- El renombrado confirmado publica `taxonomy.characteristic-value.updated`; la baja segura usa el flujo transversal de entidad maestra para `CHARACTERISTIC_VALUE`.
- No CRUD de marcas/asociaciones.

## 1. Metadatos
| Campo | Valor |
|---|---|
| ID | WF-009 |
| Versión | 0.8 |
| Estado | Alineado |
| Responsable | Leonardo Lopez |
| Última actualización | 2026-10-01 |

## 2. Trazabilidad HU
- CA-01: reglas TEXTO.
- CA-02: NUMERO/unidad.
- CA-03: LISTA/límite.
- CA-04 y CA-06: renombrado/propagación por ID.
- CA-05: detalle/consulta.
- CA-07: frontera con WF-010/WF-011.
- CA-08: tipo inmutable.
- CA-09/CA-10: baja segura de valor y admisión HTTP.
- CA-11/CA-12: estado de característica y oferta de nuevas asociaciones.

No se delegan erróneamente CA-05/06/08/09 a otros wireframes.

## 3. Pantallas
S-01 listado; S-02 crear; S-03 editar; S-04 valores LISTA; S-04-P comprobando uso; S-04-R rechazo; S-05 estado de característica; S-06 detalle.

## 4. Baja de valor LISTA
1. Confirmar intención.
2. `Comprobando uso en productos`.
3. Mantener valor sin baja confirmada.
4. Resultado seguro → Inactivo.
5. En uso → rechazo.
6. Error/no confirmación → sin cambio.

## 4.1 Estado de la característica completa
1. Acción `Desactivar característica` o `Reactivar característica`.
2. El diálogo aclara que el identificador se conserva.
3. Tras la operación, el listado mantiene la misma fila y muestra el nuevo estado.
4. Una característica inactiva no se lista entre las candidatas para nuevas asociaciones.

## 5. Copy
- `Los valores de producto se validan según el tipo de producto asociado.`
- `Este valor se está comprobando y temporalmente no está disponible para nuevas asignaciones.`
- `No pudimos confirmar que la baja sea segura. No se realizó ningún cambio.`
- `Esta característica está inactiva y no está disponible para nuevas asociaciones.`

## 6. Responsividad/accesibilidad
320px, 44px, foco visible, modal accesible y estados anunciados con texto.

## 7. Registro
v0.8 incorpora la desactivación/reactivación lógica de la característica completa con ID conservado, la lectura del `202 Accepted` como admisión y la no oferta de características inactivas para nuevas asociaciones.
v0.7 completa el prototipo con alta, edición, detalle, valores LISTA, renombrado, baja segura y cambio de estado; los tipos se muestran con etiquetas humanas.
v0.6 formaliza la propagación `taxonomy.characteristic-value.updated` y alinea la baja segura de `CHARACTERISTIC_VALUE` con el AsyncAPI 0.4.0.

v0.5 corrige trazabilidad CA, elimina la referencia a formularios “por categoría” y representa baja asíncrona segura.
