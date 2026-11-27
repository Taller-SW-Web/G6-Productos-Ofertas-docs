# Estrategia de Consolidación de PRs: Backend #307 (#305/#306) y Docs #152 (#151)

## 1. Backend — `#307` como candidato único

| PR / Referencia | Rama | HEAD SHA | Estado respecto a `#307` (`18413ac4...`) | Acción recomendada al aprobar release |
|---|---|---|---|---|
| **Base `master`** | `master` | `097dac1bf4a8dcf5c6e799742d2df340f6d893d5` | Ancestro común exacto | Mantener intacto hasta aprobación final |
| **PR Draft #306** | `trabajo/castilla/h5-integracion-pr-pendientes` | `0cd784d575827fd42e91a487f8b68adce5f2220e` | **100% incluido** por merge `--no-ff` (`73b48ca`) preservando autoría de `#300` (Taxonomy), `#297` (Inventory) y `#296` (Promotions) | **NO fusionar por separado**; cerrar como sustituido por `#307` para evitar reincorporar deltas duplicados |
| **PR Draft #305 (parte autónoma)** | `trabajo/castilla/h5-cierre-post-r2-backend` | hasta `523033a0c8fea87cffd546f124921578da245ca9` (`fabf2c43` + `523033a0`) | **100% incluido** por merge `--no-ff` (`c204823`) preservando autoría de Marco Castilla (rollback R02, migración candidata R10 `0002`, candidato APIM base) | **NO fusionar por separado** la parte hasta `523033a0` |
| **PR Draft #305 (delta APIM operativo)** | `trabajo/castilla/h5-cierre-post-r2-backend` | `a26965a0f7aff96eaf1919d2159e90d0ef6d2c67` y `8af53c24bab652dae7edbfb096e2553262897bfe` (16 archivos) | **Deliberadamente fuera de `#307`** pendiente de decisión con Marco Castilla (scripts operativos `Conectar-APIM.ps1`, `Desplegar-APIM.ps1`, `Detener-G6.ps1`, `Eliminar-APIM.ps1`, `Iniciar-G6.ps1`, `Verificar-G6.ps1`, soporte dos etapas Bicep y evidencia Chile) | **Definir con Marco Castilla una sola incorporación:** (A) cherry-pick/merge único de `a26965a0..8af53c24` dentro de `#307` alineando `corsAllowedOrigins` con `https://g6-productos-ofertas.vercel.app` y cerrar `#305`; o (B) fusionar `#307` primero y luego rebasar/actualizar `#305` para contener únicamente el delta APIM operativo |
| **PR Draft #307 (candidato único)** | `trabajo/cueva/h5-cierre-integral` | `18413ac459b24793f4f09ea07104d5281c0be3c7` | **Candidato único Backend** — CI [`#46044277201`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/46044277201) **22/22 PASS** | Único PR Backend a promover a `Ready for review` tras revisión de Castilla/Poma/Taco |

---

## 2. Docs — Relación `#152` sobre `#151` (ambos apuntando a `master`)

- **Base normativa `master`:** `5f30802129ba4bbc0674dcc5878f10065f443118` (`OpenAPI 3.1.0` y `AsyncAPI 3.0.0`, `0.7.0-rc.3`).
- **PR Draft #151 (Marco Castilla):** `trabajo/castilla/h5-cierre-post-r2-docs` (`5969a0ed831b43c5ed398c8a925ffbd7bd3340cc`) — contiene `hitos/h5/cierre-post-r2/*` (evidencia histórica post-R2).
- **PR Draft #152 (Axel Cueva):** `trabajo/cueva/h5-cierre-evidencias-axel` — construido a partir de `5969a0ed` (`#151`) añadiendo exclusivamente `hitos/h5/evidencias/cierre-axel-2026-11-27/*`, preservando 100% intacta la historia y los archivos de `#151`.

### Estrategia explícita de orden/base/consolidación para que el diff aprobado quede limpio

1. **Opción recomendada (orden secuencial sin interferencia):**
   - Paso 1: Revisar y fusionar **Docs `#151`** hacia `master` (conserva autoría e historial de Castilla).
   - Paso 2: Una vez `#151` esté en `master`, el diff de **Docs `#152`** contra `master` mostrará **únicamente** la carpeta `hitos/h5/evidencias/cierre-axel-2026-11-27/` (0 archivos solapados con `#151`), listo para revisión limpia y merge final.
   - *(Opcional mientras `#151` sigue abierto: si Marco Castilla prefiere revisar el diff aislado de `#152` antes del merge de `#151`, basta cambiar temporalmente la base de `#152` a `trabajo/castilla/h5-cierre-post-r2-docs` y regresarla a `master` al fusionar `#151`.)*
2. **Opción alternativa (consolidación directa en un solo merge):**
   - Si Marco Castilla aprueba ambos cortes en una sola revisión, fusionar **Docs `#152`** directamente a `master` (preserva todos los commits de `#151` por ancestría) y cerrar `#151` como incluido en `#152`.
