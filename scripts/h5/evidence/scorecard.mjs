#!/usr/bin/env node
import { createHash } from 'node:crypto';
import { readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
import { criteria, blocked, validateEvidenceSet } from './validate-evidence.mjs';
import { validateReleaseManifest } from './validate-release-manifest.mjs';
import { verifyArtifact } from './verify-artifact.mjs';
import { verifyRemoteLink } from './verify-link.mjs';

export const caseOwners={
 'INT-01':'Poma','INT-02':'Taco','INT-03':'Axel','INT-04':'Castilla','INT-05':'Vera','INT-06':'López','INT-07':'Castilla','INT-08':'Poma','INT-09':'Axel','INT-10':'Vera',
 'PERF-01':'Poma','PERF-02':'Vera','PERF-03':'Taco','PERF-04':'Axel','PERF-05':'Axel','PERF-06':'Poma','PERF-07':'Castilla','PERF-08':'Castilla',
 'RL-01':'Castilla','RL-02':'Castilla','RL-03':'Vera','RL-04':'Castilla','RL-05':'Axel','RL-06':'Vera',
 'APIM-T01':'Castilla','APIM-T02':'Castilla','APIM-T03':'Castilla','APIM-T04':'Castilla','APIM-T05':'Castilla','APIM-T06':'Castilla','APIM-T07':'Castilla','APIM-T08':'Castilla',
 'DOC-01':'Castilla','SEC-DOC-01':'Castilla','CLOSE-01':'Castilla',
 'R01':'Castilla','R02':'Castilla','R03':'Axel','R04':'Castilla','R05':'Castilla','R06':'Taco','R07':'Poma','R08':'Axel','R09':'Poma','R10':'Taco','R11':'Taco','R12':'Taco','R13':'Axel','R14':'Axel','R15':'Vera','R16':'Vera','R17':'Vera','R18':'López','N01':'Axel'
};
export const criterionCases={
 'H5-01':['DOC-01','SEC-DOC-01','CLOSE-01'], 'H5-02':['INT-01','INT-02','INT-03','INT-04','INT-05','INT-06','INT-07','INT-08','INT-09','INT-10'],
 'H5-03':['PERF-01','PERF-02','PERF-03','PERF-04','PERF-05','PERF-06','PERF-07','PERF-08','RL-01','RL-02','RL-03','RL-04','RL-05','RL-06'],
 'H5-04A':['APIM-T01','APIM-T02','APIM-T03','APIM-T04','APIM-T05','APIM-T06','APIM-T07','APIM-T08'],
 'H5-04B':['R16','R18','R01','R04','R03','R14','R07','R02','R05','R06','R08','R09','R10','R11','R12','R13','R15','R17','N01']
};
const reserved=new Set(['R03','R14']);
function classifyCase(id,records,release,verifiedArtifacts,invalidCaseIds) {
 const matches=records.filter(x=>x.case_id===id&&x.scope==='IN_SCOPE'); const r=matches[0];
 const excluded=records.find(x=>x.case_id===id&&x.scope==='OUT_OF_SCOPE');
 let status=matches.length>1?'FAIL':r?.execution_result||((excluded&&release?.approved&&excluded.scope_justification?.record_uri)?'OUT_OF_SCOPE_APPROVED':'NOT_RUN');
 if(id==='CLOSE-01'&&status!=='FAIL'&&(!release?.approved||!release?.approval?.approver||!release?.approval?.record_uri)) status='INCONCLUSIVE';
 if(invalidCaseIds.has(id)) status='FAIL';
 if(status==='PASS'&&(!verifiedArtifacts.has(r?.artifact_uri)||verifiedArtifacts.get(r?.artifact_uri)?.sha256!==r?.artifact_sha256)) status='FAIL';
 if(reserved.has(id)) status='RESERVED_NO_APLICA';
 const flows=release?.flows||[];
 const sbPair=flows.includes('R16')&&(flows.includes('R18')||(flows.includes('R07')&&release?.flow_decision?.includes('R07')));
 const conditional=(/^R\d\d$/.test(id)&&!flows.includes(id)&&id!=='R16'&&id!=='R18'&&id!=='R07')||
  (id==='R07'&&!flows.includes('R07'))||(id==='R18'&&!flows.includes('R18'))||
  (id==='INT-04'&&!flows.includes('R01'))||(id==='INT-06'&&!flows.includes('R18'))||(id==='PERF-04'&&!flows.includes('N01'));
 if(conditional) status='CONDITIONAL_NOT_ENABLED';
 const realLevel=new Set(['L2','L3','LAB_AZURE','STAGING_REAL','INTERGROUP']);
 if(status==='PASS'&&(id.startsWith('APIM-T')||id==='PERF-08'||id.startsWith('RL-'))&&(!realLevel.has(r?.evidence_level)||r?.deployment_state!=='DEPLOYED')) status='L1_NOT_RELEASE_EVIDENCE';
 if(status==='PASS'&&id==='PERF-08'&&(r?.config?.same_revision!==true||r?.config?.equivalent_control!==true)) status='INCONCLUSIVE';
 if(status==='PASS'&&id==='RL-04'&&(!Array.isArray(r?.config?.identity_refs)||new Set(r.config.identity_refs).size<2)) status='INCONCLUSIVE';
 if(status==='PASS'&&id==='R16'&&(!realLevel.has(r?.evidence_level)||!r?.run?.resource_identity||r?.deployment_state!=='DEPLOYED')) status='PILOT_OR_L1_ONLY';
 if(status==='PASS'&&(id==='R18'||id==='R07')&&(!sbPair||!realLevel.has(r?.evidence_level)||!r?.run?.resource_identity||r?.deployment_state!=='DEPLOYED')) status='SECOND_FLOW_NOT_VERIFIED';
 const blockingStatus=['FAIL','NOT_RUN','INCONCLUSIVE','L1_NOT_RELEASE_EVIDENCE','PILOT_OR_L1_ONLY','SECOND_FLOW_NOT_VERIFIED'];
 const implementation=r?.implementation_state||'NOT_IMPLEMENTED'; const execution=r?.execution_result||'NOT_RUN'; const local=['L0','L1','STATIC','ISOLATED'].includes(r?.evidence_level);
 const excludedCase=status==='CONDITIONAL_NOT_ENABLED'||status==='RESERVED_NO_APLICA'||status==='OUT_OF_SCOPE_APPROVED';
 return {case_id:id,owner:caseOwners[id]||r?.owner||excluded?.owner||'UNASSIGNED',status,blocking:blockingStatus.includes(status)||blocked.has(status),command:r?.test_command||null,rerun_command:r?.test_command||null,total_cases:excludedCase?0:1,implemented_cases:excludedCase?0:implementation==='NOT_IMPLEMENTED'?0:1,executed_local_cases:local&&execution!=='NOT_RUN'?1:0,passed_local_cases:local&&status==='PASS'?1:0,blocked_external_cases:blocked.has(status)?1:0,failed_cases:status==='FAIL'?1:0,unimplemented_cases:excludedCase?0:implementation==='NOT_IMPLEMENTED'?1:0,implementation_state:implementation,execution_result:execution,deployment_state:r?.deployment_state||'UNKNOWN',homologation_state:r?.homologation_state||'UNKNOWN'};
}
export function buildScorecard(records,release=null,{verifiedArtifacts=new Map(),invalidCaseIds=new Set(),validationErrors=[]}={}) {
 const cases=[...new Set([...Object.values(criterionCases).flat(),'DOC-01','CLOSE-01'])].sort((a,b)=>a<b?-1:a>b?1:0);
 const entries=cases.map(id=>classifyCase(id,records,release,verifiedArtifacts,invalidCaseIds));
 const byCriterion={}; for(const c of criteria) {
   const ids=criterionCases[c]; const rows=entries.filter(x=>ids.includes(x.case_id));
   const failed=rows.filter(x=>x.status==='FAIL').length; const passed=rows.filter(x=>x.status==='PASS').length;
   const blockedExternal=rows.filter(x=>blocked.has(x.status)).length; const unimplemented=rows.filter(x=>x.implementation_state==='NOT_IMPLEMENTED').length;
   const conditional=rows.filter(x=>x.status==='CONDITIONAL_NOT_ENABLED'||x.status==='RESERVED_NO_APLICA'||x.status==='OUT_OF_SCOPE_APPROVED').length;
   const total=rows.filter(x=>x.total_cases>0).length;
   const verdict=failed?'FAIL':rows.some(x=>x.status==='NOT_RUN')?'INCONCLUSIVE':passed===total&&total>0?'PASS':'INCONCLUSIVE';
   byCriterion[c]={verdict,total_cases:total,implemented_cases:rows.reduce((n,x)=>n+x.implemented_cases,0),executed_local_cases:rows.reduce((n,x)=>n+x.executed_local_cases,0),passed_local_cases:rows.reduce((n,x)=>n+x.passed_local_cases,0),blocked_external_cases:blockedExternal,failed_cases:failed,unimplemented_cases:unimplemented,conditional_cases:conditional,owner:'Castilla',blocking:verdict!=='PASS',cases:rows};
 }
 return {schema_version:'h5-scorecard/v1',release_id:release?.release_id||null,verdict:validationErrors.length||release?.approved!==true?'INCONCLUSIVE':Object.values(byCriterion).every(x=>x.verdict==='PASS')?'PASS':'INCONCLUSIVE',validation_errors:validationErrors,criteria:byCriterion,cases:entries};
}
export function renderMarkdown(scorecard) { const lines=['# Scorecard H5 calculado','',`Release: ${scorecard.release_id||'NOT_SET'}`,`Resultado global: **${scorecard.verdict}**`,'','| Criterio | Resultado | Total | Implementados | Ejecutados locales | PASS local | Bloqueos externos | Fallos | Sin implementar | Owner |','|---|---:|---:|---:|---:|---:|---:|---:|---:|---|']; for(const [id,c] of Object.entries(scorecard.criteria)) lines.push(`| ${id} | ${c.verdict} | ${c.total_cases} | ${c.implemented_cases} | ${c.executed_local_cases} | ${c.passed_local_cases} | ${c.blocked_external_cases} | ${c.failed_cases} | ${c.unimplemented_cases} | ${c.owner} |`); lines.push('','## Casos y bloqueantes','','| ID | Owner | Estado | Implementación | Ejecución | Bloqueante | Reejecución |','|---|---|---|---|---|---|---|'); for(const x of scorecard.cases) lines.push(`| ${x.case_id} | ${x.owner} | ${x.status} | ${x.implementation_state} | ${x.execution_result} | ${x.blocking?'sí':'no'} | ${x.command||'Pendiente de prerequisito'} |`); return lines.join('\n')+'\n'; }
export async function writeScorecard(scorecard,jsonPath,mdPath) { const json=JSON.stringify(scorecard,null,2)+'\n'; await writeFile(jsonPath,json); await writeFile(mdPath,renderMarkdown(scorecard)); const digest=createHash('sha256').update(json).digest('hex'); await writeFile(`${jsonPath}.sha256`,`${digest}  ${jsonPath.split(/[\\/]/).at(-1)}\n`); return digest; }
if(process.argv[1]&&import.meta.url===pathToFileURL(resolve(process.argv[1])).href) { try { const [recordsFile,manifestFile,outJson,outMd,...flags]=process.argv.slice(2); const data=JSON.parse(await readFile(recordsFile,'utf8')); const records=Array.isArray(data)?data:data.records; const release=manifestFile?JSON.parse(await readFile(manifestFile,'utf8')):null; const root=resolve(recordsFile,'..'); const verifiedArtifacts=new Map(); for(const r of records) if(r.execution_result==='PASS'&&r.artifact_uri) { const proof=await verifyArtifact(r.artifact_uri,{root,expectedSha256:r.artifact_sha256,expectedSourceSha:r.source_sha,provenance:r.source}); if(proof.verification_state==='VERIFIED') verifiedArtifacts.set(r.artifact_uri,proof); } const validation=validateEvidenceSet(records,{releaseManifest:release,baseDir:root,verifiedArtifacts}); const releaseValidation=release?await validateReleaseManifest(release,{root:resolve(manifestFile,'..')}):{valid:false,errors:[{field:'release',message:'Release manifest requerido para derivar scorecard.'}]}; const validationErrors=[...validation.errors,...releaseValidation.errors]; const invalidCaseIds=new Set(validation.errors.map(x=>/^records\[(\d+)\]/.exec(x.field)).filter(Boolean).map(m=>records[Number(m[1])]?.case_id).filter(Boolean)); if(releaseValidation.errors.length) invalidCaseIds.add('CLOSE-01'); const network=flags.includes('--network'),allowHosts=flags.filter(x=>x.startsWith('--allow-host=')).map(x=>x.slice(13)); const remoteUris=new Set([...(release?.evidence_files||[]),release?.approval?.record_uri,...records.map(r=>r.scope_justification?.record_uri),...records.map(r=>r.run?.bilateral_record)].filter(x=>typeof x==='string'&&x.startsWith('https://'))); for(const uri of [...remoteUris].sort()) { const check=await verifyRemoteLink(uri,{enabled:network,allowHosts}); if(check.status!=='LINK_ACCESSIBLE') { validationErrors.push({field:'remote_link',message:check.reason||check.status}); invalidCaseIds.add('CLOSE-01'); } } const score=buildScorecard(records,release,{verifiedArtifacts,invalidCaseIds,validationErrors}); const digest=await writeScorecard(score,outJson,outMd); process.stdout.write(JSON.stringify({verdict:score.verdict,validation_errors:validationErrors.length,sha256:digest})+'\n'); } catch(e) { process.stderr.write(JSON.stringify({error:e.message})+'\n'); process.exitCode=2; } }
