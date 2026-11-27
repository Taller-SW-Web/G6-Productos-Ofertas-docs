# Baseline Azure de solo lectura

Captura inicial: `DEPLOY_BASELINE.json`, obtenida por `az containerapp list` con proyección explícita de nombre, región, estado, revisión, FQDN, ingress, puerto, tráfico e imagen; `az servicebus queue list` proyectó nombre/estado. No se guardaron variables, secretos ni connection strings.

Suscripción `fef42188-accd-4470-ae88-78f583eb4906` (Azure for Students), grupo `rg-g6-aca-chile`, región real `chilecentral`. El Gateway `api-gateway--0000003` recibió 100 % del tráfico y `api-gateway--0000002` conservó etiqueta `g5-h5` con peso 0 %. Los ocho servicios tenían ingress `external=false`; Gateway tenía `external=true`. El digest Gateway observado comenzó por `sha256:2ab58ef9` (completo en JSON).

Sondas de bajo impacto al Gateway vigente: `GET /health` → 200; `GET /api/v1/productos?pagina=1&tamanio=1` sin token → 401 y `X-Correlation-Id=b29d71c5-dac0-4a93-b90a-9ca34cac60ae`. `/health/live` y `/health/ready` respondieron 404; no se confunden con fallo del servicio, pues el controlador público expone `/health`. No se enviaron escrituras ni credenciales.

La segunda captura y comparación se documentan en `19_NO_DEPLOY_ATTESTATION.md`. Una igualdad de proyecciones prueba solo los campos inventariados, no la ausencia de cambios ajenos fuera de ellos.
