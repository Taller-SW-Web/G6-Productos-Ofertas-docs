// Cada inicio reconstruye desde el contrato oficial; no consulta la red.
const { build } = await import('./build-local.mjs');
await build();
await import('./serve-local.mjs');
