import { readFile } from 'node:fs/promises';
export const config = JSON.parse(await readFile(new URL('../studio.config.json', import.meta.url), 'utf8'));
export function forStudio(spec) {
  const publication = structuredClone(spec);
  publication.info.title = config.title;
  publication.servers = structuredClone(config.servers);
  return publication;
}
export function stable(value) {
  if (Array.isArray(value)) return value.map(stable);
  if (value && typeof value === 'object') return Object.fromEntries(Object.keys(value).sort().map(key => [key, stable(value[key])]));
  return value;
}
