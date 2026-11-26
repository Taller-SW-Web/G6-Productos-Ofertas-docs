#!/usr/bin/env node
import https from 'node:https';
import dns from 'node:dns/promises';
import net from 'node:net';
import { pathToFileURL } from 'node:url';
import { resolve } from 'node:path';

const privateV4=(ip)=>{const a=ip.split('.').map(Number);return a[0]===10||a[0]===127||a[0]===0||a[0]===169&&a[1]===254||a[0]===172&&a[1]>=16&&a[1]<=31||a[0]===192&&a[1]===168||a[0]===100&&a[1]>=64&&a[1]<=127||a[0]===198&&(a[1]===18||a[1]===19)||a[0]>=224;};
const privateV6=(ip)=>{const x=ip.toLowerCase();if(x.startsWith('::ffff:'))return privateV4(x.slice(7));return x==='::1'||x==='::'||x.startsWith('fc')||x.startsWith('fd')||x.startsWith('fe8')||x.startsWith('fe9')||x.startsWith('fea')||x.startsWith('feb');};
export async function verifyRemoteLink(value,{enabled=false,allowHosts=[],timeoutMs=5000,maxBytes=1024*1024,maxRedirects=2}={}) {
 if(!enabled)return {status:'NOT_VERIFIED',reason:'Red desactivada por defecto.'};
 if(!Number.isInteger(timeoutMs)||timeoutMs<100||timeoutMs>15000||!Number.isInteger(maxBytes)||maxBytes<1||maxBytes>10*1024*1024||!Number.isInteger(maxRedirects)||maxRedirects<0||maxRedirects>3)return {status:'NOT_VERIFIED',reason:'Límites de red fuera del rango permitido.'};
 let url;try{url=new URL(value);}catch{return {status:'NOT_VERIFIED',reason:'URL inválida.'};}
 for(let hop=0;hop<=maxRedirects;hop++) {
   if(url.protocol!=='https:'||url.username||url.password||url.port&&url.port!=='443'||!allowHosts.includes(url.hostname))return {status:'NOT_VERIFIED',reason:'Solo HTTPS/443 y host exacto allowlisted; credenciales embebidas prohibidas.'};
   if(net.isIP(url.hostname))return {status:'NOT_VERIFIED',reason:'IP literal bloqueada.'};
   let addresses;try{addresses=await dns.lookup(url.hostname,{all:true,verbatim:true});}catch{return {status:'NOT_ACCESSIBLE',reason:'DNS no resolvió.'};}
   if(!addresses.length||addresses.some(x=>net.isIP(x.address)===4?privateV4(x.address):privateV6(x.address)))return {status:'NOT_VERIFIED',reason:'Host resuelve a dirección privada/reservada.'};
   const result=await new Promise((resolvePromise)=>{
     let settled=false; const finish=(x)=>{if(!settled){settled=true;clearTimeout(timer);resolvePromise(x);}}; const timer=setTimeout(()=>req.destroy(new Error('timeout')),timeoutMs); timer.unref?.();
     const req=https.request(url,{method:'GET',timeout:timeoutMs,servername:url.hostname,lookup(_hostname,_options,cb){cb(null,addresses[0].address,addresses[0].family);},headers:{'User-Agent':'G6-H5-evidence-verifier/1','Accept':'*/*'}},res=>{
       const code=res.statusCode||0; const loc=res.headers.location; let bytes=0; let tooLarge=Number(res.headers['content-length'])>maxBytes; if(tooLarge)res.destroy(); res.on('data',chunk=>{bytes+=chunk.length;if(bytes>maxBytes){tooLarge=true;res.destroy();}}); res.on('end',()=>finish({code,loc,bytes,tooLarge})); res.on('error',()=>finish({code,loc,bytes,tooLarge,error:!tooLarge}));
     }); req.on('timeout',()=>req.destroy(new Error('timeout'))); req.on('error',()=>finish({error:true})); req.end();
   });
   if(result.error)return {status:'NOT_ACCESSIBLE',reason:'Timeout o error de conexión.'}; if(result.tooLarge)return {status:'NOT_VERIFIED',reason:'Respuesta excede el límite de bytes configurado.'};
   if([301,302,303,307,308].includes(result.code)&&result.loc){if(hop===maxRedirects)return {status:'NOT_VERIFIED',reason:'Límite de redirects excedido.'};try{url=new URL(result.loc,url);}catch{return {status:'NOT_VERIFIED',reason:'Redirect inválido.'};}continue;}
   return {status:result.code>=200&&result.code<400?'LINK_ACCESSIBLE':'NOT_ACCESSIBLE',http_status:result.code,bytes_downloaded:result.bytes,max_bytes:maxBytes};
 }
 return {status:'NOT_VERIFIED',reason:'No se pudo verificar.'};
}
if(process.argv[1]&&import.meta.url===pathToFileURL(resolve(process.argv[1])).href){const [url,...args]=process.argv.slice(2);const enabled=args.includes('--network');const allowHosts=args.filter(x=>x.startsWith('--allow-host=')).map(x=>x.slice(13));try{const result=await verifyRemoteLink(url,{enabled,allowHosts});process.stdout.write(JSON.stringify(result)+'\n');process.exitCode=result.status==='LINK_ACCESSIBLE'?0:1;}catch{process.stderr.write('{"status":"NOT_VERIFIED"}\n');process.exitCode=2;}}
