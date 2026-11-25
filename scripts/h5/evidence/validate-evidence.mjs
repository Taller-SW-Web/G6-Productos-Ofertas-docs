#!/usr/bin/env node
import { readFile } from 'node:fs/promises';
import { pathToFileURL } from 'node:url';
import { resolve } from 'node:path';

export const criteria = ['H5-01', 'H5-02', 'H5-03', 'H5-04A', 'H5-04B'];
export const blocked = new Set(['BLOCKED_APIM','BLOCKED_SB','BLOCKED_G7','BLOCKED_G5','BLOCKED_CONTRACT','BLOCKED_PROVIDER','BLOCKED_INFRA','BLOCKED_BUDGET','BLOCKED_AUTH','BLOCKED_TOOL','BLOCKED_GH_ADMIN','BLOCKED_DATA']);
const states = {
  scope: new Set(['IN_SCOPE','OUT_OF_SCOPE']), level: new Set(['L0','L1','L2','L3','STATIC','ISOLATED','LAB_AZURE','STAGING_REAL','INTERGROUP']),
  result: new Set(['PASS','FAIL','INCONCLUSIVE','NOT_RUN',...blocked]), implementation: new Set(['DONE_LOCAL','READY_FOR_INTEGRATION','BLOCKED_DEPENDENCY','NEEDS_FIX']),
  deployment: new Set(['NOT_DEPLOYED','DEPLOYED','UNKNOWN']), homologation: new Set(['NOT_REQUIRED','PENDING','HOMOLOGATED','UNKNOWN']),
  verification: new Set(['VERIFIED','NOT_VERIFIED','NOT_ACCESSIBLE','EXPIRED']), review: new Set(['REVIEWED','PENDING','NOT_REQUIRED'])
};
const required = ['schema_version','case_id','h5_criterion','owner','scope','source_repo','source_sha','docs_sha','test_command','environment','evidence_level','execution_result','test_result','implementation_state','deployment_state','homologation_state','verification_state','started_at','finished_at','artifact_uri','artifact_sha256','source','config','dataset','dependencies','blocking_dependency','manual_review'];
const known = new Set([...required,'scope_justification','findings','run','metadata']);
const sha40 = /^[0-9a-f]{40}$/; const sha64 = /^[0-9a-f]{64}$/;
function err(errors, field, message) { errors.push({ field, message }); }
function dateValue(value) { const n = Date.parse(value); return Number.isFinite(n) ? n : null; }

export function validateEvidenceSet(records, { releaseManifest = null, baseDir = process.cwd(), verifiedArtifacts = new Map() } = {}) {
  const errors = []; const seen = new Map(); const byRepoSha = new Map();
  if (!Array.isArray(records)) return { valid: false, errors: [{ field: '$', message: 'Debe ser un arreglo de registros.' }] };
  for (let i=0;i<records.length;i++) {
    const r=records[i], p=`records[${i}]`;
    if (!r || typeof r !== 'object' || Array.isArray(r)) { err(errors,p,'Debe ser un objeto.'); continue; }
    for (const k of Object.keys(r)) if (!known.has(k)) err(errors,`${p}.${k}`,'Clave crítica/desconocida; requiere migrador de esquema.');
    for (const k of required) if (!(k in r)) err(errors,`${p}.${k}`,'Campo obligatorio ausente.');
    if(r.schema_version!=='h5-evidence/v1') err(errors,`${p}.schema_version`,'Se requiere h5-evidence/v1.');
    if(typeof r.case_id!=='string'||!r.case_id.trim()) err(errors,`${p}.case_id`,'ID de caso requerido.');
    if(typeof r.owner!=='string'||!r.owner.trim()) err(errors,`${p}.owner`,'Owner único requerido.');
    if(!['H5-01','H5-02','H5-03','H5-04A','H5-04B','DOC-01','SEC-DOC-01','CLOSE-01'].includes(r.h5_criterion)) err(errors,`${p}.h5_criterion`,'Criterio no reconocido.');
    if(!states.scope.has(r.scope)) err(errors,`${p}.scope`,'Estado de alcance no reconocido.');
    if(!states.level.has(r.evidence_level)) err(errors,`${p}.evidence_level`,'Nivel no reconocido.');
    for(const k of ['execution_result','test_result']) if(!states.result.has(r[k])) err(errors,`${p}.${k}`,'Resultado no reconocido.');
    if(r.execution_result!==r.test_result) err(errors,p,'execution_result y test_result deben coincidir; no se permite resolver por texto libre.');
    for(const [k,s] of [['implementation_state',states.implementation],['deployment_state',states.deployment],['homologation_state',states.homologation],['verification_state',states.verification],['manual_review',states.review]]) if(!s.has(r[k])) err(errors,`${p}.${k}`,'Estado no reconocido.');
    for(const k of ['source_sha','docs_sha']) if(r[k]!==null&&!sha40.test(r[k]||'')) err(errors,`${p}.${k}`,'Debe ser SHA-1 completo de 40 caracteres hex minúsculos o null explícito.');
    if(r.scope==='OUT_OF_SCOPE'&&(!r.scope_justification?.reason||!r.scope_justification?.record_uri||!r.scope_justification?.approved_by||!releaseManifest?.approved||!releaseManifest?.approval?.approver||!releaseManifest?.approval?.record_uri||!releaseManifest?.evidence_files?.includes(r.scope_justification.record_uri))) err(errors,`${p}.scope`,'OUT_OF_SCOPE requiere justificación trazable incluida en el manifiesto aprobado.');
    if(r.scope==='IN_SCOPE'&&r.scope_justification) err(errors,`${p}.scope_justification`,'La justificación solo aplica a OUT_OF_SCOPE.');
    if(r.execution_result==='PASS') {
      if(!r.artifact_uri||!r.artifact_sha256||!sha64.test(r.artifact_sha256)) err(errors,`${p}.artifact_uri`,'PASS requiere URI y SHA-256 verificado de artefacto.');
      if(!sha40.test(r.source_sha||'')) err(errors,`${p}.source_sha`,'PASS requiere SHA fuente.');
      if(!r.docs_sha||!sha40.test(r.docs_sha)) err(errors,`${p}.docs_sha`,'PASS requiere SHA Docs completo.');
      if(!r.started_at||!r.finished_at||!r.environment) err(errors,p,'PASS requiere timestamps UTC y entorno identificable.');
      if(!((r.dataset?.seed!==undefined&&sha64.test(r.dataset?.sha256||''))||(r.dataset?.not_applicable===true&&r.dataset?.reason))) err(errors,`${p}.dataset`,'PASS requiere semilla/checksum de dataset o motivo estructurado de no aplicación.');
      if(r.verification_state!=='VERIFIED') err(errors,`${p}.verification_state`,'PASS requiere verificación VERIFIED.');
      if(r.manual_review==='PENDING') err(errors,`${p}.manual_review`,'Hallazgos/revisión pendientes impiden PASS.');

      const proof=verifiedArtifacts.get(r.artifact_uri);
      if(!proof||proof.sha256!==r.artifact_sha256||proof.verification_state!=='VERIFIED'||proof.source_sha_matches!==true) err(errors,`${p}.artifact_sha256`,'Los bytes y procedencia no fueron verificados por verify-artifact.');
    }
    if(r.verification_state==='EXPIRED'&&r.execution_result==='PASS') err(errors,`${p}.verification_state`,'Artefacto expirado no puede conservar PASS.');
    if(['SKIPPED','CANCELLED'].includes(r.run?.conclusion)) err(errors,`${p}.run.conclusion`,'Ejecución skipped/cancelled no es evidencia PASS.');
    if(r.evidence_level==='L2'||r.evidence_level==='LAB_AZURE'||r.evidence_level==='STAGING_REAL') {
      if(!r.environment||!r.run?.resource_identity) err(errors,`${p}.run`,'L2 requiere entorno, recurso e identidad observados.');
    }
    if(r.evidence_level==='L3'||r.evidence_level==='INTERGROUP') {
      if(r.homologation_state!=='HOMOLOGATED'||!r.run?.bilateral_record) err(errors,`${p}.homologation_state`,'L3 requiere acta bilateral verificable.');
    }
    if(r.source_repo&&r.source_sha) { const prev=byRepoSha.get(r.source_repo); if(prev&&prev!==r.source_sha) err(errors,`${p}.source_sha`,'Un release no puede mezclar SHAs del mismo repositorio.'); else byRepoSha.set(r.source_repo,r.source_sha); }
    if(r.source_repo&&r.source_sha&&releaseManifest?.repos) { const releaseKey=Object.keys(releaseManifest.repos).find(k=>k.toLowerCase()===String(r.source_repo).toLowerCase()); if(releaseKey&&releaseManifest.repos[releaseKey].sha!==r.source_sha) err(errors,`${p}.source_sha`,'El SHA no coincide con la revisión aprobada de ese repositorio.'); }
    if(r.docs_sha&&releaseManifest?.repos?.Docs?.sha&&r.docs_sha!==releaseManifest.repos.Docs.sha) err(errors,`${p}.docs_sha`,'No coincide con el SHA Docs del manifiesto de release.');
    if(r.started_at!==null||r.finished_at!==null) { const a=dateValue(r.started_at), b=dateValue(r.finished_at); if(a===null||b===null||b<a||!r.started_at?.endsWith('Z')||!r.finished_at?.endsWith('Z')) err(errors,`${p}.started_at`,'Timestamps UTC ausentes, inválidos, sin Z o invertidos.'); }
    if(r.metadata?.expires_at) { const expiry=dateValue(r.metadata.expires_at); if(expiry===null||expiry<=Date.now()) err(errors,`${p}.metadata.expires_at`,'Artefacto expirado o fecha de expiración inválida.'); }
    if(r.scope==='IN_SCOPE'&&r.owner) { const key=r.case_id; const prev=seen.get(key); if(prev&&prev!==r.owner) err(errors,`${p}.owner`,'Caso duplicado asignado a más de un owner.'); else if(prev) err(errors,`${p}.case_id`,'case_id duplicado.'); else seen.set(key,r.owner); }
    if(typeof r.execution_result==='string'&&r.execution_result.startsWith('BLOCKED_')&&(!r.blocking_dependency?.owner||!r.blocking_dependency?.condition||!r.blocking_dependency?.operation)) err(errors,`${p}.blocking_dependency`,'Bloqueo exige owner, operación y condición concreta.');
    if(!['object'].includes(typeof r.source)||!r.source||!r.config||!r.dataset||!Array.isArray(r.dependencies)) err(errors,p,'source/config/dataset/dependencies requieren tipos estructurados.');
  }
  return { valid: errors.length===0, errors };
}

export async function loadAndValidate(path, options={}) { const data=JSON.parse(await readFile(path,'utf8')); const records=Array.isArray(data)?data:data.records; return { records, ...validateEvidenceSet(records,{...options,baseDir:resolve(path,'..')}) }; }
if (process.argv[1] && import.meta.url===pathToFileURL(resolve(process.argv[1])).href) {
  try { const out=await loadAndValidate(process.argv[2]); process.stdout.write(JSON.stringify({valid:out.valid,errors:out.errors},null,2)+'\n'); process.exitCode=out.valid?0:1; }
  catch(e) { process.stderr.write(JSON.stringify({valid:false,errors:[{field:'$',message:e.message}]})+'\n'); process.exitCode=2; }
}
