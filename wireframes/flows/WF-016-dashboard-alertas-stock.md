# WF-016 — Dashboard analítico y alertas de stock

> Fuentes: SPEC-016, HU-016, DESIGN.md, INDEX.md.

## 0. Producción
- Solo lectura.
- SKU vendible = unidad operativa.
- Estados deterministas con `available`.
- Filtros: producto/categoría/marca/SKU/ubicación/**estado**.
- Consumir `inventory.stock.changed`.
- **Nunca emitir ese evento desde el dashboard.**
- No usar botón/atajo/doble clic para modificar saldos en el prototipo.
- Un escenario documental puede abrirse con `?state=event-received` para representar la pantalla *después de recibir* un hecho, sin convertirlo en acción del usuario.
- Sin ventas/Top productos.

## 1. Metadatos
| Campo | Valor |
|---|---|
| ID | WF-016 |
| Versión | 0.6 |
| Estado | Alineado |
| Responsable | Miguel Ángel Taco Zavala |
| Última actualización | 2026-09-28 |

## 2. Pantalla
S-01 Dashboard; S-01-E vacío/error; S-01-U variante posterior a actualización recibida.

## 3. Regiones
1. Filtros.
2. KPIs.
3. Alertas.
4. Distribución por ubicación.

## 4. Filtro de estado
Opciones:
- Todos;
- Disponible;
- Stock bajo;
- Agotado.

Debe filtrar realmente el listado/proyección del prototipo.

## 5. Actualización reactiva
Copy después de recibir un evento:

> Inventario confirmó un cambio de stock. Los indicadores se recalcularon con el saldo vigente.

No mostrar `Emitir evento`, `Actualizar stock`, `Consumir` ni equivalentes.

## 6. Responsividad/accesibilidad
320px, controles 44px, tabla contenida/tarjetas, `aria-live` para cambios recibidos.

## 7. Registro
v0.6 añade la región explícita de alertas de Stock bajo/Agotado derivada del inventario filtrado, sin introducir acciones de mutación.
v0.5 elimina la simulación de emisión/mutación y consolida el filtro de estado.
