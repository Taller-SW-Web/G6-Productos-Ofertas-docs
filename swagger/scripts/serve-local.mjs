import http from 'node:http';
import { readFile } from 'node:fs/promises';
import { extname } from 'node:path';
const root = new URL('../dist/', import.meta.url);
const files = new Set(['index.html', 'portal.js', 'portal.css', 'swagger-ui-bundle.js', 'swagger-ui.css', 'openapi.json', 'openapi.yaml', 'manifest.json', 'LICENSE', 'NOTICE']);
const types = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.css': 'text/css', '.json': 'application/json', '.yaml': 'application/yaml' };
http.createServer(async (req, res) => {
  try {
    if (!['GET', 'HEAD'].includes(req.method)) { res.writeHead(405, { Allow: 'GET, HEAD' }); res.end(); return; }
    const pathname = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
    const name = pathname === '/' ? 'index.html' : pathname.slice(1);
    if (!files.has(name)) throw Error();
    const file = new URL(name, root);
    res.setHeader('Content-Type', types[extname(name)] ?? 'text/plain');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('Cache-Control', 'no-store');
    const content = await readFile(file);
    res.end(req.method === 'HEAD' ? undefined : content);
  } catch { res.writeHead(404); res.end('No encontrado'); }
}).on('error', error => { console.error(`No se pudo iniciar Swagger local: ${error.code}`); process.exitCode = 1; })
  .listen(8080, '127.0.0.1', () => console.log('Swagger local: http://localhost:8080 (solo loopback 127.0.0.1)'));
