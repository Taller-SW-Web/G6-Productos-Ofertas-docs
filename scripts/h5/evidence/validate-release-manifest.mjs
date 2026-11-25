import { lstat, readFile, realpath } from 'node:fs/promises';
import { resolve, relative, sep, isAbsolute } from 'node:path';
import { pathToFileURL } from 'node:url';
const sha40=/^[0-9a-f]{40}$/;const sha64=/^[0-9a-f]{64}$/;
export async function validateReleaseManifest(manifest,{root=process.cwd()}={}) {
 const errors=[];const fail=(field,message)=>errors.push({field,message});
 if(manifest?.schema_version!=='h5-release/v1')fail('schema_version','Se requiere h5-release/v1.');
 if(!manifest?.release_id)fail('release_id','Identificador requerido.');
 if(typeof manifest?.created_at!=='string'||!manifest.created_at.endsWith('Z')||!Number.isFinite(Date.parse(manifest.created_at)))fail('created_at','Fecha UTC ISO-8601 con Z requerida.');
 if(!Array.isArray(manifest?.required_criteria)||!Array.isArray(manifest?.evidence_files)||!Array.isArray(manifest?.flows))fail('$','required_criteria/evidence_files/flows deben ser arreglos.');
 else for(const c of ['H5-01','H5-02','H5-03','H5-04A','H5-04B']) if(!manifest.required_criteria.includes(c))fail('required_criteria',`Falta criterio fijo ${c}.`);
 const repos=manifest?.repos||{}; for(const [name,info] of Object.entries(repos)) { if(!sha40.test(info?.sha||''))fail(`repos.${name}.sha`,'SHA completo requerido.'); if(info?.digest!==undefined&&info.digest!==null&&!/^sha256:[0-9a-f]{64}$/.test(info.digest))fail(`repos.${name}.digest`,'Digest OCI inválido.'); if(info?.dataset_sha256&& !sha64.test(info.dataset_sha256))fail(`repos.${name}.dataset_sha256`,'Checksum dataset inválido.'); }
 if(manifest?.approved&&(!manifest.approval?.approver||!manifest.approval?.record_uri||!manifest.approval?.approved_at||!String(manifest.approval.approved_at).endsWith('Z')||!Number.isFinite(Date.parse(manifest.approval.approved_at))||!manifest.evidence_files?.includes(manifest.approval.record_uri)))fail('approval','approved=true requiere aprobador, acta incluida en evidencia_files y fecha UTC verificable.');
 if(manifest?.approved) { for(const name of ['Backend','Frontend','Docs']) if(!repos[name]) fail(`repos.${name}`,'La aprobación requiere SHA por repositorio.'); if(!manifest.environment)fail('environment','Aprobación requiere ambiente.'); }
 const rootReal=await realpath(root).catch(()=>null);
 for(let i=0;i<(manifest?.evidence_files||[]).length;i++) { const raw=manifest.evidence_files[i]; if(typeof raw!=='string'||raw.split(/[\\/]/).includes('..')||isAbsolute(raw)) { fail(`evidence_files[${i}]`,'Ruta con traversal/absoluta no permitida.');continue; } if(raw.includes('://')) { try {const u=new URL(raw);if(u.protocol!=='https:'||u.username||u.password||u.port&&u.port!=='443')fail(`evidence_files[${i}]`,'Solo HTTPS sin credenciales/puertos alternos.');}catch{fail(`evidence_files[${i}]`,'URL inválida.');} continue; } try {const p=await realpath(resolve(root,raw));const rel=relative(rootReal,p);if(rel==='..'||rel.startsWith(`..${sep}`)||isAbsolute(rel))fail(`evidence_files[${i}]`,'Ruta escapa raíz.');}catch(e){fail(`evidence_files[${i}]`,'Evidencia no accesible.');} }
 for(let i=0;i<(manifest?.evidence_files||[]).length;i++) { const raw=manifest.evidence_files[i]; if(typeof raw==='string'&&!raw.includes('://')) try {const info=await lstat(resolve(root,raw));if(info.isSymbolicLink()||!info.isFile())fail(`evidence_files[${i}]`,'La evidencia local debe ser un archivo regular, no symlink/directorio.');}catch{} }
 if(manifest?.flows?.some(x=>['R03','R14'].includes(x)))fail('flows','R03 y R14 están reservados/no aplican; no pueden activarse.');
 if(manifest?.flows?.includes('R07')&&!manifest?.flow_decision?.includes('R07'))fail('flows','R07 fallback requiere decisión de release explícita.');
 if(manifest?.required_criteria?.includes('H5-04B')&&(!manifest?.flows?.includes('R16')||!(manifest?.flows?.includes('R18')||(manifest?.flows?.includes('R07')&&manifest?.flow_decision?.includes('R07'))))) fail('flows','H5-04B requiere R16+R18 o R16+R07 con decisión explícita.');
 return {valid:errors.length===0,errors};
}
if(process.argv[1]&&import.meta.url===pathToFileURL(resolve(process.argv[1])).href){try{const [file,root]=process.argv.slice(2);const m=JSON.parse(await readFile(file,'utf8'));const x=await validateReleaseManifest(m,{root});process.stdout.write(JSON.stringify(x,null,2)+'\n');process.exitCode=x.valid?0:1;}catch(e){process.stderr.write(JSON.stringify({valid:false,error:e.message})+'\n');process.exitCode=2;}}
