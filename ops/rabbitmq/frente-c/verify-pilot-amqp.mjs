// Verificación de una sola identidad desde el PC conectado por túnel.
// No imprime RABBITMQ_URL ni contraseña. Instalar amqplib en un directorio temporal.
import amqp from 'amqplib';
import { readFile } from 'node:fs/promises';
import { randomUUID } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const username = process.argv[2];
const urlText = process.env.RABBITMQ_URL;
if (!username || !urlText) throw new Error('Usage: node verify-pilot-amqp.mjs <g6_identity>; set RABBITMQ_URL in the protected process environment.');

const url = new URL(urlText);
const expectedPort = process.env.G6_AMQP_PORT ?? '5673';
if (url.protocol !== 'amqp:' || url.hostname !== '127.0.0.1' || url.port !== expectedPort || decodeURIComponent(url.pathname.slice(1)) !== 'g6-productos-ofertas') {
  throw new Error(`RABBITMQ_URL must point to 127.0.0.1:${expectedPort}/g6-productos-ofertas.`);
}

const here = path.dirname(fileURLToPath(import.meta.url));
const manifestPath = process.env.G6_RABBITMQ_RBAC_FILE ?? path.resolve(here, '../rbac-rc3.json');
const manifest = JSON.parse(await readFile(manifestPath, 'utf8'));
const account = manifest.users.find((entry) => entry.username === username);
if (!account) throw new Error('Identity is not present in the rc.3 RBAC manifest.');
const runId = randomUUID();
const badKey = `frontc.unauthorized.${runId.replaceAll('-', '')}`;
const credentials = { username: decodeURIComponent(url.username), password: decodeURIComponent(url.password) };
const options = {
  protocol: 'amqp', hostname: url.hostname, port: Number(url.port),
  username: credentials.username, password: credentials.password,
  vhost: decodeURIComponent(url.pathname.slice(1)), heartbeat: 10,
  clientProperties: { connection_name: `g6-frontc-pilot-${runId}` },
};

async function connect() { return amqp.connect(options); }

async function expectDenied(action) {
  let conn;
  let ch;
  try {
    conn = await connect();
    ch = await conn.createChannel();
    let failure;
    const closed = new Promise((resolve) => ch.once('close', resolve));
    ch.on('error', (error) => { failure = error; });
    await action(ch);
    await Promise.race([closed, new Promise((resolve) => setTimeout(resolve, 500))]);
    if (!failure) throw new Error('An unauthorized operation unexpectedly succeeded.');
    if (!/ACCESS_REFUSED|403/.test(`${failure.code ?? ''} ${failure.message ?? ''}`)) throw new Error('The broker closed the channel for a reason other than ACCESS_REFUSED.');
    return 'PASS';
  } catch (error) {
    if (/ACCESS_REFUSED|403/.test(`${error?.code ?? ''} ${error?.message ?? ''}`)) return 'PASS';
    throw error;
  } finally {
    await ch?.close().catch(() => {});
    await conn?.close().catch(() => {});
  }
}

const report = { runId, username, vhost: 'g6-productos-ofertas' };
let conn = await connect();
report.authentication = 'PASS';
try {
  const ch = await conn.createChannel();
  const ownMessage = await ch.get(account.queue, { noAck: false });
  if (ownMessage) {
    ch.nack(ownMessage, false, true);
    throw new Error(`Own queue ${account.queue} became non-empty during the test; the message was requeued.`);
  }
  report.ownQueueRead = 'PASS';
} finally { await conn.close(); }

const otherQueue = manifest.users.find((entry) => entry.username !== username).queue;
report.crossQueueReadDenied = await expectDenied((ch) => ch.get(otherQueue, { noAck: false }));
report.configureDenied = await expectDenied((ch) => ch.assertQueue(account.queue, { durable: true, arguments: { 'x-queue-type': 'quorum' } }));
report.unauthorizedRoutingKeyDenied = await expectDenied((ch) => ch.publish(
  account.test_publish?.exchange ?? 'po.eventos.x', badKey,
  Buffer.from(`G6-FRONT-C-NEGATIVE ${runId}`), { mandatory: true },
));
report.unapprovedExchangeDenied = await expectDenied((ch) => ch.publish(
  'po.sin-ruta.x', 'frontc.denied', Buffer.from(`G6-FRONT-C-NEGATIVE ${runId}`), { mandatory: true },
));
report.defaultExchangeDenied = await expectDenied((ch) => ch.publish(
  '', account.queue, Buffer.from(`G6-FRONT-C-NEGATIVE ${runId}`), { mandatory: true },
));

if (process.env.G6_SKIP_AUTHORIZED_PUBLISH === '1' && account.test_publish) {
  report.authorizedPublication = 'NOT_RUN_BY_LOCAL_SMOKE';
  report.publisherConfirm = 'NOT_RUN_BY_LOCAL_SMOKE';
} else if (!account.test_publish) {
  report.authorizedPublication = 'NO_APLICA';
  report.publisherConfirm = 'NO_APLICA';
} else {
  const marker = `g6-frontc-${runId}-${username}`;
  conn = await connect();
  try {
    const ch = await conn.createConfirmChannel();
    let returned = false;
    ch.on('return', (message) => { if (message.properties.messageId === marker) returned = true; });
    await new Promise((resolve, reject) => ch.publish(
      account.test_publish.exchange, account.test_publish.routing_key,
      Buffer.from(`G6-FRONT-C-SYNTHETIC ${runId} ${username}`),
      { messageId: marker, correlationId: runId, contentType: 'text/plain', persistent: true,
        mandatory: true, expiration: '2000', headers: { 'x-g6-test': 'front-c-pilot', 'x-test-run': runId } },
      (error) => error ? reject(error) : resolve(),
    ));
    await new Promise((resolve) => setTimeout(resolve, 50));
    if (returned) throw new Error('The authorized routing key was returned by the broker.');
    await ch.close();
    report.authorizedPublication = 'PASS';
    report.publisherConfirm = 'PASS';
    report.syntheticMessageId = marker;
    report.expirationMs = 2000;
  } finally { await conn.close(); }
}

conn = await connect();
await conn.close();
conn = await connect();
report.reconnect = 'PASS';
await conn.close();
console.log(JSON.stringify(report, null, 2));
