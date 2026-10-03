// Run with Node.js and the yaml package, supplied via NODE_PATH when needed.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const YAML = require('yaml');
const root = path.resolve(__dirname, '../..');
const workflow = YAML.parse(fs.readFileSync(path.join(root, '.github/workflows/sync-workspaces.yml'), 'utf8'));
const existing = YAML.parse(fs.readFileSync(path.join(root, '.github/workflows/sync-master.yml'), 'utf8'));
const owners = ['castilla', 'poma', 'cueva', 'lopez', 'taco', 'vera'];
assert.deepEqual(workflow.on.push.branches, owners);
assert.deepEqual(workflow.on.workflow_run.workflows, [existing.name]);
assert.deepEqual(workflow.on.workflow_run.types, ['completed']);
assert.deepEqual(workflow.on.workflow_run.branches, ['master']);
assert.equal(workflow.on.schedule[0].cron, '7/15 * * * *');
assert.equal(workflow.on.workflow_dispatch.inputs.dry_run.default, true);
assert.deepEqual(workflow.permissions, {contents: 'read'});
assert.deepEqual(workflow.jobs.sync.permissions, {contents: 'write'});
assert.equal(workflow.jobs.sync.concurrency.group, 'sync-workspace-${{ matrix.source }}');
assert.equal(workflow.jobs.sync.concurrency['cancel-in-progress'], false);
assert.equal(workflow.jobs.sync.strategy['fail-fast'], false);
assert.equal(workflow.jobs.sync.if, "needs.plan.outputs.has_work == 'true'");
assert.match(workflow.jobs.plan.if, /conclusion == 'success'/);
assert.match(workflow.jobs.plan.if, /head_repository.full_name == github.repository/);
assert.match(workflow.jobs.plan.if, /vars.SYNC_WORKSPACES_ENABLED == 'true'/);
assert.equal(workflow.jobs.plan.outputs.matrix, '${{ steps.plan.outputs.matrix }}');
assert.equal(workflow.jobs.plan.outputs.has_work, '${{ steps.plan.outputs.has_work }}');
for (const job of Object.values(workflow.jobs)) {
  const checkout = job.steps.find(step => step.uses);
  assert.equal(checkout.uses, 'actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1');
  assert.equal(checkout.with.ref, '${{ github.event.repository.default_branch }}');
  assert.equal(checkout.with['persist-credentials'], false);
}
assert.equal(workflow.jobs.sync.steps[1].env.SYNC_GITHUB_TOKEN, '${{ github.token }}');
assert.match(workflow.jobs.sync.steps[1].run, /--apply/);
console.log('Contrato del workflow: 25 comprobaciones PASS.');
