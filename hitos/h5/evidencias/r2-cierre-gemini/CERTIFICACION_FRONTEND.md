# Certificación frontend en curso

Primera ejecución nueva: `npx playwright test --config playwright.real.config.ts --reporter=line`, laboratorio Docker PostgreSQL TLS descartable, nueve procesos G6, Vite API y JWT/JWKS locales. Resultado exit1: 3 PASS, 13 FAIL, 16 ejecutadas, cero retries, duración3.8min. No acredita frontend certificado.

Fallos detectados: selectores spinbutton obsoletos (Mantine expone textbox), Taxonomy usa botón y confirmación slug; campos Audit snake_case; Pricing numeric vs string; fixture Promotion rechazado422; Combo etiqueta Nombre no encontrada; Bulk plantilla vacía y entrada fichero no encontrada; seguridad una lectura400; producto devuelve identificador distinto del asumido en transversal. Cada causa requiere contraste contractual, no aceptar respuestas defectuosas.

Se ajustaron cuatro flujos (Catalog/Taxonomy/Audit/Inventory) y se lanzó corrida focalizada; resultado todavía pendiente. No presentar cambios como verificados. Evidencia diagnóstica local en frontend/tests/playwright-real-certification.log y test-results (puede contener datos técnicos, no se publica cruda).

LOCAL_G6_GO=false; CODE_AND_LAB_FUNCTIONAL_READY=false; AZURE_G6_GO=false.
