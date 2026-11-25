const parsers={
 sarif(input){const x=JSON.parse(input);if(x.version!=='2.1.0'||!Array.isArray(x.runs))throw new Error('SARIF inválido: version/runs');return {format:'SARIF',runs:x.runs.length,findings:x.runs.flatMap(r=>r.results||[]).length};},
 sbom(input){const x=JSON.parse(input);if(!x.bomFormat||!Array.isArray(x.components))throw new Error('SBOM inválido: bomFormat/components');return {format:'SBOM',bomFormat:x.bomFormat,components:x.components.length};},
 vulnerability(input){const x=JSON.parse(input);if(!Array.isArray(x.findings||x.vulnerabilities))throw new Error('Reporte vulnerabilidades inválido.');return {format:'VULNERABILITY',findings:(x.findings||x.vulnerabilities).length,manual_review:'PENDING'};},
 k6(input){const x=JSON.parse(input);if(!Array.isArray(x.metrics)&&!x.root_group)throw new Error('k6 JSON inválido: metrics/root_group ausente.');return {format:'K6',metrics:Object.keys(x.metrics||{}).length};},
 junit(input){if(!/<(testsuite|testsuites)\b/.test(input)||!/<testcase\b/.test(input))throw new Error('JUnit inválido.');return {format:'JUnit',tests:(input.match(/<testcase\b/g)||[]).length,failures:(input.match(/<(failure|error)\b/g)||[]).length};},
 github(input){const x=JSON.parse(input);if(typeof x.run_success!=='boolean'||typeof x.job_success!=='boolean'||typeof x.artifact_verified!=='boolean'||typeof x.sha_matches!=='boolean'||typeof x.manual_review!=='boolean')throw new Error('Metadatos GitHub incompletos; no inferir estados.');return {format:'GITHUB',...x};}
};
export function parseAdapter(format,input){const parser=parsers[format];if(!parser)throw new Error(`Adaptador no soportado: ${format}`);return parser(input);}
