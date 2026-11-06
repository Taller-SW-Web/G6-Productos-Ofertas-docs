import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { parseDocument } from 'yaml';

export const source = fileURLToPath(new URL('../../contratos/http/openapi.yaml', import.meta.url));
export async function loadContract() {
  const raw = await readFile(source, 'utf8');
  const doc = parseDocument(raw);
  if (doc.errors.length) throw new Error(doc.errors.map(e => e.message).join('\n'));
  return { raw, spec: doc.toJS({ maxAliasCount: 10000 }), strictErrors: [], redundantKeys: [] };
}

export const methods = ['get', 'put', 'post', 'delete', 'options', 'head', 'patch', 'trace'];
export function operations(spec) {
  return Object.entries(spec.paths).flatMap(([path, item]) => methods.filter(m => item[m]).map(method => ({ path, method, ...item[method] })));
}
