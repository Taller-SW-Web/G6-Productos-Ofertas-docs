#!/usr/bin/env node
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { buildSanitizedJunitXml, sanitizeNewmanRun } from './lib/sanitizer-core.mjs';

function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i += 1) {
    if (argv[i].startsWith('--')) {
      const key = argv[i].slice(2);
      const next = argv[i + 1];
      if (next && !next.startsWith('--')) {
        args[key] = next;
        i += 1;
      } else {
        args[key] = 'true';
      }
    }
  }
  return args;
}

const args = parseArgs(process.argv.slice(2));
if (!args.input || !args.output) {
  console.error('Uso: node scripts/sanitize-evidence.mjs --input <raw-newman.json> --output <sanitized.json> [--junit <out.xml>] [--run-id <id>] [--env <env>] [--profile <profile>]');
  process.exit(1);
}

const rawPath = resolve(args.input);
const outPath = resolve(args.output);
const rawSummary = JSON.parse(readFileSync(rawPath, 'utf8'));
const extraSecrets = [
  process.env.G6_ACCESS_TOKEN,
  process.env.G6_SERVICE_ACCESS_TOKEN,
  process.env.G6_RESTRICTED_ACCESS_TOKEN,
].filter(Boolean);

const sanitized = sanitizeNewmanRun(rawSummary, {
  runId: args['run-id'] || 'manual-sanitize',
  environmentName: args.env || 'azure-aca-chile',
  profile: args.profile || 'smoke',
  evidenceLevel: args['evidence-level'] || 'LAB_AZURE',
  extraSecrets,
});

mkdirSync(dirname(outPath), { recursive: true });
writeFileSync(outPath, `${JSON.stringify(sanitized, null, 2)}\n`, 'utf8');

if (args.junit) {
  const junitPath = resolve(args.junit);
  mkdirSync(dirname(junitPath), { recursive: true });
  writeFileSync(junitPath, buildSanitizedJunitXml(sanitized, extraSecrets), 'utf8');
}

console.log(`[SANITIZE] OK — Reporte saneado generado en ${outPath}`);
