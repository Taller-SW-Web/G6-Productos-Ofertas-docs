# WF-014 — Historial de auditoría de precios

> Fuentes: SPEC-014, HU-014, DESIGN.md, INDEX.md.

## 0. Producción
- Solo lectura.
- Filtros SKU/fechas/usuario/canal/lote.
- CSV <=100,000; PDF <=500.
- `CREACION`: mostrar “Sin precio anterior” y “No aplicable”.
- `RETIRO_OFERTA`: mostrar “Sin oferta” y “No aplicable”.
- Nunca convertir nulos en S/ 0.00.
- La UI no muestra los nombres de permisos pendientes.
- No afirmar sello criptográfico ni mecanismo de integridad no definido.
- Estilo monocromático.

## 1. Metadatos
| Campo | Valor |
|---|---|
| ID | WF-014 |
| Versión | 0.6 |
| Estado | Alineado |
| Responsable | Leonardo Vera Rodríguez |
| Última actualización | 2026-09-28 |

## 2. Pantallas
S-01 listado/filtros; S-02 detalle; S-02-N detalle no encontrado; S-03 exportar CSV; S-04 exportar PDF; variantes de generación, listo, límite, error, permisos y sesión.

## 3. Semántica visible
`null` tiene significado de dominio:
- sin precio anterior;
- sin oferta;
- no aplicable.

La tabla y detalle deben usar funciones de formato tolerantes a `null`.

## 3.1. Etiquetas visibles de dominio
La UI debe traducir valores internos a lenguaje operativo. Como mínimo:

| Valor interno | Etiqueta visible |
|---|---|
| `MODIFICACION` | Modificación de precio |
| `CREACION` | Creación de precio |
| `RETIRO_OFERTA` | Retiro de oferta |
| `BACKOFFICE` | Gestión interna |
| `BULK_IMPORT` | Carga masiva |
| `API` | Integración externa |
| `REGULAR` | Precio regular |
| `OFERTA` | Oferta |

Estas constantes pertenecen al contrato/dominio y no deben aparecer como copy para el usuario final.

## 4. Seguridad
Copy: `No tienes permiso para consultar esta información.`  
No renderizar códigos `PRICING_AUDIT_*` hasta homologación.

## 5. Exportación
CSV asíncrono hasta 100,000 filas. PDF limitado a 500. Si se supera el máximo, no mostrar una exportación como creada: mantener al usuario en el flujo y explicar que debe acotar filtros o elegir un formato compatible. No renderizar el código técnico `LIMITE_EXPORTACION_AUDITORIA_EXCEDIDO`. Sin sellos/garantías criptográficas no documentadas.

## 5.1. Detalle inexistente
Si el registro consultado ya no existe o el identificador no es válido para un asiento disponible, mostrar `No encontramos este registro de auditoría` y ofrecer volver al listado. La interfaz no expone `AUDITORIA_PRECIO_NO_ENCONTRADA` como texto de usuario.

## 6. Registro
v0.6 humaniza operaciones, tipos de precio y origen del cambio; los enums internos dejan de mostrarse en filtros, tabla y detalle.

v0.5 alinea los estados de detalle inexistente y exceso de exportación con los códigos HTTP canónicos, manteniendo copy humano en la UI.
v0.4 corrige permisos pendientes y representación de alta/retiro de oferta.
