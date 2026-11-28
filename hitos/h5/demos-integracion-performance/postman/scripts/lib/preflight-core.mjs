import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import { join, resolve } from 'node:path';
import {
  ALL_AUTHORIZED_HOSTS,
  AUTHORIZED_HOSTS,
  CASE_METADATA,
  COLLECTION_PATH,
  COVERAGE_CSV_PATH,
  ENVIRONMENTS_DIR,
  OPENAPI_CONTRACT_PATH,
  PROFILES,
  SAFE_READ_ONLY_METHODS,
  SENSITIVE_VALUE_PATTERNS,
} from './constants.mjs';

export function isLoopbackHost(hostname) {
  return hostname === '127.0.0.1' || hostname === 'localhost' || hostname === '::1';
}

export function validateBaseUrl(baseUrl, environmentName) {
  const errors = [];
  if (!baseUrl || typeof baseUrl !== 'string') {
    return { ok: false, errors: ['baseUrl es obligatoria y debe ser una cadena no vacia.'] };
  }

  let parsed;
  try {
    parsed = new URL(baseUrl);
  } catch {
    return { ok: false, errors: ['baseUrl invalida: no es una URL bien formada.'] };
  }

  if (parsed.username || parsed.password) {
    errors.push('baseUrl no puede contener credenciales embebidas en la URL.');
  }

  const host = parsed.hostname.toLowerCase();
  const allowedForEnv = environmentName && AUTHORIZED_HOSTS[environmentName]
    ? AUTHORIZED_HOSTS[environmentName]
    : ALL_AUTHORIZED_HOSTS;

  if (!allowedForEnv.includes(host)) {
    errors.push(
      `Host no autorizado (${host}) para el entorno '${environmentName || 'default'}'. Hosts permitidos: ${allowedForEnv.join(', ')}.`,
    );
  }

  if (!isLoopbackHost(host) && parsed.protocol !== 'https:') {
    errors.push(`Entornos remotos requieren HTTPS obligatorio (recibido: ${parsed.protocol}).`);
  }

  if (isLoopbackHost(host) && parsed.protocol !== 'http:' && parsed.protocol !== 'https:') {
    errors.push(`Protocolo no soportado para entorno local: ${parsed.protocol}.`);
  }

  return { ok: errors.length === 0, errors, parsed };
}

export function validateRedirectTarget(targetUrl, environmentName) {
  const result = validateBaseUrl(targetUrl, environmentName);
  if (!result.ok) {
    return {
      allowed: false,
      reason: `Redireccion bloqueada hacia destino no autorizado: ${result.errors.join(' ')}`,
    };
  }
  return { allowed: true };
}

export function extractRequestsFromItems(items = [], folderPath = []) {
  const results = [];
  for (const item of items) {
    if (Array.isArray(item.item)) {
      results.push(...extractRequestsFromItems(item.item, [...folderPath, item.name]));
    } else if (item.request) {
      results.push({
        name: item.name,
        folderPath,
        method: (item.request.method || 'GET').toUpperCase(),
        url: typeof item.request.url === 'string' ? item.request.url : item.request.url?.raw || '',
        request: item.request,
        events: item.event || [],
      });
    }
  }
  return results;
}

export function scanFilesForSecrets(rootDir, { ignoreDirs = ['node_modules', '.git', '.tmp', 'raw-results'] } = {}) {
  const findings = [];
  if (!existsSync(rootDir)) return findings;

  function walk(dir) {
    for (const entry of readdirSync(dir)) {
      if (ignoreDirs.includes(entry)) continue;
      const fullPath = join(dir, entry);
      const stat = statSync(fullPath);
      if (stat.isDirectory()) {
        walk(fullPath);
      } else if (stat.isFile() && stat.size < 2 * 1024 * 1024) {
        if (entry.endsWith('.lock') || entry === 'package-lock.json') continue;
        if (fullPath.includes(`${join('tests', '')}`) || entry.endsWith('.test.mjs')) continue;
        const content = readFileSync(fullPath, 'utf8');
        for (const pattern of SENSITIVE_VALUE_PATTERNS) {
          pattern.lastIndex = 0;
          if (pattern.test(content)) {
            findings.push({
              file: fullPath,
              pattern: pattern.source,
            });
          }
        }
      }
    }
  }

  walk(rootDir);
  return findings;
}

export function parseOpenApiRoutes(openApiPath = OPENAPI_CONTRACT_PATH) {
  if (!existsSync(openApiPath)) {
    return { ok: false, routes: new Set(), pathCount: 0, operationCount: 0 };
  }
  const lines = readFileSync(openApiPath, 'utf8').split(/\r?\n/);
  const routes = new Set();
  const pathsSet = new Set();
  let inPaths = false;
  let currentPath = null;

  for (const line of lines) {
    if (line === 'paths:') {
      inPaths = true;
      continue;
    }
    if (inPaths && /^[a-zA-Z]/.test(line)) {
      break;
    }
    if (!inPaths) continue;

    const pathMatch = line.match(/^  (\/[^:\s]+):\s*$/);
    if (pathMatch) {
      currentPath = pathMatch[1];
      pathsSet.add(currentPath);
      continue;
    }
    const methodMatch = line.match(/^    (get|post|put|patch|delete|head|options):\s*$/);
    if (methodMatch && currentPath) {
      routes.add(`${methodMatch[1].toUpperCase()} ${currentPath}`);
    }
  }

  return { ok: true, routes, pathCount: pathsSet.size, operationCount: routes.size };
}

function normalizeCollectionPathToOpenApi(rawUrl) {
  const withoutQuery = String(rawUrl || '').split('?')[0];
  let pathPart = withoutQuery
    .replace('{{baseUrl}}', '')
    .replace('{{apiPrefix}}', '')
    .replace(/^https?:\/\/[^/]+/i, '');
  if (pathPart.startsWith('/api/v1')) {
    pathPart = pathPart.slice('/api/v1'.length);
  }
  // Replace Postman {{var}} segments with wildcard regex matcher for OpenAPI {param}
  return pathPart;
}

function matchesOpenApiRoute(method, normalizedPath, openApiRoutes) {
  const segs = normalizedPath.split('/').filter(Boolean);
  for (const route of openApiRoutes) {
    const [m, p] = route.split(' ');
    if (m !== method) continue;
    const oSegs = p.split('/').filter(Boolean);
    if (oSegs.length !== segs.length) continue;
    let match = true;
    for (let i = 0; i < segs.length; i += 1) {
      const isParam = oSegs[i].startsWith('{') && oSegs[i].endsWith('}');
      const isVar = segs[i].startsWith('{{') && segs[i].endsWith('}}');
      if (isParam) continue;
      if (isVar || oSegs[i] !== segs[i]) {
        match = false;
        break;
      }
    }
    if (match) return route;
  }
  return null;
}

export function validateCollectionAgainstOpenApi(
  collectionPath = COLLECTION_PATH,
  openApiPath = OPENAPI_CONTRACT_PATH,
) {
  const errors = [];
  const col = validateCollectionStructure(collectionPath);
  if (!col.ok) {
    return { ok: false, errors: col.errors, matchedCount: 0, openApiOperationCount: 0 };
  }

  const parsed = parseOpenApiRoutes(openApiPath);
  if (!parsed.ok) {
    return {
      ok: false,
      errors: [`No se pudo leer contrato OpenAPI oficial en ${openApiPath}`],
      matchedCount: 0,
      openApiOperationCount: 0,
    };
  }

  let matchedCount = 0;
  for (const req of col.requests) {
    const pmId = req.name.match(/^(PM-\d+[A-Z]?)\b/)?.[1];
    const meta = CASE_METADATA[pmId];
    if (!meta) {
      errors.push(`Caso '${pmId}' no esta registrado en CASE_METADATA (scripts/lib/constants.mjs).`);
      continue;
    }
    if (meta.openApiExempt) {
      matchedCount += 1;
      continue;
    }
    const normalizedPath = normalizeCollectionPathToOpenApi(req.url);
    const matched = matchesOpenApiRoute(req.method, normalizedPath, parsed.routes);
    if (!matched) {
      errors.push(
        `Operacion fuera de OpenAPI oficial (${req.method} ${normalizedPath}) en "${req.name}".`,
      );
    } else {
      matchedCount += 1;
    }
  }

  return {
    ok: errors.length === 0,
    errors,
    matchedCount,
    openApiOperationCount: parsed.operationCount,
  };
}

export function validateMatrixParity(
  collectionPath = COLLECTION_PATH,
  csvPath = COVERAGE_CSV_PATH,
) {
  const errors = [];
  const col = validateCollectionStructure(collectionPath);
  if (!col.ok) return { ok: false, errors: col.errors };
  if (!existsSync(csvPath)) {
    return { ok: false, errors: [`Matriz CSV no encontrada: ${csvPath}`] };
  }

  const collectionIds = new Set(
    col.requests.map((r) => r.name.match(/^(PM-\d+[A-Z]?)\b/)?.[1]).filter(Boolean),
  );
  const metaIds = new Set(Object.keys(CASE_METADATA));

  for (const id of collectionIds) {
    if (!metaIds.has(id)) {
      errors.push(`ID ${id} existe en la coleccion pero falta en CASE_METADATA.`);
    }
  }
  for (const id of metaIds) {
    if (!collectionIds.has(id)) {
      errors.push(`ID ${id} existe en CASE_METADATA pero falta en la coleccion.`);
    }
  }

  const csvLines = readFileSync(csvPath, 'utf8').trim().split(/\r?\n/).slice(1);
  const csvImplementedIds = new Set();
  for (const line of csvLines) {
    const id = line.split(',')[0]?.trim();
    if (id && /^PM-\d+[A-Z]?$/.test(id)) {
      csvImplementedIds.add(id);
    }
  }

  for (const id of collectionIds) {
    if (!csvImplementedIds.has(id)) {
      errors.push(`ID ${id} existe en la coleccion pero falta en cobertura-integracion.csv.`);
    }
  }
  for (const id of csvImplementedIds) {
    if (!collectionIds.has(id)) {
      errors.push(`ID ${id} existe en cobertura-integracion.csv pero falta en la coleccion.`);
    }
  }

  return {
    ok: errors.length === 0,
    errors,
    collectionCount: collectionIds.size,
    csvCount: csvImplementedIds.size,
  };
}

export function validateCollectionStructure(collectionPath = COLLECTION_PATH) {
  const errors = [];
  if (!existsSync(collectionPath)) {
    return { ok: false, errors: [`Coleccion no encontrada: ${collectionPath}`], collection: null, requests: [] };
  }

  let collection;
  try {
    collection = JSON.parse(readFileSync(collectionPath, 'utf8'));
  } catch (err) {
    return { ok: false, errors: [`Coleccion JSON invalida: ${err.message}`], collection: null, requests: [] };
  }

  if (!collection.info?.name || !collection.info?.schema?.includes('v2.1.0')) {
    errors.push('La coleccion debe declarar info.name y schema Postman Collection v2.1.0.');
  }

  if (!Array.isArray(collection.item) || collection.item.length === 0) {
    errors.push('La coleccion debe contener al menos una carpeta o solicitud.');
  }

  const requests = extractRequestsFromItems(collection.item || []);
  const seenIds = new Set();

  for (const req of requests) {
    const idMatch = req.name.match(/^(PM-\d+[A-Z]?)\b/);
    if (!idMatch) {
      errors.push(`Solicitud sin prefijo ID PM valido: "${req.name}"`);
    } else {
      const id = idMatch[1];
      if (seenIds.has(id)) {
        errors.push(`ID PM duplicado en coleccion: ${id}`);
      }
      seenIds.add(id);
    }

    if (!SAFE_READ_ONLY_METHODS.has(req.method)) {
      errors.push(
        `Metodo mutante '${req.method}' no permitido en coleccion de lectura por defecto: "${req.name}"`,
      );
    }

    const rawUrl = req.url;
    if (rawUrl && /^https?:\/\//i.test(rawUrl)) {
      const urlCheck = validateBaseUrl(rawUrl);
      if (!urlCheck.ok) {
        errors.push(`URL absoluta no autorizada en "${req.name}": ${urlCheck.errors.join(' ')}`);
      }
    }

    const hasTestScript = (req.events || []).some(
      (ev) => ev.listen === 'test' && Array.isArray(ev.script?.exec) && ev.script.exec.join('\n').trim().length > 0,
    );
    if (!hasTestScript) {
      errors.push(`La solicitud "${req.name}" no tiene script de aserciones (event: test).`);
    }
  }

  return { ok: errors.length === 0, errors, collection, requests };
}

export function runPreflight(options = {}) {
  const {
    baseUrl,
    environmentName = 'azure-apim-chile',
    profile = 'apim-edge',
    folder = null,
    requireAuth = true,
    accessToken = '',
    marketplaceAccessToken = '',
    ventasAccessToken = '',
    collectionPath = COLLECTION_PATH,
    scanRoot = resolve(ENVIRONMENTS_DIR, '..'),
    skipSecretScan = false,
    fixtures = {},
  } = options;

  const checks = [];
  const errors = [];
  const warnings = [];

  const nodeMajor = Number(process.versions.node.split('.')[0]);
  const nodeOk = Number.isFinite(nodeMajor) && nodeMajor >= 20;
  checks.push({ id: 'node_version', ok: nodeOk, detail: `Node.js ${process.versions.node}` });
  if (!nodeOk) errors.push(`Se requiere Node.js >= 20 (actual: ${process.versions.node}).`);

  if (profile && !PROFILES[profile] && !folder) {
    const msg = `Perfil desconocido: '${profile}'. Perfiles validos: ${Object.keys(PROFILES).join(', ')}.`;
    checks.push({ id: 'profile', ok: false, detail: msg });
    errors.push(msg);
  } else {
    checks.push({ id: 'profile', ok: true, detail: folder ? `Carpeta: ${folder}` : `Perfil: ${profile}` });
  }

  const colCheck = validateCollectionStructure(collectionPath);
  checks.push({
    id: 'collection',
    ok: colCheck.ok,
    detail: colCheck.ok ? `${colCheck.requests.length} solicitudes validadas` : colCheck.errors.join('; '),
  });
  if (!colCheck.ok) errors.push(...colCheck.errors);

  const urlCheck = validateBaseUrl(baseUrl, environmentName);
  checks.push({
    id: 'base_url',
    ok: urlCheck.ok,
    detail: urlCheck.ok ? `${urlCheck.parsed.origin} (${environmentName})` : urlCheck.errors.join('; '),
  });
  if (!urlCheck.ok) errors.push(...urlCheck.errors);

  const hasAnyToken = Boolean(
    (accessToken && accessToken.trim()) ||
    (marketplaceAccessToken && marketplaceAccessToken.trim()) ||
    (ventasAccessToken && ventasAccessToken.trim()),
  );
  if (requireAuth && !hasAnyToken) {
    const msg = 'No se proporciono G6_ACCESS_TOKEN ni tokens M2M (G6_MARKETPLACE_ACCESS_TOKEN / G6_VENTAS_ACCESS_TOKEN) para pruebas autenticadas.';
    checks.push({ id: 'credentials', ok: false, detail: msg });
    errors.push(msg);
  } else {
    checks.push({
      id: 'credentials',
      ok: true,
      detail: hasAnyToken
        ? 'Credenciales presentes en memoria (redactadas); casos sin su token especifico se registraran como NOT_RUN'
        : 'Modo sin autenticacion explicito (--allow-no-auth): solo se ejecutaran casos publicos/negativos 401/404; el resto quedara NOT_RUN',
    });
  }

  const priceMin = fixtures.priceMin !== undefined ? Number(fixtures.priceMin) : 0;
  const priceMax = fixtures.priceMax !== undefined ? Number(fixtures.priceMax) : 100;
  const fixturesOk = Number.isFinite(priceMin) && Number.isFinite(priceMax) && priceMin >= 0 && priceMin <= priceMax;
  checks.push({
    id: 'fixtures',
    ok: fixturesOk,
    detail: fixturesOk ? `Rango de precios valido [${priceMin}, ${priceMax}]` : `Rango de precios invalido [${fixtures.priceMin}, ${fixtures.priceMax}]`,
  });
  if (!fixturesOk) errors.push('Fixtures de rango de precios invalidos: priceMin debe ser >= 0 y <= priceMax.');

  if (!skipSecretScan) {
    const secretFindings = scanFilesForSecrets(scanRoot);
    const secretsOk = secretFindings.length === 0;
    checks.push({
      id: 'versioned_secrets',
      ok: secretsOk,
      detail: secretsOk ? 'Sin secretos detectados en archivos versionados' : `${secretFindings.length} hallazgos posibles`,
    });
    if (!secretsOk) {
      errors.push(`Se detectaron posibles secretos en archivos del directorio postman: ${secretFindings.map((f) => f.file).join(', ')}`);
    }
  }

  if (environmentName === 'azure-aca-chile') {
    warnings.push(
      'Entorno ACA directo protegido por Modalidad B (espera 403 RBAC desde IPs externas). Para pruebas de borde externas utilice azure-apim-chile.',
    );
  }

  return {
    ok: errors.length === 0,
    checks,
    errors,
    warnings,
    resolvedHost: urlCheck.parsed?.hostname || null,
  };
}
