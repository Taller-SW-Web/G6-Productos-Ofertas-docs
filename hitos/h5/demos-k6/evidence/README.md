# Evidencia de las demostraciones k6

El ejecutor de Backend genera `summary.json`, `summary.sha256`, `metrics.csv` y el dashboard HTML (si k6 lo soporta) bajo `scripts/h5/k6/.local/<id>/`. Consulta el [esquema y las reglas de comparación del arnés](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/blob/080fda038ea217e1ed5795b7ea6fc5b62d846564/scripts/h5/k6/evidence/README.md).

Los resúmenes identifican el SHA de código, modalidad, operación, versión de k6, dataset y métricas. Conserva reportes crudos fuera de Git y comparte únicamente evidencia saneada. Distingue `L1_FIXTURE_SINTETICO`, `L1_NEST_FIXTURES` y `L2_STAGING_APIM` al presentar resultados.
