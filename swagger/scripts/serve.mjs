import http from 'node:http';
import { readFile } from 'node:fs/promises';
import { resolve, sep, extname } from 'node:path';
const root = resolve('dist');
const types = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.css': 'text/css', '.json': 'application/json', '.yaml': 'application/yaml' };
http.createServer(async (req, res) => {
  try {
    const path = resolve(root, '.' + decodeURIComponent(new URL(req.url, 'http://localhost').pathname));
    if (path !== root && !path.startsWith(root + sep)) throw Error();
    const file = path === root ? resolve(root, 'index.html') : path;
    res.setHeader('Content-Type', types[extname(file)] ?? 'text/plain');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.end(await readFile(file));
  } catch { res.writeHead(404); res.end('No encontrado'); }
}).listen(8080, '127.0.0.1', () => console.log('Swagger local: http://127.0.0.1:8080'));
