// Smoke G5. Solo ejecutar después de homologación y de una ventana aislada aprobada.
// No consume mensajes: checkQueue valida autorización read y requiere cola vacía/sin consumidores.
import amqp from 'amqplib';
import { randomUUID } from 'node:crypto';
import net from 'node:net';

const expectedUser='g5_ventas', vhost='g6-productos-ofertas', localPort='5673';
const urlText=process.env.RABBITMQ_URL;
if(!urlText) throw new Error('Set RABBITMQ_URL in process environment; never pass it on the command line.');
const url=new URL(urlText);
if(url.protocol!=='amqp:'||url.hostname!=='127.0.0.1'||url.port!==localPort||decodeURIComponent(url.pathname.slice(1))!==vhost||decodeURIComponent(url.username)!==expectedUser) throw new Error('RABBITMQ_URL must use the expected G5 identity, loopback tunnel, port and vhost.');
const runId=randomUUID(), badKey=`g5.denied.${runId.replaceAll('-','')}`;
const opts={protocol:'amqp',hostname:'127.0.0.1',port:Number(localPort),username:decodeURIComponent(url.username),password:decodeURIComponent(url.password),vhost,heartbeat:10,clientProperties:{connection_name:`g5-ventas-smoke-${runId}`}};
async function connect(){return amqp.connect(opts);}
async function managementPortUnavailable(){return new Promise((resolve,reject)=>{const socket=net.createConnection({host:'127.0.0.1',port:15672});const timer=setTimeout(()=>{socket.destroy();reject(new Error('Management port check timed out; tunnel boundary is unverified.'));},1000);socket.once('connect',()=>{clearTimeout(timer);socket.destroy();reject(new Error('127.0.0.1:15672 is reachable locally; refusing to claim management API denial.'));});socket.once('error',e=>{clearTimeout(timer);if(e.code==='ECONNREFUSED')resolve('PASS');else reject(new Error(`Management port check failed unexpectedly (${e.code??'unknown'}).`));});});}
async function denied(action){let c,ch;try{c=await connect();ch=await c.createChannel();let failure;ch.on('error',e=>{failure=e;});const closed=new Promise(resolve=>ch.once('close',resolve));await action(ch);await Promise.race([closed,new Promise(resolve=>setTimeout(resolve,500))]);if(!failure||!/ACCESS_REFUSED|403/.test(`${failure.code??''} ${failure.message??''}`))throw new Error('An unauthorized operation was not denied with ACCESS_REFUSED.');return 'PASS';}catch(e){if(/ACCESS_REFUSED|403/.test(`${e?.code??''} ${e?.message??''}`))return 'PASS';throw e;}finally{await c?.close().catch(()=>{});}}
const report={runId,user:expectedUser,vhost,authentication:'PASS'};
let c=await connect();
try{const ch=await c.createChannel();const own=await ch.checkQueue('po.ventas.q');if(own.messageCount!==0||own.consumerCount!==0)throw new Error('Precondition failed: po.ventas.q must be empty and have no consumers; no messages were fetched.');report.ownQueueRead='PASS (passive check; no message consumed)';}
finally{await c.close();}
report.crossQueueReadDenied=await denied(ch=>ch.checkQueue('po.promociones.q'));
report.queueDeclarationDenied=await denied(ch=>ch.assertQueue(`g5-smoke-denied-${runId}`,{durable:false}));
report.exchangeDeclarationDenied=await denied(ch=>ch.assertExchange(`g5-smoke-denied-${runId}`,'topic',{durable:false}));
report.defaultExchangeDenied=await denied(ch=>ch.publish('','po.ventas.q',Buffer.from('synthetic-denied')));
report.unapprovedExchangeDenied=await denied(ch=>ch.publish('po.eventos.x','g5.denied',Buffer.from('synthetic-denied')));
report.otherRoutingKeyDenied=await denied(ch=>ch.publish('po.comandos.x',badKey,Buffer.from('synthetic-denied')));
report.managementApiUnavailableThroughTunnel=await managementPortUnavailable();

// Authorized publishes are enabled only by the central Windows wrapper after it verifies
// po.ventas.q and po.promociones.q are empty and have zero consumers over the admin SSH path.
// The owner must keep that isolated window active through the publish and post-check.
if(process.env.G5_SMOKE_ALLOW_SYNTHETIC_PUBLISH!=='1'){
  report.authorizedPublication='NOT_RUN_BY_INDIVIDUAL_SMOKE';report.publisherConfirms='NOT_RUN_BY_INDIVIDUAL_SMOKE';
} else for(const routingKey of ['promotions.coupon.consumption.requested','promotions.coupon.restoration.requested']){
  c=await connect();try{const ch=await c.createConfirmChannel();const marker=`g5-smoke-${runId}-${routingKey.split('.')[2]}`;let returned=false;ch.on('return',msg=>{if(msg.properties.messageId===marker)returned=true;});await new Promise((resolve,reject)=>ch.publish('po.comandos.x',routingKey,Buffer.from(JSON.stringify({synthetic:true,runId,routingKey})),{messageId:marker,correlationId:runId,contentType:'application/json',mandatory:true,persistent:true,expiration:'2000',headers:{'x-g6-smoke':'g5-ventas','x-test-run':runId}},e=>e?reject(e):resolve()));await new Promise(resolve=>setTimeout(resolve,50));if(returned)throw new Error(`Authorized synthetic message was returned for ${routingKey}.`);report[routingKey]='PASS';report.publisherConfirms??='PASS';}finally{await c.close();}
}
if(process.env.G5_SMOKE_ALLOW_SYNTHETIC_PUBLISH==='1'){await new Promise(resolve=>setTimeout(resolve,2300));report.syntheticMessagesExpired='PENDING_ADMIN_QUEUE_POSTCHECK';}
report.adminAccess='DENIED_BY_TUNNEL_BOUNDARY; management port 15672 is not forwarded';
report.retryDlq='NOT_TESTED (blocked-specific in rc.3)';
c=await connect();await c.close();c=await connect();report.reconnect='PASS';await c.close();
console.log(JSON.stringify(report,null,2));
