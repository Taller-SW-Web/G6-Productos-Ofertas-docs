#!/usr/bin/env node
import { createHash } from 'node:crypto';
import { lstat, readFile, realpath } from 'node:fs/promises';
import { resolve, relative, sep, isAbsolute } from 'node:path';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { pathToFileURL } from 'node:url';
const exec=promisify(execFile);

const hex = /^[0-9a-f]{64}$/;
export async function verifyArtifact(uri, { root, expectedSha256, expectedSourceSha, provenance = null } = {}) {
  const result={uri,verification_state:'NOT_VERIFIED',artifact_verified:false,sha256:null,source_sha_matches:false,reason:null};
  if(typeof uri!=='string'||uri.startsWith('sandbox:')) { result.reason='URI sandbox/no verificable.'; return result; }
  if(!root) { result.reason='Se requiere raíz explícita para resolver artefacto local.'; return result; }
  let candidate;
  if(uri.startsWith('file:')) candidate=new URL(uri);
  else if(!uri.includes('://')) { if(isAbsolute(uri)||uri.split(/[\\/]/).includes('..')) { result.reason='Ruta absoluta o traversal bloqueado.'; return result; } candidate=resolve(root,uri); }
  else { result.reason='URI remota no habilitada; descárguese mediante adaptador autorizado y calcúlese hash sobre bytes.'; return result; }
  try {
    const filePath=candidate instanceof URL?await realpath(candidate):await realpath(candidate);
    const rootReal=await realpath(root); const rel=relative(rootReal,filePath);
    if(rel==='..'||rel.startsWith(`..${sep}`)||isAbsolute(rel)) { result.reason='Ruta resuelta fuera de la raíz autorizada.'; return result; }
    const st=await lstat(filePath); if(!st.isFile()||st.isSymbolicLink()) { result.reason='El artefacto no es un archivo regular.'; return result; }
    const bytes=await readFile(filePath); const hash=createHash('sha256').update(bytes).digest('hex');
    result.sha256=hash; result.artifact_verified=true;
    if(!hex.test(expectedSha256||'')||expectedSha256!==hash) { result.reason='Checksum esperado ausente o no coincide.'; return result; }
    let provenanceVerified=false;
    if(provenance?.mode==='github-run') provenanceVerified=provenance.source_sha===expectedSourceSha&&provenance.sha_matches===true&&provenance.run_success===true&&provenance.job_success===true&&provenance.artifact_verified===true&&provenance.manual_review===true;
    if(provenance?.mode==='git-local'&&provenance.source_sha===expectedSourceSha&&provenance.manual_review===true&&provenance.repository_path) {
      try { await exec('git',['-C',resolve(provenance.repository_path),'cat-file','-e',`${expectedSourceSha}^{commit}`]); provenanceVerified=true; } catch { provenanceVerified=false; }
    }
    result.source_sha_matches=Boolean(expectedSourceSha&&provenanceVerified);
    if(!result.source_sha_matches) { result.reason='Procedencia de commit no verificada.'; return result; }
    result.verification_state='VERIFIED'; return result;
  } catch(e) { result.verification_state=e.code==='ENOENT'?'NOT_ACCESSIBLE':'NOT_VERIFIED'; result.reason=e.code==='ENOENT'?'Artefacto no accesible.':e.message; return result; }
}
if(process.argv[1]&&import.meta.url===pathToFileURL(resolve(process.argv[1])).href) {
  try { const [uri,root,sha,sourceSha,provenancePath]=process.argv.slice(2); const provenance=provenancePath?JSON.parse(await readFile(provenancePath,'utf8')):null; const out=await verifyArtifact(uri,{root,expectedSha256:sha,expectedSourceSha:sourceSha,provenance}); process.stdout.write(JSON.stringify(out,null,2)+'\n'); process.exitCode=out.verification_state==='VERIFIED'?0:1; }
  catch(e) { process.stderr.write(JSON.stringify({verification_state:'NOT_VERIFIED',reason:e.message})+'\n'); process.exitCode=2; }
}
