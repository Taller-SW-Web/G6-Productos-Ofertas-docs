# Fixtures de la suite Postman/Newman — G6 Hito 5

## Principio de seguridad y aislamiento

Esta suite opera en **modo de solo lectura** por defecto y no modifica registros comerciales compartidos en Supabase ni ejecuta importaciones, reservas o consumos de cupones.

Los identificadores utilizados son:

1. **Descubiertos dinamicamente en lectura:** `PM-002` (`GET /api/v1/productos`) captura `productId`, `sku`, `categoryId` y `brandId` del primer producto comercialmente activo disponible para encadenar `PM-003C`, `PM-003D`, `PM-010`, `PM-011`, `PM-012` y `PM-040`.
2. **Parametros de rango de precio (sinteticos y seguros):**
   - `priceMin`: `0`
   - `priceMax`: `100` (rango amplio)
   - `priceMaxNarrow`: `60` (rango acotado para verificar invariante de subconjunto `narrowTotal <= wideTotal`)
3. **Identificadores inexistentes (sinteticos para pruebas negativas 404):**
   - `nonExistentProductId`: `00000000-0000-4000-8000-000000000404`
   - `nonExistentSku`: `SKU-NO-EXISTE-H5-404`
   - `nonExistentBatchId`: `00000000-0000-4000-8000-000000000405`
   - `nonExistentComboId`: `00000000-0000-4000-8000-000000000406`
   - `nonExistentCategoryId`: `00000000-0000-4000-8000-000000000407`
4. **Canal comercial por defecto:** `MARKETPLACE` (valores contractuales validos: `MARKETPLACE`, `CHATBOT`, `RETAIL`, `VENTAS`).

## Restriccion de datos

- Nunca almacene tokens reales, credenciales de G7 ni identificadores sensibles en archivos de fixtures.
- Las pruebas del harness local (`tests/runner.test.mjs`) utilizan un servidor HTTP loopback efimero con datos completamente sinteticos y se etiquetan con `evidenceLevel: ISOLATED`, nunca como `LAB_AZURE`.
