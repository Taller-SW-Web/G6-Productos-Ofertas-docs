/* global SwaggerUIBundle */
async function start() {
  const [spec, manifest] = await Promise.all(['openapi.json', 'manifest.json'].map(async file => {
    const response = await fetch(new URL(file, document.baseURI));
    if (!response.ok) throw new Error(`No se pudo cargar ${file}`);
    return response.json();
  }));
  document.getElementById('status').textContent = `${manifest.version} · ${manifest.operations} operaciones · ${manifest.schemas} schemas${manifest.strictErrors.length ? ' · Validación estricta pendiente: clave redundante en el YAML fuente; consultar manifiesto.' : ''}`;
  window.ui = SwaggerUIBundle({
    spec,
    dom_id: '#swagger-ui',
    deepLinking: true,
    filter: true,
    displayOperationId: true,
    showExtensions: true,
    showCommonExtensions: true,
    defaultModelsExpandDepth: 1,
    docExpansion: 'none',
    supportedSubmitMethods: [],
    tryItOutEnabled: false,
    queryConfigEnabled: false,
    validatorUrl: null,
    persistAuthorization: false,
    withCredentials: false,
    plugins: [() => ({ components: { authorizeBtn: () => null, authorizeOperationBtn: () => null } })],
    requestInterceptor: () => { throw new Error('Portal de consulta: peticiones API deshabilitadas'); }
  });
}
start().catch(error => { document.getElementById('status').textContent = error.message; });
