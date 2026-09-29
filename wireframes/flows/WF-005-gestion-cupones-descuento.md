# WF-005 — Gestión de cupones de descuento

> Fuentes normativas: SPEC-005, HU-005, `DESIGN.md`, `INDEX.md`. Prevalece SPEC → HU → WF.

## 0. Reglas de producción
- Código normalizado con `trim` + mayúsculas.
- Solo promociones `CUPON`.
- Límites global/cliente opcionales.
- Campo vacío de límite por cliente = `Sin límite`.
- Validar compra no consume.
- No exponer controles manuales de consumo/restitución.
- La UI no muestra `CUPON_DUPLICADO`; muestra microcopy de negocio.
- El iniciador externo de consumo no se etiqueta como contrato definitivo.
- Estilo monocromático, sin sombras.

## 1. Metadatos
| Campo | Valor |
|---|---|
| ID | WF-005 |
| Versión | 0.4 |
| Estado | Alineado |
| Responsable | Axel Andree Cueva Alcalá |
| Última actualización | 2026-09-28 |

## 2. Pantallas
S-01 Listado; S-02 Crear/Editar; S-03 Detalle; S-04 Confirmar estado; variantes de carga, vacío, error, permisos y sesión.

## 3. Formulario
| Campo | Regla |
|---|---|
| Código | requerido, único normalizado |
| Promoción | modalidad `CUPON` |
| Monto mínimo | opcional, >0 |
| Límite global | opcional, entero >0 |
| Límite cliente | opcional, entero >0 |
| Restitución | Restaurar / No restaurar |
| Estado | Activo/Inactivo |

El backend representa duplicado con `code=CUPON_DUPLICADO`; la interfaz muestra: **“Este código ya existe. Prueba con uno diferente.”**

## 4. Detalle
Mostrar promoción, compra mínima, límites, consumos y política. Copy obligatorio: **“La validación de una compra no consume usos.”**

## 5. Contratos
`POST /api/v1/cupones/validar` valida sin consumo.

Resultados asíncronos publicados:
- `promotions.coupon.consumption.completed`
- `promotions.coupon.consumption.rejected`

El comando iniciador de Ventas/Postventa permanece pendiente de homologación.

## 6. Responsividad/accesibilidad
320 px sin overflow del body, controles >=44px, foco visible, error asociado y diálogo accesible.

## 7. Registro
v0.4: se incorpora `CUPON_DUPLICADO`, límites opcionales reales y se retira el nombre provisional del iniciador como contrato definitivo.
