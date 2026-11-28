#!/usr/bin/env node
import { readFileSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { buildMarkdownReport } from './lib/report-core.mjs';

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
if (!args['run-dir']) {
  console.error('Uso: node scripts/generate-report.mjs --run-dir <directorio-corrida>');
  process.exit(1);
}

const runDir = resolve(args['run-dir']);
const manifest = JSON.parse(readFileSync(join(runDir, 'manifest.json'), 'utf8'));
const results = JSON.parse(readFileSync(join(runDir, 'integration-results.json'), 'utf8'));
const report = buildMarkdownReport(manifest, results);
const outPath = join(runDir, 'report.md');
writeFileSync(outPath, report, 'utf8');
console.log(`[REPORT] OK — Reporte regenerado en ${outPath}`);
