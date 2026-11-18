// Sonda explícita de lectura. No recibe ni envía credenciales y no sigue redirects.
import https from 'node:https';
import { lookup } from 'node:dns/promises';
import { randomUUID } from 'node:crypto';
import { mkdir, writeFile } from 'node:fs/promises';

const host = 'g6-productos-ofertas.duckdns.org';
const report = { observedAt: new Date().toISOString(), host, browserOrigin: 'https://app.swaggerhub.com', backendSha: null, dns: null, requests: [] };
try { report.dns = await lookup(host, { all: true }); } catch (e) { report.dns = { error: e.code }; }
function redact(value) {
  if (Array.isArray(value)) return value.map(redact);
  if (value && typeof value === 'object') return Object.fromEntries(Object.entries(value).map(([key, v]) => [key, /token|secret|password|authorization|cookie/i.test(key) ? '[REDACTADO]' : redact(v)]));
  return value;
}
async function get(path) {
  const correlationId = randomUUID();
  const started = performance.now();
  const result = await new Promise(resolve => {
    const request = https.get({ hostname: host, path, timeout: 15000, headers: { Origin: report.browserOrigin, 'X-Correlation-Id': correlationId, Accept: 'application/json' } }, response => {
      const chunks = [];
      let bytes = 0;
      const certificate = response.socket.getPeerCertificate();
      const tls = { authorized: response.socket.authorized, subject: certificate.subject, issuer: certificate.issuer, validTo: certificate.valid_to };
      response.on('data', chunk => {
        bytes += chunk.length;
        if (bytes > 1024 * 1024) { request.destroy(new Error('RESPONSE_TOO_LARGE')); return; }
        chunks.push(chunk);
      });
      response.on('end', () => {
        const text = Buffer.concat(chunks).toString('utf8');
        let body;
        try { body = redact(JSON.parse(text)); } catch { body = text.slice(0, 4000); }
        const headers = Object.fromEntries(Object.entries(response.headers).filter(([key]) => ['content-type', 'server', 'x-correlation-id', 'access-control-allow-origin', 'access-control-allow-headers', 'access-control-expose-headers', 'vary'].includes(key)));
        resolve({ method: 'GET', path, status: response.statusCode, headers, body, correlationId, durationMs: Math.round(performance.now() - started), tls, result: 'RESPUESTA_HTTP_NO_ACREDITA_NEGOCIO_NI_JWT' });
      });
    });
    request.on('timeout', () => request.destroy(new Error('TIMEOUT')));
    request.on('error', e => resolve({ method: 'GET', path, correlationId, error: e.code ?? e.message, durationMs: Math.round(performance.now() - started), result: 'NO_VERIFICADO' }));
  });
  report.requests.push(result);
  return result;
}
await get('/api/v1/categorias');
await get('/api/v1/marcas');
const products = await get('/api/v1/productos?canal=MARKETPLACE&pagina=1&tamanio=1');
const items = products.body?.data?.items ?? products.body?.items ?? products.body?.data;
const slug = Array.isArray(items) ? items.find(item => typeof item?.slug === 'string')?.slug : null;
if (products.status === 200 && slug) await get(`/api/v1/productos/por-slug/${encodeURIComponent(slug)}?canal=MARKETPLACE`);
else report.slugTest = 'NO_EJECUTADO: no se obtuvo un slug real de la consulta de productos';
await mkdir('reports', { recursive: true });
await writeFile('reports/runtime.json', JSON.stringify(report, null, 2));
console.log(JSON.stringify({ ...report, requests: report.requests.map(({ body, ...request }) => ({ ...request, bodyType: typeof body })) }, null, 2));
