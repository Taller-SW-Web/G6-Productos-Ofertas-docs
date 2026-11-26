# Correcciones Aplicadas — G6 H5 R2

1. **Separación y carga de Vitest en worktree (`backend/vitest.config.ts`, `backend/vitest.config.e2e.ts`):**
   - Agregado `resolve.alias.vitest` con `realpathSync('node_modules/vitest/package.json')` para evitar doble carga ESM de `vitest` a través de junctions (`TypeError: Cannot read properties of undefined (reading 'config')`), y excluido `**/*.e2e-spec.ts` de `vitest.config.ts`.
   - Resultado: eliminación total de errores de colección (de 101 archivos fallidos a 25 archivos fallidos reales; `service-bus-19-queues.e2e-spec.ts` pasó a `3/3 PASS`).

2. **Topología 19 colas (`backend/tests/h5/service-bus-19-queues.e2e-spec.ts`):**
   - Corregidos imports reales (`catalogDestinations as CATALOG_ROUTING` y `combosServiceBusRoutes`).

3. **Certificador 158 operaciones (`backend/tests/h5/certify-158-endpoints.mjs`):**
   - **C158-01:** Eliminado casteo `::uuid` sobre `inventory.reservations.order_id` (`text`); validados `status` (`CONFIRMADA`/`CONSUMIDA`/`LIBERADA`) e `inventory.inventory_operations`.
   - **C158-03:** Incluidos `evaluarPromociones` (+ validación semántica de DTO), `simularCarritoPromociones`, `calcularDescuento`, `validarCupon`, `consultarDatosFisicos`, `resolverSlugCategoriaCreacion`, `resolverSkusAdministracion`, `prevalidarImportacionPrecios`, `resolverCodigoBarras` en `READ_ONLY_POST_OPS`.
   - **C158-04:** Corte ordenado ante `httpStatus === 0` marcando `BLOCKED_INFRA` y `NOT_RUN` en las restantes.
   - **C158-05:** Añadidas validaciones SQL reales para variantes (`ACTIVA`/`INACTIVA`), cupones (`couponIdDeact` separado para `[48]..[50]`), reglas, taxonomía, precios, umbrales (`eliminarUmbralSku`) y polling terminal para `[109]`.

4. **Protección de `/__test/pg-query` (`frontend/tests/e2e-real/startRealStackAndVite.mjs`):**
   - Envuelto en `try/catch` devolviendo HTTP `400`/`500` JSON controlado sin derribar el stack ante errores SQL.

5. **Conciliación offline (`backend/apps/inventory-svc/src/inventory.controller.ts`):**
   - Pasado `req?.jwtPayload ?? req?.user` a `reconcileFromAuthorizedRequest`, resolviendo el 403 previo (`[128]` pasó a HTTP 200 `COMPLETED`).

6. **Bulk `INVALID_TRANSITION` (`backend/apps/bulk-svc/src/messaging/bulk-service-bus.ts` y `persistence/bulk.repository.ts`):**
   - Revertido el envío ciego a DLQ en `bulk-service-bus.ts`.
   - En `bulk.repository.ts`, resultados tardíos de dominios dependientes cuando la fila ya falló en `CATALOGO` se registran de forma durable en `bulk.inbox` (`SUPERSEDED_BY_CATALOG_FAILURE`) sin bucle infinito.

7. **Runner 19 recorridos (`backend/tests/h5/certify-19-messaging-flows.mjs`):**
   - Arranca `startRealStackAndVite.mjs --no-vite`, usa `gestor@example.test` / `isolated-g7-password` con `formatoAcceso: "JWS"`, soporta `http` y `https` según URL, y captura `stdout`/`stderr` y `exitCode`.
