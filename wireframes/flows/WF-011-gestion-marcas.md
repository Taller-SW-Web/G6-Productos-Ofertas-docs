# WF-011 — Gestión de marcas

> Fuentes: SPEC-011, HU-011, DESIGN.md, INDEX.md.

## 0. Reglas
- Nombre único entre activas e inactivas.
- PNG/JPG/JPEG/WebP <=5 MB.
- País mediante selector ISO 3166-1.
- Baja: Solicitud recibida → Verificando productos → Confirmada/Rechazada.
- No cronómetro ni “timeout de N segundos”.
- No eliminación física.
- Acceso descrito de forma genérica; no rol global inventado.
- Estilo monocromático.

## 1. Metadatos
| Campo | Valor |
|---|---|
| ID | WF-011 |
| Versión | 0.4 |
| Estado | Alineado |
| Responsable | Leonardo Lopez |
| Última actualización | 2026-09-28 |

## 2. Pantallas
S-01 listado; S-02 crear; S-03 editar; S-04 confirmar baja; S-04-P verificando; S-04-B bloqueada; S-04-E no concluyente; S-05 detalle.

## 3. Formulario
Nombre requerido. Descripción, logo y país opcionales. `accept` restringido a formatos permitidos. País se persiste como código ISO.

## 4. Baja
La marca no cambia de estado al iniciar la comprobación. Productos activos, error o falta de confirmación conservan Activo.

## 5. EDA
Usar el protocolo transversal de entidad maestra; no inventar un evento específico de marca.

## 6. Accesibilidad/responsive
320 px, controles 44 px, foco, diálogo y mensajes textuales.

## 7. Registro
v0.4 corrige unicidad, formato de archivo, país ISO y elimina timeout/rol no homologados.
