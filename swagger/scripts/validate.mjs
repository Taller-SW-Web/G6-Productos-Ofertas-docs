import SwaggerParser from '@apidevtools/swagger-parser';
import { mkdir, writeFile } from 'node:fs/promises';
import { loadContract, operations } from './contract.mjs';

const { spec, strictErrors, redundantKeys } = await loadContract();
const issues = [...strictErrors];
try { await SwaggerParser.validate(structuredClone(spec), { resolve: { external: false } }); }
catch (e) { issues.push(e.message); }
const ops = operations(spec);
const ids = new Set();
for (const op of ops) {
  if (!op.operationId || ids.has(op.operationId)) issues.push(`operationId ausente/duplicado: ${op.method} ${op.path}`);
  ids.add(op.operationId);
  if (op.path.startsWith('/api/v1')) issues.push(`Prefijo duplicado: ${op.path}`);
  for (const security of op.security ?? spec.security ?? []) {
    for (const name of Object.keys(security)) {
      if (!spec.components.securitySchemes[name]) issues.push(`Seguridad desconocida: ${name}`);
    }
  }
}
const report = { version: spec.info.version, operations: ops.length, redundantKeys, issues };
await mkdir('reports', { recursive: true });
await writeFile('reports/validation.json', JSON.stringify(report, null, 2));
console.log(JSON.stringify(report, null, 2));
if (issues.length) process.exitCode = 1;
