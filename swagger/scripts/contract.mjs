import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { isMap, parseDocument, visit } from 'yaml';
import { isDeepStrictEqual } from 'node:util';

export const source = fileURLToPath(new URL('../../contratos/http/openapi.yaml', import.meta.url));
export async function loadContract() {
  const raw = await readFile(source, 'utf8');
  const strict = parseDocument(raw);
  // A redundant identical key is diagnosed, never resolved by choosing a value.
  const doc = parseDocument(raw, { uniqueKeys: false });
  if (doc.errors.length) throw new Error(doc.errors.map(e => e.message).join('\n'));
  const redundantKeys = [];
  visit(doc, {
    Map(_, map) {
      if (!isMap(map)) return;
      const seen = new Map();
      map.items = map.items.filter(pair => {
        const key = String(pair.key.value);
        if (!seen.has(key)) { seen.set(key, pair); return true; }
        const a = seen.get(key).value?.toJSON();
        const b = pair.value?.toJSON();
        if (!isDeepStrictEqual(a, b)) throw new Error(`Clave duplicada contradictoria: ${key}`);
        redundantKeys.push({ key, offset: pair.key.range[0] });
        return false;
      });
    }
  });
  return { raw, spec: doc.toJS({ maxAliasCount: 10000 }), strictErrors: strict.errors.map(e => e.message), redundantKeys };
}

export const methods = ['get', 'put', 'post', 'delete', 'options', 'head', 'patch', 'trace'];
export function operations(spec) {
  return Object.entries(spec.paths).flatMap(([path, item]) => methods.filter(m => item[m]).map(method => ({ path, method, ...item[method] })));
}
