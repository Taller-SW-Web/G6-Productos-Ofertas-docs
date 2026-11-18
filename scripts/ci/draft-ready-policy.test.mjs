import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
const wf=await readFile('.github/workflows/swagger-docs.yml','utf8');
const sync=await readFile('.github/workflows/sync-workspaces.yml','utf8');
test('Swagger docs ejecuta en Draft/Ready y posmerge con agregador estable',()=>{assert.match(wf,/opened, reopened, synchronize, ready_for_review, converted_to_draft, edited/);assert.match(wf,/push:[\s\S]*?branches: \[master\]/);assert.match(wf,/name: validate-docs/);assert.match(wf,/draft == false/);});
test('la concurrencia agrupa por PR/ref y manuales no se cancelan',()=>{assert.match(wf,/group: swagger-docs-\$\{\{ github\.event\.pull_request\.number \|\| github\.ref \}\}/);assert.match(wf,/cancel-in-progress: \$\{\{ github\.event_name != 'workflow_dispatch' \}\}/);});
test('sin paths filter, conserva despacho y pruebas contractuales/Playwright',()=>{assert.match(wf,/workflow_dispatch:/);assert.doesNotMatch(wf,/^    paths:/m);for(const check of ['npm run validate','npm run test:browser','python -m unittest discover'])assert.ok(wf.includes(check));});
test('sincronización sigue manual, dry-run por defecto y apunta al repo canónico',()=>{assert.match(sync,/workflow_dispatch:/);assert.match(sync,/default: true/);assert.match(sync,/Taller-SW-Web\/G6-Productos-Ofertas-docs/);});
