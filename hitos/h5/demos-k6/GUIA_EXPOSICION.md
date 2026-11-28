# Guion en vivo (6 minutos)

Abre un PowerShell en la raíz de Backend, en la rama de integración de k6. Usa los [comandos de Backend](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/blob/080fda038ea217e1ed5795b7ea6fc5b62d846564/scripts/h5/k6/README.md) para la demo local de Catálogo, con `--dashboard`. Deja el manifiesto privado y el token fuera de pantalla.

| Tiempo | Qué mostrar | Qué decir |
|---|---|---|
| 0:00–0:45 | Matriz y caso PERF-01. | Medimos una lectura GET de Catálogo con un conjunto de productos conocido. El alcance local es `L1_FIXTURE_SINTETICO`. |
| 0:45–1:30 | PowerShell con preflight. | Comprueba SHA, dataset, ventana y perfil. `NO_EJECUTADO` identifica un preflight sin medición. |
| 1:30–2:45 | Demo de 1 VU y dashboard en http://127.0.0.1:5665. | Un VU repite la lectura. RPS son solicitudes por segundo y p95 es el tiempo por debajo del cual se completó aproximadamente el 95% de las lecturas medidas. |
| 2:45–3:45 | Cierra la pestaña y abre el resumen saneado. | Enseña casos válidos, latencias y errores. El 401 de la prueba negativa aparece separado del throughput. |
| 3:45–4:45 | Evidencia. | Muestra el SHA del arnés, el hash del dataset, la versión de k6 y el alcance. El HTML exportado permite presentar la corrida después. |
| 4:45–6:00 | Pricing e Inventario. | Distingue los controladores Nest locales con fixtures del recorrido en Azure. Explica qué hace falta para comparar baseline/candidato y para correr en APIM. |

Ten listo el HTML de una corrida local previa como respaldo. El perfil de 5 VU requiere una ventana autorizada.
