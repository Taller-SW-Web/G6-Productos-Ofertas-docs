# Estrategia de Consolidación de PRs: Backend #307 (#305/#306) y Docs #152 (#151)

## 1. Backend — `#307` como candidato único

| PR / Referencia | Rama | HEAD SHA | Estado respecto a `#307` (`18413ac4...`) | Acción recomendada al aprobar release |
|---|---|---|---|---|
| **Base `master`** | `master` | `097dac1bf4a8dcf5c6e799742d2df340f6d893d5` | Ancestro común exacto | Mantener intacto hasta aprobación final |
| **PR Draft #306** | `trabajo/castilla/h5-integracion-pr-pendientes` | `0cd784d575827fd42e91a487f8b68adce5f2220e` | **100% incluido** por merge `--no-ff` (`73b48ca`) preservando autoría de `#300` (Taxonomy), `#297` (Inventory) y `#296` (Promotions) | **NO fusionar por separado**; cerrar como sustituido por `#307` para evitar reincorporar deltas duplicados |
| **PR Draft #305 (parte autónoma)** | `trabajo/castilla/h5-cierre-post-r2-backend` | hasta `523033a0c8fea87cffd546f124921578da245ca9` (`fabf2c43` + `523033a0`) | **100% incluido** por merge `--no-ff` (`c204823`) preservando autoría de Marco Castilla (rollback R02, migración candidata R10 `0002`, candidato APIM base) | **NO fusionar por separado** la parte hasta `523033a0` |
| **PR Draft #305 (delta APIM operativo)** | `trabajo/castilla/h5-cierre-post-r2-backend` | `a26965a0` y `8af53c24` | Incorporado una sola vez a #307 en `7ecee3f`. | Revisar el candidato #307. Resolver #305 como absorbido tras autorización del release. |
| **PR Draft #307 (candidato único)** | `trabajo/cueva/h5-cierre-integral` | `f3cc10d604050d9346e0d9934cd7867121dbe166` | [CI #46060439353](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/46060439353), Trivy 9/9 con cero críticos/altos | Único PR Backend a revisión final. |

---

## 2. Docs — Relación `#152` sobre `#151` (ambos apuntando a `master`)

- **Base normativa `master`:** `5f30802129ba4bbc0674dcc5878f10065f443118` (`OpenAPI 3.1.0` y `AsyncAPI 3.0.0`, `0.7.0-rc.3`).
- **PR Draft #151 (Marco Castilla):** `trabajo/castilla/h5-cierre-post-r2-docs` (`5969a0ed831b43c5ed398c8a925ffbd7bd3340cc`) — contiene `hitos/h5/cierre-post-r2/*` (evidencia histórica post-R2).
- **PR Draft #152 (Axel Cueva):** `trabajo/cueva/h5-cierre-evidencias-axel` — construido a partir de `5969a0ed` (`#151`) añadiendo exclusivamente `hitos/h5/evidencias/cierre-axel-2026-11-27/*`, preservando 100% intacta la historia y los archivos de `#151`.

### Consolidación al aprobar el release

Revisar los dos cortes en #152 y hacer un único merge que conserve commits y autoría de #151. Cerrar #151 como incluido después de confirmar la ancestría y la aprobación final. Mantener ambos PR Draft durante la revisión.
