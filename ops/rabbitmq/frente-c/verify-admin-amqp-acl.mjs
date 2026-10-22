// Active ACL test. Invoke only from Test-G6OnboardingAmqp.ps1 after its queue snapshots.
import amqp from 'amqplib';
import { readFile } from 'node:fs/promises';

if (process.argv[2] !== '--admin-acl' || process.env.G6_ADMIN_ACTIVE_TEST !== '1' || process.env.G6_ADMIN_ISOLATION_VERIFIED !== '1' || !process.env.G6_ADMIN_RUN_ID) {
  throw new Error('Active ACL tests require the explicit administrative mode and verified queue-isolation preconditions.');
}
const username = process.argv[3];
const urlText = process.env.RABBITMQ_URL;
if (!username || !urlText) throw new Error('Provide one G6 identity and set RABBITMQ_URL in the protected process environment.');

const url = new URL(urlText);
const expectedPort = process.env.G6_AMQP_PORT ?? '5673';
const expectedVhost = process.env.G6_AMQP_VHOST ?? 'g6-productos-ofertas';
if (url.protocol !== 'amqp:' || url.hostname !== '127.0.0.1' || url.port !== expectedPort || decodeURIComponent(url.pathname.slice(1)) !== expectedVhost || decodeURIComponent(url.username) !== username) {
  throw new Error('RABBITMQ_URL does not match the assigned identity, vhost, and isolated local tunnel.');
}
const manifestPath = process.env.G6_RABBITMQ_RBAC_FILE;
if (!manifestPath) throw new Error('The assigned G6 RBAC manifest path is required.');
const manifest = JSON.parse(await readFile(manifestPath, 'utf8'));
const account = manifest.users.find((entry) => entry.username === username);
if (!account || manifest.vhost !== expectedVhost) throw new Error('Identity or vhost is not assigned by the G6 RBAC manifest.');

const options = {
  protocol: 'amqp', hostname: url.hostname, port: Number(url.port), username,
  password: decodeURIComponent(url.password), vhost: expectedVhost, heartbeat: 10,
  clientProperties: { connection_name: `g6-admin-acl-${process.env.G6_ADMIN_RUN_ID}` },
};
const runId = process.env.G6_ADMIN_RUN_ID;
const badKey = `frontc.unauthorized.${runId.replaceAll('-', '')}`;
async function connect() { return amqp.connect(options); }
async function expectDenied(action) {
  let conn; let ch;
  try {
    conn = await connect(); ch = await conn.createChannel();
    let failure;
    const closed = new Promise((resolve) => ch.once('close', resolve));
    ch.on('error', (error) => { failure = error; });
    await action(ch);
    await Promise.race([closed, new Promise((resolve) => setTimeout(resolve, 500))]);
    if (!failure || !/ACCESS_REFUSED|403/.test(`${failure.code ?? ''} ${failure.message ?? ''}`)) throw new Error('Expected a broker ACCESS_REFUSED response for a denied operation.');
    return 'PASS';
  } catch (error) {
    if (/ACCESS_REFUSED|403/.test(`${error?.code ?? ''} ${error?.message ?? ''}`)) return 'PASS';
    throw error;
  } finally { await ch?.close().catch(() => {}); await conn?.close().catch(() => {}); }
}

const report = { runId, username, vhost: expectedVhost, testMode: 'admin-active-acl' };
let conn = await connect();
try {
  const ch = await conn.createChannel();
  const ownMessage = await ch.get(account.queue, { noAck: false });
  if (ownMessage) {
    ch.nack(ownMessage, false, true);
    throw new Error('Own queue was non-empty during the isolated ACL test; message was requeued.');
  }
  report.ownQueueRead = 'PASS';
} finally { await conn.close(); }

const otherQueue = manifest.users.find((entry) => entry.username !== username).queue;
report.crossQueueReadDenied = await expectDenied((ch) => ch.get(otherQueue, { noAck: false }));
report.configureDenied = await expectDenied((ch) => ch.assertQueue(account.queue, { durable: true, arguments: { 'x-queue-type': 'quorum' } }));
report.unauthorizedRoutingKeyDenied = await expectDenied((ch) => ch.publish(account.test_publish?.exchange ?? 'po.eventos.x', badKey, Buffer.from(`G6-ADMIN-NEGATIVE ${runId}`), { mandatory: true }));
report.unapprovedExchangeDenied = await expectDenied((ch) => ch.publish('po.sin-ruta.x', 'frontc.denied', Buffer.from(`G6-ADMIN-NEGATIVE ${runId}`), { mandatory: true }));
report.defaultExchangeDenied = await expectDenied((ch) => ch.publish('', account.queue, Buffer.from(`G6-ADMIN-NEGATIVE ${runId}`), { mandatory: true }));

if (!account.test_publish) {
  report.authorizedPublication = 'NO_APLICA'; report.publisherConfirm = 'NO_APLICA';
} else {
  const marker = `g6-admin-${runId}-${username}`;
  conn = await connect();
  try {
    const ch = await conn.createConfirmChannel(); let returned = false;
    ch.on('return', (message) => { if (message.properties.messageId === marker) returned = true; });
    await new Promise((resolve, reject) => ch.publish(account.test_publish.exchange, account.test_publish.routing_key,
      Buffer.from(`G6-ADMIN-SYNTHETIC ${runId} ${username}`),
      { messageId: marker, correlationId: runId, contentType: 'text/plain', persistent: true, mandatory: true,
        expiration: '2000', headers: { 'x-g6-test': 'admin-active-acl', 'x-test-run': runId } },
      (error) => error ? reject(error) : resolve()));
    await new Promise((resolve) => setTimeout(resolve, 50));
    if (returned) throw new Error('The authorized routing key was returned by the broker.');
    await ch.close(); report.authorizedPublication = 'PASS'; report.publisherConfirm = 'PASS';
    report.syntheticMessageId = marker; report.expirationMs = 2000;
  } finally { await conn.close(); }
}

conn = await connect(); await conn.close();
conn = await connect(); report.reconnect = 'PASS'; await conn.close();
console.log(JSON.stringify(report, null, 2));
