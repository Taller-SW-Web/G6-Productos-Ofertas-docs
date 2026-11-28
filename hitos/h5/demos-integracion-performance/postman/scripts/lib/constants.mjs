import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export const POSTMAN_ROOT = resolve(__dirname, '..', '..');
export const DOCS_ROOT = resolve(POSTMAN_ROOT, '..', '..', '..', '..');
export const COLLECTION_PATH = resolve(POSTMAN_ROOT, 'g6-h5-integration.postman_collection.json');
export const ENVIRONMENTS_DIR = resolve(POSTMAN_ROOT, 'environments');
export const EVIDENCIAS_DIR = resolve(POSTMAN_ROOT, 'evidencias');
export const COVERAGE_CSV_PATH = resolve(POSTMAN_ROOT, 'matrices', 'cobertura-integracion.csv');
export const OPENAPI_CONTRACT_PATH = resolve(DOCS_ROOT, 'contratos', 'http', 'openapi.yaml');
export const OPENAPI_CONTRACT_VERSION = '0.7.0-rc.3';

/**
 * Lista autorizada de hosts derivada de fuentes oficiales del proyecto:
 * - APIM Chile live (corte Axel Cueva PR #152: apim-g6-productos-chile.azure-api.net)
 * - Gateway ACA Chile Central (Frontend vercel.json; protegido por Modalidad B)
 * - Entorno local de desarrollo y harness (loopback)
 */
export const AUTHORIZED_HOSTS = Object.freeze({
  'azure-apim-chile': Object.freeze([
    'apim-g6-productos-chile.azure-api.net',
  ]),
  'azure-aca-chile': Object.freeze([
    'api-gateway.calmgrass-aec0b33c.chilecentral.azurecontainerapps.io',
  ]),
  local: Object.freeze(['127.0.0.1', 'localhost']),
});

export const ALL_AUTHORIZED_HOSTS = Object.freeze([
  ...AUTHORIZED_HOSTS['azure-apim-chile'],
  ...AUTHORIZED_HOSTS['azure-aca-chile'],
  ...AUTHORIZED_HOSTS.local,
]);

export const PROFILES = Object.freeze({
  'apim-edge': Object.freeze({
    name: 'apim-edge',
    description: 'Verificacion de borde APIM live (negativos 401/404, correlacion y smoke autorizado sobre /api/v1)',
    folders: Object.freeze([
      '01 - Catalog y Pricing',
      '09 - APIM, Gateway y G7',
    ]),
  }),
  smoke: Object.freeze({
    name: 'smoke',
    description: 'Cadena critica HTTP (Preflight, Catalog->Pricing y negativos contractuales G7/Gateway)',
    folders: Object.freeze([
      '00 - Preflight y autenticacion',
      '01 - Catalog y Pricing',
      '09 - APIM, Gateway y G7',
    ]),
  }),
  integration: Object.freeze({
    name: 'integration',
    description: 'Suite completa de lectura segura sobre los ocho microservicios de G6 y casos negativos',
    folders: Object.freeze([
      '00 - Preflight y autenticacion',
      '01 - Catalog y Pricing',
      '02 - Preparacion comercial e Inventory',
      '03 - Combos',
      '04 - Bulk y Catalog',
      '05 - Pricing y Price Audit',
      '06 - Taxonomy y Catalog',
      '07 - Promotions',
      '08 - Inventory',
      '09 - APIM, Gateway y G7',
      '10 - Integraciones externas',
    ]),
  }),
});

export const SAFE_READ_ONLY_METHODS = new Set(['GET', 'HEAD', 'OPTIONS']);

export const SENSITIVE_KEY_PATTERNS = [
  /authorization/i,
  /token/i,
  /secret/i,
  /password/i,
  /contrasena/i,
  /passwd/i,
  /cookie/i,
  /set-cookie/i,
  /api[-_]?key/i,
  /subscription[-_]?key/i,
  /connection[-_]?string/i,
  /private[-_]?key/i,
  /client[-_]?secret/i,
  /refresh/i,
  /supabase/i,
];

export const SENSITIVE_VALUE_PATTERNS = [
  /\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\b/g,
  /\bBearer\s+[A-Za-z0-9._~+/=-]{8,}\b/gi,
  /\bBasic\s+[A-Za-z0-9+/=]{8,}\b/gi,
  /\bpostgres(?:ql)?:\/\/[^\s"'<>]+/gi,
  /\bEndpoint=sb:\/\/[^\s"'<>]+/gi,
  /SharedAccessKey=[A-Za-z0-9+/=%]+/gi,
  /\b(?:ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{20,}\b/g,
  /([?&](?:access_token|token|api_key|apikey|client_secret|password|secret)=)(?!\[REDACTED\]|%5BREDACTED%5D)[^&#\s]+/gi,
];

/**
 * Metadatos y requisito de credencial por caso PM.
 * authRequirement:
 *   - 'none': no requiere credencial (o prueba negativa sin token/token invalido)
 *   - 'user': requiere G6_ACCESS_TOKEN (userBearer GESTOR_COMERCIAL)
 *   - 'restricted': requiere G6_RESTRICTED_ACCESS_TOKEN (identidad sin permiso -> 403)
 *   - 'marketplace': requiere G6_MARKETPLACE_ACCESS_TOKEN (serviceBearer modulo-marketplace)
 *   - 'ventas': requiere G6_VENTAS_ACCESS_TOKEN (serviceBearer modulo-ventas)
 */
export const CASE_METADATA = Object.freeze({
  'PM-001': { intId: 'INT-07', services: ['api-gateway'], type: 'lectura', scope: 'public-health', authRequirement: 'none', openApiExempt: true },
  'PM-001B': { intId: 'INT-07', services: ['api-gateway'], type: 'lectura', scope: 'public-health', authRequirement: 'none', openApiExempt: true },
  'PM-002': { intId: 'INT-01', services: ['api-gateway', 'catalog-svc'], type: 'lectura', scope: 'catalogo:leer / GESTOR_COMERCIAL', authRequirement: 'user' },
  'PM-003A': { intId: 'INT-01', services: ['api-gateway', 'catalog-svc', 'pricing-svc'], type: 'lectura', scope: 'catalogo:leer / GESTOR_COMERCIAL', authRequirement: 'user' },
  'PM-003B': { intId: 'INT-01', services: ['api-gateway', 'catalog-svc', 'pricing-svc'], type: 'lectura', scope: 'catalogo:leer / GESTOR_COMERCIAL', authRequirement: 'user' },
  'PM-003C': { intId: 'INT-01', services: ['api-gateway', 'catalog-svc'], type: 'lectura', scope: 'catalogo:leer / GESTOR_COMERCIAL', authRequirement: 'user' },
  'PM-003D': { intId: 'INT-01', services: ['api-gateway', 'pricing-svc'], type: 'lectura', scope: 'precios:leer / GESTOR_COMERCIAL', authRequirement: 'user' },
  'PM-004': { intId: 'INT-07', services: ['api-gateway'], type: 'negativo', scope: 'sin-autenticacion', authRequirement: 'none' },
  'PM-004B': { intId: 'INT-07', services: ['api-gateway'], type: 'negativo', scope: 'token-invalido', authRequirement: 'none' },
  'PM-005': { intId: 'INT-07', services: ['api-gateway', 'price-audit-svc'], type: 'negativo', scope: 'restringido (403)', authRequirement: 'restricted' },
  'PM-006': { intId: 'INT-01', services: ['api-gateway', 'catalog-svc'], type: 'negativo', scope: 'catalogo:leer / GESTOR_COMERCIAL', authRequirement: 'user' },
  'PM-007A': { intId: 'INT-01', services: ['api-gateway', 'catalog-svc'], type: 'negativo', scope: 'catalogo:leer / GESTOR_COMERCIAL', authRequirement: 'user' },
  'PM-007B': { intId: 'INT-01', services: ['api-gateway', 'catalog-svc'], type: 'negativo', scope: 'catalogo:leer / GESTOR_COMERCIAL', authRequirement: 'user' },
  'PM-008': { intId: 'INT-07', services: ['api-gateway'], type: 'negativo', scope: 'ruta-inexistente', authRequirement: 'none', openApiExempt: true },
  'PM-010': { intId: 'INT-01', services: ['api-gateway', 'catalog-svc'], type: 'lectura', scope: 'GESTOR_COMERCIAL', authRequirement: 'user' },
  'PM-011': { intId: 'INT-01', services: ['api-gateway', 'catalog-svc'], type: 'lectura', scope: 'catalogo:leer / GESTOR_COMERCIAL', authRequirement: 'user' },
  'PM-012': { intId: 'INT-02', services: ['api-gateway', 'inventory-svc'], type: 'lectura', scope: 'inventario:disponibilidad:leer / GESTOR_COMERCIAL', authRequirement: 'user' },
  'PM-020': { intId: 'INT-01', services: ['api-gateway', 'combos-svc'], type: 'lectura', scope: 'GESTOR_COMERCIAL', authRequirement: 'user' },
  'PM-021': { intId: 'INT-01', services: ['api-gateway', 'combos-svc'], type: 'negativo', scope: 'combos:leer / GESTOR_COMERCIAL', authRequirement: 'user' },
  'PM-030': { intId: 'INT-04', services: ['api-gateway', 'bulk-svc'], type: 'lectura', scope: 'GESTOR_COMERCIAL', authRequirement: 'user' },
  'PM-031': { intId: 'INT-04', services: ['api-gateway', 'bulk-svc'], type: 'negativo', scope: 'GESTOR_COMERCIAL', authRequirement: 'user' },
  'PM-040': { intId: 'INT-05', services: ['api-gateway', 'pricing-svc'], type: 'lectura', scope: 'precios:leer / GESTOR_COMERCIAL', authRequirement: 'user' },
  'PM-041': { intId: 'INT-05', services: ['api-gateway', 'pricing-svc'], type: 'negativo', scope: 'precios:leer / GESTOR_COMERCIAL', authRequirement: 'user' },
  'PM-042': { intId: 'INT-05', services: ['api-gateway', 'price-audit-svc'], type: 'lectura', scope: 'GESTOR_COMERCIAL', authRequirement: 'user' },
  'PM-050': { intId: 'INT-06', services: ['api-gateway', 'taxonomy-svc'], type: 'lectura', scope: 'catalogo:leer / GESTOR_COMERCIAL', authRequirement: 'user' },
  'PM-051': { intId: 'INT-06', services: ['api-gateway', 'taxonomy-svc'], type: 'lectura', scope: 'catalogo:leer / GESTOR_COMERCIAL', authRequirement: 'user' },
  'PM-052': { intId: 'INT-06', services: ['api-gateway', 'taxonomy-svc'], type: 'lectura', scope: 'catalogo:leer / GESTOR_COMERCIAL', authRequirement: 'user' },
  'PM-053': { intId: 'INT-06', services: ['api-gateway', 'taxonomy-svc'], type: 'lectura', scope: 'catalogo:leer / GESTOR_COMERCIAL', authRequirement: 'user' },
  'PM-054': { intId: 'INT-06', services: ['api-gateway', 'taxonomy-svc'], type: 'negativo', scope: 'catalogo:leer / GESTOR_COMERCIAL', authRequirement: 'user' },
  'PM-060': { intId: 'INT-03', services: ['api-gateway', 'promotions-svc'], type: 'lectura', scope: 'promociones:leer / GESTOR_COMERCIAL', authRequirement: 'user' },
  'PM-061': { intId: 'INT-03', services: ['api-gateway', 'promotions-svc'], type: 'lectura', scope: 'GESTOR_COMERCIAL', authRequirement: 'user' },
  'PM-062': { intId: 'INT-03', services: ['api-gateway', 'promotions-svc'], type: 'lectura', scope: 'GESTOR_COMERCIAL', authRequirement: 'user' },
  'PM-070': { intId: 'INT-02', services: ['api-gateway', 'inventory-svc'], type: 'lectura', scope: 'GESTOR_COMERCIAL', authRequirement: 'user' },
  'PM-071': { intId: 'INT-02', services: ['api-gateway', 'inventory-svc'], type: 'lectura', scope: 'GESTOR_COMERCIAL', authRequirement: 'user' },
  'PM-072': { intId: 'INT-02', services: ['api-gateway', 'inventory-svc'], type: 'lectura', scope: 'GESTOR_COMERCIAL', authRequirement: 'user' },
  'PM-080': { intId: 'INT-09', services: ['api-gateway', 'catalog-svc'], type: 'lectura', scope: 'serviceBearer:modulo-marketplace:catalogo:leer', authRequirement: 'marketplace' },
  'PM-081': { intId: 'INT-09', services: ['api-gateway', 'inventory-svc'], type: 'lectura', scope: 'serviceBearer:modulo-marketplace:inventario:disponibilidad:leer', authRequirement: 'marketplace' },
  'PM-082': { intId: 'INT-09', services: ['api-gateway', 'inventory-svc'], type: 'lectura', scope: 'serviceBearer:modulo-ventas:inventario:disponibilidad:leer', authRequirement: 'ventas' },
});
