#!/usr/bin/env node
let data;
try { data=JSON.parse(process.argv[2]??''); } catch { console.error('FALLO: JSON de resultados inválido.'); process.exit(2); }
if(data.contrato?.result!=='success'){console.error(`FALLO: contrato: ${data.contrato?.result??'ausente'}`);process.exit(1);}
console.log('Correcto: las validaciones contractuales, Swagger, Python y Playwright finalizaron correctamente.');
