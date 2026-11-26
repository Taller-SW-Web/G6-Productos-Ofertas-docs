#!/usr/bin/env node
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { lstat, mkdir, realpath, readFile, writeFile } from 'node:fs/promises';
import { resolve, relative, sep } from 'node:path';
import { pathToFileURL } from 'node:url';
const exec=promisify(execFile);
const catalog=[
 ['H5-01','SEC-DOC-01','castilla',['.github/workflows/ci.yml','.github/workflows/frontend.yml']],
 ['H5-02','INT-01','poma',['apps/catalog-svc/test']],['H5-02','INT-04','castilla',['apps/bulk-svc/test']],['H5-02','INT-07','castilla',['apps/api-gateway/test']],
 ['H5-03','PERF-01','poma',['scripts/performance']],['H5-03','PERF-07','castilla',['scripts/performance','apps/bulk-svc/test']],
 ['H5-04A','APIM-01','castilla',['ops/azure/apim']],['H5-04B','R16','vera',['docs/hito-5/CIERRE_PILOTO_234.md']],['H5-04B','R18','axel',['apps/taxonomy-svc','apps/catalog-svc']]
];
async function safePath(root, rel) { if(rel.split(/[\\/]/).includes('..')) throw new Error('Traversal path is not allowed.'); const rootReal=await realpath(root); const path=resolve(rootReal,rel), back=relative(rootReal,path); if(back==='..'||back.startsWith(`..${sep}`)) throw new Error('Path escapes repository root.'); const item=await lstat(path); if(item.isSymbolicLink()) throw new Error('Symlink paths are not followed.'); const real=await realpath(path), resolvedBack=relative(rootReal,real); if(resolvedBack==='..'||resolvedBack.startsWith(`..${sep}`)) throw new Error('Symlink escapes repository root.'); return {path:real,isDirectory:item.isDirectory()}; }
export async function scanRepositories(repositories,{githubRuns=[],allowGithubRead=false}={}) {
 const output={schema_version:'h5-inventory/v1',mode:allowGithubRead?'offline-plus-explicit-gh-readonly':'offline-read-only',generated_at:null,repositories:[],capabilities:[],github_runs:[]};
 for(const repo of repositories) {
   const root=resolve(repo.root); let sha=null,ref=null;
   try { ({stdout:sha}=await exec('git',['-C',root,'rev-parse','HEAD'])); sha=sha.trim(); ({stdout:ref}=await exec('git',['-C',root,'branch','--show-current'])); ref=ref.trim(); } catch { sha=null; }
   output.repositories.push({repo:repo.name,root:repo.label||repo.name,sha,ref,read_state:sha?'READABLE':'NOT_ACCESSIBLE'});
   for(const [criterion,id,owner,paths] of catalog) if(repo.capabilities?.includes(id)) {
     const matches=[]; for(const rel of paths) { try { const item=await safePath(root,rel); matches.push({path:rel,status:'present',kind:item.isDirectory?'directory':'file'}); } catch(e) { matches.push({path:rel,status:e.code==='ENOENT'?'missing':'NOT_ACCESSIBLE'}); } }
     output.capabilities.push({repo:repo.name,base_sha:sha,capability_id:id,criterion,owner,paths:matches,status:matches.some(x=>x.status==='present')?'present':'missing'});
   }
 }
 const names=new Set(); for(const r of repositories) { if(names.has(r.name)) throw new Error(`Duplicate repository: ${r.name}`); names.add(r.name); }
 if(allowGithubRead) for(const run of githubRuns) {
   if(!/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(run.repo||'')||!/^[0-9]+$/.test(String(run.run_id||''))) { output.github_runs.push({repo:run.repo||null,run_id:null,status:'NOT_VERIFIED',reason:'Repo/run ID inválidos.'}); continue; }
   try {
     const {stdout}=await exec('gh',['run','view',String(run.run_id),'--repo',run.repo,'--json','databaseId,headSha,status,conclusion,workflowName,jobs,createdAt,updatedAt,url']);
     const data=JSON.parse(stdout); const jobs=Array.isArray(data.jobs)?data.jobs:[]; const expected=run.expected_sha||null;
     output.github_runs.push({repo:run.repo,run_id:String(run.run_id),workflow:data.workflowName||null,run_status:data.status||null,run_conclusion:data.conclusion||null,run_success:data.conclusion==='success',job_success:jobs.length>0&&jobs.every(j=>j.conclusion==='success'),artifact_verified:false,sha_matches:expected?data.headSha===expected:null,manual_review:false,head_sha:data.headSha||null,created_at:data.createdAt||null,updated_at:data.updatedAt||null,url:data.url||null,jobs:jobs.map(j=>({name:j.name,conclusion:j.conclusion,status:j.status})),artifact_note:'Artifact bytes were not downloaded; no checksum is claimed.'});
   } catch { output.github_runs.push({repo:run.repo,run_id:String(run.run_id),status:'NOT_ACCESSIBLE',run_success:null,job_success:null,artifact_verified:false,sha_matches:null,manual_review:false}); }
 }
 return output;
}
export async function writeInventory(repositories,outFile) { const inventory=await scanRepositories(repositories); await mkdir(resolve(outFile,'..'),{recursive:true}); await writeFile(outFile,JSON.stringify(inventory,null,2)+'\n',{flag:'wx'}); return inventory; }
if(process.argv[1]&&import.meta.url===pathToFileURL(resolve(process.argv[1])).href) {
 try { const [configFile,outFile,...flags]=process.argv.slice(2); const config=JSON.parse(await readFile(configFile,'utf8')); const inventory=await scanRepositories(config.repositories,{githubRuns:config.github_runs||[],allowGithubRead:flags.includes('--gh-readonly')}); await writeFile(outFile,JSON.stringify(inventory,null,2)+'\n',{flag:'wx'}); process.stdout.write(JSON.stringify({repositories:inventory.repositories.length,capabilities:inventory.capabilities.length,github_runs:inventory.github_runs.length,outFile})+'\n'); }
 catch(e) { process.stderr.write(JSON.stringify({error:e.message})+'\n'); process.exitCode=2; }
}
