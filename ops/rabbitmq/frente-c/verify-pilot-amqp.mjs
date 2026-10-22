// Smoke local de solo autenticación. No declara, consume ni publica recursos.
import amqp from 'amqplib';
import { readFile } from 'node:fs/promises';

const username = process.argv[2];
const urlText = process.env.RABBITMQ_URL;
if (!username || !urlText) throw new Error('Usage: node verify-pilot-amqp.mjs <g6_identity>; set RABBITMQ_URL in the protected process environment.');

const url = new URL(urlText);
const expectedPort = process.env.G6_AMQP_PORT ?? '5673';
const expectedVhost = process.env.G6_AMQP_VHOST ?? 'g6-productos-ofertas';
const urlVhost = decodeURIComponent(url.pathname.slice(1));
if (url.protocol !== 'amqp:' || url.hostname !== '127.0.0.1' || url.port !== expectedPort || urlVhost !== expectedVhost || decodeURIComponent(url.username) !== username) {
  throw new Error(`RABBITMQ_URL must use identity ${username} and point to 127.0.0.1:${expectedPort}/${expectedVhost}.`);
}

const manifestPath = process.env.G6_RABBITMQ_RBAC_FILE;
if (!manifestPath) throw new Error('The assigned G6 RBAC manifest path is required.');
const manifest = JSON.parse(await readFile(manifestPath, 'utf8'));
if (manifest.vhost !== expectedVhost || !manifest.users.some((entry) => entry.username === username)) {
  throw new Error('Identity or vhost is not assigned by the G6 RBAC manifest.');
}

const options = {
  protocol: 'amqp', hostname: url.hostname, port: Number(url.port),
  username, password: decodeURIComponent(url.password), vhost: urlVhost, heartbeat: 10,
  clientProperties: { connection_name: 'g6-developer-auth-smoke' },
};
const connection = await amqp.connect(options);
await connection.close();
console.log(JSON.stringify({ authentication: 'PASS', identity: username, vhost: expectedVhost, operations: 'none' }));
