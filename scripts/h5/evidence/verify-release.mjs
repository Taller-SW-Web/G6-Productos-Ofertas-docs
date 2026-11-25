#!/usr/bin/env node
import { readFile } from 'node:fs/promises';
import { resolve, dirname } from 'node:path';
import { pathToFileURL } from 'node:url';
import { validateReleaseManifest } from './validate-release-manifest.mjs';
import { validateEvidenceSet } from './validate-evidence.mjs';
import { verifyArtifact } from './verify-artifact.mjs';
import { verifyRemoteLink } from './verify-link.mjs';

export async function verifyRelease(manifestPath,evidencePath,{allowNetwork=false,allowedHosts=[]}={}) {
 const root=dirname(resolve(manifestPath)); const manifest=JSON.parse(await readFile(manifestPath,'utf8')); const manifestCheck=await validateReleaseManifest(manifest,{root});
 const raw=JSON.parse(await readFile(evidencePath,'utf8')); const records=Array.isArray(raw)?raw:raw.records; const verified=new Map(); const artifactChecks=[];
 for(const r of records) if(r.execution_result==='PASS'&&r.artifact_uri) { const proof=await verifyArtifact(r.artifact_uri,{root,expectedSha256:r.artifact_sha256,expectedSourceSha:r.source_sha,provenance:r.source}); artifactChecks.push(proof); if(proof.verification_state==='VERIFIED')verified.set(r.artifact_uri,proof); }
 const linkUris=new Set([...(manifest.evidence_files||[]),manifest.approval?.record_uri,...records.map(r=>r.scope_justification?.record_uri)].filter(x=>typeof x==='string'&&x.startsWith('https://'))); const remoteLinks=[]; for(const uri of [...linkUris].sort()) remoteLinks.push({uri,...await verifyRemoteLink(uri,{enabled:allowNetwork,allowHosts:allowedHosts})});
 const evidenceCheck=validateEvidenceSet(records,{releaseManifest:manifest,baseDir:root,verifiedArtifacts:verified});
 return {schema_version:'h5-release-verification/v1',manifest:manifestCheck,evidence:evidenceCheck,artifact_checks:artifactChecks,remote_links:remoteLinks,verified:manifestCheck.valid&&evidenceCheck.valid&&manifest.approved===true&&remoteLinks.every(x=>x.status==='LINK_ACCESSIBLE')};
}
if(process.argv[1]&&import.meta.url===pathToFileURL(resolve(process.argv[1])).href){try{const [manifest,evidence,...flags]=process.argv.slice(2);const result=await verifyRelease(manifest,evidence,{allowNetwork:flags.includes('--network'),allowedHosts:flags.filter(x=>x.startsWith('--allow-host=')).map(x=>x.slice(13))});process.stdout.write(JSON.stringify(result,null,2)+'\n');process.exitCode=result.verified?0:1;}catch(e){process.stderr.write(JSON.stringify({verified:false,error:e.message})+'\n');process.exitCode=2;}}
