# Certificación frontend en curso

Última corrida íntegra: **16/16 PASS**, 0 FAIL, 0 SKIP, 0 flaky, retries=0. Inicio UTC 2026-11-27T00:15:42.408Z, duración129.38s. Comando: `npx playwright test --config playwright.real.config.ts`. Evidencia saneada: FRONTEND_16_CORREGIDOS.json (hash del reporte original, HEAD base y hash del diff probado). Cambios publicados en Frontend8ebdc31; esta corrida ocurrió inmediatamente antes del commit, con ese contenido.

Laboratorio local aislado autorizado expresamente: Chromium→React/Vite en modo API→Gateway→ocho proveedores reales→PostgreSQL Docker TLS descartable. G7 RS256/JWKS local; G5 es servidor contractual controlado; broker HTTP in-memory. No acredita G7 externo, G5 real ni Azure Service Bus administrado.

Se verificaron Catalog y variantes, Taxonomy, Pricing, Audit, Promotions/cupones, Combos, Inventory, Bulk (admisión, procesamiento terminal íntegro y CSV inválido), autenticación/rotación/revocación, navegación protegida,401/403,429 y503 sin reintento ambiguo; transversal causal incluye N01. Cada caso conserva aserciones de respuesta, persistencia y actualización de UI según su flujo.

Las corridas diagnósticas anteriores fallaron por selectores/DTO/fixtures desactualizados y dos presupuestos temporales de la prueba. Se corrigieron: controles textbox reales, slug confirmado, IDs/campos contractuales, producto Promotion existente, descarga plantilla real, atributos Bulk array JSON y navegación upload→revisión→confirmación. Catalog espera preparación terminal sin presuponer PENDING. Bulk espera hasta40s, presupuesto ya usado por certificación HTTP: la traza mostró relay Pricing de una entrega por segundo y una terminación real a6662ms; la ventana previa de6250ms fallaba por backlog legítimo. No se cambió producción ni se añadieron retries Playwright.

Typecheck y lint: PASS. Unitarias y build actuales en ejecución; resultado se actualizará al terminar. Faltan dos regresiones integrales limpias consecutivas asociadas a SHAs finales y completar auditoría HTTP/matrices. CODE_AND_LAB_FUNCTIONAL_READY=false; LOCAL_G6_GO=false; AZURE_G6_GO=false.
