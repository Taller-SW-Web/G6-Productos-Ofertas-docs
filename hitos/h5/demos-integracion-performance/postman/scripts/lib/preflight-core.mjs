import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import { join, resolve } from 'node:path';
import {
  ALL_AUTHORIZED_HOSTS,
  AUTHORIZED_HOSTS,
  COLLECTION_PATH,
  ENVIRONMENTS_DIR,
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
    return { ok: false, errors: [`baseUrl invalida: no es una URL bien formada.`] };
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
        // Skip test files that intentionally use synthetic secrets
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
    environmentName = 'azure-aca-chile',
    profile = 'smoke',
    folder = null,
    requireAuth = true,
    accessToken = '',
    serviceAccessToken = '',
    collectionPath = COLLECTION_PATH,
    scanRoot = resolve(ENVIRONMENTS_DIR, '..'),
    skipSecretScan = false,
    fixtures = {},
  } = options;

  const checks = [];
  const errors = [];
  const warnings = [];

  // 1. Node.js version
  const nodeMajor = Number(process.versions.node.split('.')[0]);
  const nodeOk = Number.isFinite(nodeMajor) && nodeMajor >= 20;
  checks.push({ id: 'node_version', ok: nodeOk, detail: `Node.js ${process.versions.node}` });
  if (!nodeOk) errors.push(`Se requiere Node.js >= 20 (actual: ${process.versions.node}).`);

  // 2. Profile / folder selection
  if (profile && !PROFILES[profile] && !folder) {
    const msg = `Perfil desconocido: '${profile}'. Perfiles validos: ${Object.keys(PROFILES).join(', ')}.`;
    checks.push({ id: 'profile', ok: false, detail: msg });
    errors.push(msg);
  } else {
    checks.push({ id: 'profile', ok: true, detail: folder ? `Carpeta: ${folder}` : `Perfil: ${profile}` });
  }

  // 3. Collection validity
  const colCheck = validateCollectionStructure(collectionPath);
  checks.push({
    id: 'collection',
    ok: colCheck.ok,
    detail: colCheck.ok ? `${colCheck.requests.length} solicitudes validadas` : colCheck.errors.join('; '),
  });
  if (!colCheck.ok) errors.push(...colCheck.errors);

  // 4. Base URL & authorized host
  const urlCheck = validateBaseUrl(baseUrl, environmentName);
  checks.push({
    id: 'base_url',
    ok: urlCheck.ok,
    detail: urlCheck.ok ? `${urlCheck.parsed.origin} (${environmentName})` : urlCheck.errors.join('; '),
  });
  if (!urlCheck.ok) errors.push(...urlCheck.errors);

  // 5. Credentials check
  const hasToken = Boolean(accessToken && accessToken.trim().length > 0);
  const hasServiceToken = Boolean(serviceAccessToken && serviceAccessToken.trim().length > 0);
  if (requireAuth && !hasToken && !hasServiceToken) {
    const msg = 'No se proporciono accessToken (userBearer) ni serviceAccessToken (serviceBearer) para pruebas autenticadas.';
    checks.push({ id: 'credentials', ok: false, detail: msg });
    errors.push(msg);
  } else {
    checks.push({
      id: 'credentials',
      ok: true,
      detail: hasToken
        ? 'Credencial userBearer presente en memoria (redactada)'
        : hasServiceToken
          ? 'Credencial serviceBearer presente en memoria (redactada)'
          : 'Autenticacion no requerida por configuracion explicita',
    });
  }

  // 6. Fixtures validation (priceMin <= priceMax when provided)
  const priceMin = fixtures.priceMin !== undefined ? Number(fixtures.priceMin) : 0;
  const priceMax = fixtures.priceMax !== undefined ? Number(fixtures.priceMax) : 100;
  const fixturesOk = Number.isFinite(priceMin) && Number.isFinite(priceMax) && priceMin >= 0 && priceMin <= priceMax;
  checks.push({
    id: 'fixtures',
    ok: fixturesOk,
    detail: fixturesOk ? `Rango de precios valido [${priceMin}, ${priceMax}]` : `Rango de precios invalido [${fixtures.priceMin}, ${fixtures.priceMax}]`,
  });
  if (!fixturesOk) errors.push('Fixtures de rango de precios invalidos: priceMin debe ser >= 0 y <= priceMax.');

  // 7. Secret scan on versioned files
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
      'APIM aun no cuenta con instancia operativa desplegada (NOT_RUN_BLOCKED_INFRA); la ejecucion apunta al Gateway ACA autorizado.',
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
