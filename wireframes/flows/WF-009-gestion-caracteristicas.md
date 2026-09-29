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
- El renombrado confirmado publica `taxonomy.characteristic-value.updated`; la baja segura usa el flujo transversal de entidad maestra para `CHARACTERISTIC_VALUE`.
- No CRUD de marcas/asociaciones.

## 1. Metadatos
| Campo | Valor |
|---|---|
| ID | WF-009 |
| Versión | 0.7 |
| Estado | Alineado |
| Responsable | Leonardo Lopez |
| Última actualización | 2026-09-28 |

## 2. Trazabilidad HU
- CA-01: reglas TEXTO.
- CA-02: NUMERO/unidad.
- CA-03: LISTA/límite.
- CA-04 y CA-06: renombrado/propagación por ID.
- CA-05: detalle/consulta.
- CA-07: frontera con WF-010/WF-011.
- CA-08: tipo inmutable.
- CA-09/CA-10: baja segura de valor.
- CA-11: estado de característica.

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

## 5. Copy
- `Los valores de producto se validan según el tipo de producto asociado.`
- `Este valor se está comprobando y temporalmente no está disponible para nuevas asignaciones.`
- `No pudimos confirmar que la baja sea segura. No se realizó ningún cambio.`

## 6. Responsividad/accesibilidad
320px, 44px, foco visible, modal accesible y estados anunciados con texto.

## 7. Registro
v0.7 completa el prototipo con alta, edición, detalle, valores LISTA, renombrado, baja segura y cambio de estado; los tipos se muestran con etiquetas humanas.
v0.6 formaliza la propagación `taxonomy.characteristic-value.updated` y alinea la baja segura de `CHARACTERISTIC_VALUE` con el AsyncAPI 0.2.1-p0.

v0.5 corrige trazabilidad CA, elimina la referencia a formularios “por categoría” y representa baja asíncrona segura.
