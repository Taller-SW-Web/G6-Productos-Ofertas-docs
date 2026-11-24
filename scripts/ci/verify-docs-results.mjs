#!/usr/bin/env node
let data;
try { data=JSON.parse(process.argv[2]??''); } catch { console.error('FALLO: JSON de resultados inválido.'); process.exit(2); }
if(data.contrato?.result!=='success'){console.error(`FALLO: contrato: ${data.contrato?.result??'ausente'}`);process.exit(1);}
if(data.prepare_pages?.result!=='success'){console.error(`FALLO: preparación y validación integral de Pages: ${data.prepare_pages?.result??'ausente'}`);process.exit(1);}
console.log('Correcto: las validaciones contractuales, Swagger, Python, Playwright y la preparación integral de Pages finalizaron correctamente.');
