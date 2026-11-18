import test from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
const checker=fileURLToPath(new URL('./verify-docs-results.mjs',import.meta.url));
const run=(value)=>spawnSync(process.execPath,[checker,JSON.stringify(value)],{encoding:'utf8'});
test('validate-docs aprueba solo contrato exitoso',()=>assert.equal(run({contrato:{result:'success'}}).status,0));
for(const result of ['failure','skipped','cancelled']) test(`validate-docs rechaza contrato ${result}`,()=>assert.equal(run({contrato:{result}}).status,1));
test('validate-docs rechaza contrato ausente',()=>assert.equal(run({}).status,1));
