import { test } from 'node:test';
import assert from 'node:assert/strict';
import { cp, mkdir, mkdtemp, readFile, rm, symlink, unlink, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { resolve } from 'node:path';
import { createHash } from 'node:crypto';
import { parse, stringify } from 'yaml';
import { build } from '../scripts/build-local.mjs';
import { source } from '../scripts/contract.mjs';
import { verifyCandidate } from '../scripts/verify-pages-candidate.mjs';

const SHA = '0123456789abcdef0123456789abcdef01234567';
const digest = bytes => createHash('sha256').update(bytes).digest('hex');

test('El verificador integral aprueba el artefacto bueno y rechaza candidatos manipulados', async t => {
  const temp = await mkdtemp(resolve(tmpdir(), 'g6-pages-integrity-'));
  t.after(() => rm(temp, { recursive: true, force: true }));
  const base = resolve(temp, 'base');
  await build({ contractPath: source, outputPath: base, commitSha: SHA, generatedAt: '2026-11-24T12:34:56.000Z' });
  const check = (candidateDir, overrides = {}) => verifyCandidate({ candidateDir, expectedSha: SHA, officialContractPath: source, ...overrides });

  await t.test('aprueba el candidato íntegro', async () => {
    const result = await check(base);
    assert.equal(result.commitSha, SHA);
    assert.equal(result.contractSha256, digest(await readFile(resolve(base, 'openapi.yaml'))));
  });

  await t.test('rechaza artefacto inexistente', async () => {
    await assert.rejects(check(resolve(temp, 'missing')), /no existe el artefacto/);
  });

  await t.test('rechaza SHA incorrecto', async () => {
    const dir = await clone('wrong-sha');
    const version = await readJson(dir, 'version.json');
    version.commit_sha = 'f'.repeat(40);
    await writeJson(dir, 'version.json', version);
    await assert.rejects(check(dir), /commit_sha .* no coincide/);
  });

  await t.test('rechaza SHA abreviado inconsistente', async () => {
    const dir = await clone('wrong-short-sha');
    const version = await readJson(dir, 'version.json');
    version.commit_sha_short = 'badbeef';
    await writeJson(dir, 'version.json', version);
    await assert.rejects(check(dir), /commit_sha_short no coincide/);
  });

  await t.test('rechaza hash contractual incorrecto', async () => {
    const dir = await clone('wrong-contract-hash');
    const version = await readJson(dir, 'version.json');
    version.contract_sha256 = '0'.repeat(64);
    await writeJson(dir, 'version.json', version);
    await assert.rejects(check(dir), /contract_sha256 no coincide/);
  });

  await t.test('rechaza hash del manifiesto distinto del contrato', async () => {
    const dir = await clone('wrong-manifest-hash');
    const manifest = await readJson(dir, 'manifest.json');
    manifest.sha256 = '0'.repeat(64);
    await writeJson(dir, 'manifest.json', manifest);
    await assert.rejects(check(dir), /manifest\.json sha256 no coincide/);
  });

  await t.test('rechaza YAML distinto del JSON aunque el hash coincida con el checkout', async () => {
    const dir = await clone('yaml-json-different');
    const spec = parse(await readFile(source, 'utf8'));
    spec.info.title += ' fixture divergente';
    const changedYaml = stringify(spec);
    const official = resolve(temp, 'official-divergent.yaml');
    await writeFile(official, changedYaml);
    await writeFile(resolve(dir, 'openapi.yaml'), changedYaml);
    const hash = digest(Buffer.from(changedYaml));
    const version = await readJson(dir, 'version.json');
    const manifest = await readJson(dir, 'manifest.json');
    version.contract_sha256 = hash;
    manifest.sha256 = hash;
    await writeJson(dir, 'version.json', version);
    await writeJson(dir, 'manifest.json', manifest);
    await assert.rejects(verifyCandidate({ candidateDir: dir, expectedSha: SHA, officialContractPath: official }), /no representan el mismo contrato/);
  });

  await t.test('rechaza versión declarada incorrecta', async () => {
    const dir = await clone('wrong-version');
    const version = await readJson(dir, 'version.json');
    version.openapi_version = '99.0.0';
    await writeJson(dir, 'version.json', version);
    await assert.rejects(check(dir), /info\.version no coincide/);
  });

  await t.test('rechaza archivos adicionales o sensibles', async () => {
    const dir = await clone('extra-file');
    await writeFile(resolve(dir, '.env'), 'TOKEN=example');
    await assert.rejects(check(dir), /archivos o directorios no permitidos/);
  });

  await t.test('rechaza material sensible dentro de un archivo permitido', async () => {
    const dir = await clone('secret-in-file');
    const portal = await readFile(resolve(dir, 'portal.js'), 'utf8');
    await writeFile(resolve(dir, 'portal.js'), `${portal}\nconst leaked = 'ghp_${'A'.repeat(36)}';\n`);
    await assert.rejects(check(dir), /material sensible en portal\.js/);
  });

  await t.test('rechaza directorios inesperados', async () => {
    const dir = await clone('extra-directory');
    await mkdir(resolve(dir, 'cache'));
    await assert.rejects(check(dir), /archivos o directorios no permitidos: cache/);
  });

  await t.test('rechaza archivos obligatorios ausentes', async () => {
    const dir = await clone('missing-file');
    await unlink(resolve(dir, 'swagger-ui.css'));
    await assert.rejects(check(dir), /faltan archivos obligatorios: swagger-ui\.css/);
  });

  await t.test('rechaza enlaces simbólicos', async () => {
    const dir = await clone('symlink');
    await unlink(resolve(dir, 'portal.css'));
    await symlink('portal.js', resolve(dir, 'portal.css'), 'file');
    await assert.rejects(check(dir), /no se permiten enlaces simbólicos/);
  });

  await t.test('rechaza candidato obsoleto frente a HEAD remoto', async () => {
    await assert.rejects(check(base, { remoteHeadSha: 'f'.repeat(40) }), /candidato obsoleto/);
  });

  async function clone(name) {
    const dir = resolve(temp, name);
    await cp(base, dir, { recursive: true });
    return dir;
  }
});

async function readJson(dir, name) {
  return JSON.parse(await readFile(resolve(dir, name), 'utf8'));
}

async function writeJson(dir, name, value) {
  await writeFile(resolve(dir, name), JSON.stringify(value, null, 2));
}
