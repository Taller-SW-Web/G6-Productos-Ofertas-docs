# Demo de k6 — G6 Hito 5

Esta carpeta conserva la documentación y el guion de la demo. La implementación ejecutable está en el repositorio Backend, en `scripts/h5/k6/`. El [README de Backend](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/blob/829b51aa69d03201d59b5e99e2e3e08a63810090/scripts/h5/k6/README.md) contiene los comandos PowerShell, requisitos, perfiles y controles de seguridad.

- [Guion de exposición](GUIA_EXPOSICION.md) para mostrar el dashboard nativo y explicar los resultados.
- [Matriz de casos y estado](MATRIZ_K6.md) para distinguir fixture local, servicios aislados y pruebas pendientes en APIM.
- [Formato de evidencia](evidence/README.md) para ubicar los reportes y verificar su procedencia.

El flujo empieza por PERF-01 de Catálogo en loopback. PERF-02 y PERF-03 pueden repetirse con los servicios Nest y sus dependencias controladas. Ejecuta los comandos desde Backend, en la revisión indicada por su PR. El resultado local es evidencia L1 y se registra por separado de [la certificación H5-03](../03_PRUEBAS_DE_PERFORMANCE.md).
