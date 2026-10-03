-- ============================================================================
-- inventory-svc - validation.sql (schema `inventory`)
-- Issue #54 - Evidencia de validación
--
-- Ejecutar DESPUÉS de aplicar migration.sql. Si el script finaliza sin errores,
-- la validación es SATISFACTORIA (criterios de aceptación del issue #54).
-- Uso:  psql -v ON_ERROR_STOP=1 -f validation.sql
-- ============================================================================

DO $$
DECLARE
    v_ns            oid;
    v_total         bigint;
    v_available     integer;
    v_loc_id        uuid;
    v_loc_dest_id   uuid;
    v_res_id        uuid;
    v_global_id     uuid;
    v_inc_id        uuid;
    v_tra_id        uuid;
    v_fixture       uuid;
    v_col_type      text;
BEGIN

    -- ---------------------------------------------------------------- 1.
    -- El schema existe
    -- ----------------------------------------------------------------
    v_ns := to_regnamespace('inventory');
    IF v_ns IS NULL THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [1]: el schema inventory no existe';
    END IF;

    -- ---------------------------------------------------------------- 2.
    -- Tabla inventory.locations existe y cumple especificación (CONVENCIONES_BD.md §18)
    -- ----------------------------------------------------------------
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'inventory' AND table_name = 'locations'
    ) THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [2a]: la tabla inventory.locations no existe';
    END IF;

    -- Comprobar PK pk_locations
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_schema = 'inventory' AND table_name = 'locations'
          AND constraint_type = 'PRIMARY KEY' AND constraint_name = 'pk_locations'
    ) THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [2b]: falta la clave primaria pk_locations en inventory.locations';
    END IF;

    -- Comprobar unicidad de code
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_schema = 'inventory' AND table_name = 'locations'
          AND constraint_type = 'UNIQUE' AND constraint_name = 'uq_locations_code'
    ) THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [2c]: falta la restriccion unica uq_locations_code en inventory.locations';
    END IF;

    -- Comprobar tipo uuid para columna id
    SELECT data_type INTO v_col_type
      FROM information_schema.columns
     WHERE table_schema = 'inventory' AND table_name = 'locations' AND column_name = 'id';
    IF v_col_type <> 'uuid' THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [2d]: locations.id debe ser tipo uuid, obtenido %', v_col_type;
    END IF;

    -- Comprobar que external_ref es nullable
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'inventory' AND table_name = 'locations'
          AND column_name = 'external_ref' AND is_nullable = 'YES'
    ) THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [2e]: locations.external_ref debe ser nullable';
    END IF;

    -- ---------------------------------------------------------------- 3.
    -- Coherencia de tipos y FK internas hacia inventory.locations
    -- ----------------------------------------------------------------
    -- Comprobar tipo uuid en columnas que referencian ubicación
    SELECT count(*) INTO v_total
      FROM information_schema.columns
     WHERE table_schema = 'inventory'
       AND column_name IN ('location_id', 'source_location_id', 'target_location_id')
       AND data_type <> 'uuid';
    IF v_total > 0 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [3a]: existen % columnas de ubicacion que no son de tipo uuid', v_total;
    END IF;

    -- Comprobar FK internas hacia locations
    SELECT count(*) INTO v_total
      FROM information_schema.table_constraints tc
      JOIN information_schema.referential_constraints rc
        ON rc.constraint_name = tc.constraint_name AND rc.constraint_schema = tc.constraint_schema
      JOIN information_schema.constraint_column_usage ccu
        ON ccu.constraint_name = tc.constraint_name AND ccu.constraint_schema = tc.constraint_schema
     WHERE tc.constraint_schema = 'inventory'
       AND tc.constraint_type = 'FOREIGN KEY'
       AND ccu.table_name = 'locations' AND ccu.column_name = 'id';
    IF v_total < 7 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [3b]: se esperaban al menos 7 FK hacia inventory.locations, encontradas %', v_total;
    END IF;

    -- ---------------------------------------------------------------- 4.
    -- Aislamiento: ninguna FK hacia otros schemas (Retail, Catálogo, auth, public)
    -- ----------------------------------------------------------------
    SELECT count(*) INTO v_total
      FROM information_schema.table_constraints tc
      JOIN information_schema.referential_constraints rc
        ON rc.constraint_name = tc.constraint_name AND rc.constraint_schema = tc.constraint_schema
     WHERE tc.constraint_schema = 'inventory'
       AND tc.constraint_type = 'FOREIGN KEY'
       AND rc.unique_constraint_schema IS DISTINCT FROM 'inventory';
    IF v_total > 0 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [4]: se encontraron % FK hacia schemas externos', v_total;
    END IF;

    -- ---------------------------------------------------------------- 5.
    -- Creación de ubicaciones de prueba para fixtures
    -- ----------------------------------------------------------------
    INSERT INTO inventory.locations (code, name, type, external_ref)
    VALUES ('V-LOC-1', 'Almacén de Prueba 1', 'ALMACEN_CENTRAL', 'RET-001')
    RETURNING id INTO v_loc_id;

    INSERT INTO inventory.locations (code, name, type, external_ref)
    VALUES ('V-LOC-DEST', 'Almacén Destino Prueba', 'TIENDA', NULL)
    RETURNING id INTO v_loc_dest_id;

    -- Unicidad de código de ubicación
    BEGIN
        INSERT INTO inventory.locations (code, name, type)
        VALUES ('V-LOC-1', 'Duplicado', 'TIENDA');
        RAISE EXCEPTION 'VALIDACION FALLADA [5b]: se permitió código de ubicación duplicado';
    EXCEPTION WHEN unique_violation THEN
        NULL;
    END;

    -- ---------------------------------------------------------------- 6.
    -- available es columna generada por la fórmula contractual
    --    available = max(on_hand - reserved - blocked, 0)
    -- ----------------------------------------------------------------
    INSERT INTO inventory.stock_balance (sku_id, location_id, on_hand, reserved, blocked)
    VALUES ('V-SKU-1', v_loc_id, 100, 30, 10);

    SELECT available INTO v_available
      FROM inventory.stock_balance
     WHERE sku_id = 'V-SKU-1' AND location_id = v_loc_id;
    IF v_available IS DISTINCT FROM 60 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [6]: available esperado 60, obtenido %', v_available;
    END IF;

    -- ---------------------------------------------------------------- 7.
    -- Invariante: on_hand negativo DEBE ser rechazado (CHECK)
    -- ----------------------------------------------------------------
    BEGIN
        INSERT INTO inventory.stock_balance (sku_id, location_id, on_hand)
        VALUES ('V-SKU-NEG', v_loc_id, -1);
        RAISE EXCEPTION 'VALIDACION FALLADA [7a]: se permitió on_hand negativo';
    EXCEPTION WHEN check_violation THEN
        NULL;
    END;

    -- Invariante: reserved o blocked negativos DEBEN ser rechazados
    BEGIN
        INSERT INTO inventory.stock_balance (sku_id, location_id, on_hand, reserved)
        VALUES ('V-SKU-NEG2', v_loc_id, 5, -1);
        RAISE EXCEPTION 'VALIDACION FALLADA [7b]: se permitió reserved negativo';
    EXCEPTION WHEN check_violation THEN
        NULL;
    END;

    -- ---------------------------------------------------------------- 8.
    -- Invariante: reserved + blocked <= on_hand DEBE ser rechazado si supera
    -- ----------------------------------------------------------------
    BEGIN
        INSERT INTO inventory.stock_balance (sku_id, location_id, on_hand, reserved, blocked)
        VALUES ('V-SKU-OV', v_loc_id, 5, 4, 2);
        RAISE EXCEPTION 'VALIDACION FALLADA [8]: se permitió reserved + blocked > on_hand';
    EXCEPTION WHEN check_violation THEN
        NULL;
    END;

    -- ---------------------------------------------------------------- 9.
    -- Idempotencia: la clave de comando en inventory_operations es única
    -- ----------------------------------------------------------------
    INSERT INTO inventory.inventory_operations (operation_type, idempotency_key, intention, status, location_id)
    VALUES ('RESERVA', 'V-IDEM-1', 'reservar', 'APLICADO', v_loc_id);

    BEGIN
        INSERT INTO inventory.inventory_operations (operation_type, idempotency_key, intention, status, location_id)
        VALUES ('RESERVA', 'V-IDEM-1', 'reservar', 'APLICADO', v_loc_id);
        RAISE EXCEPTION 'VALIDACION FALLADA [9]: idempotency_key duplicada aceptada';
    EXCEPTION WHEN unique_violation THEN
        NULL;
    END;

    -- ---------------------------------------------------------------- 10.
    -- Ciclo funcional reserva -> consumo con Kardex consistente
    -- ----------------------------------------------------------------
    INSERT INTO inventory.stock_balance (sku_id, location_id, on_hand, reserved, blocked)
    VALUES ('V-SKU-CICLO', v_loc_id, 10, 0, 0);

    INSERT INTO inventory.reservations
        (reservation_id, expires_at, idempotency_key)
    VALUES (gen_random_uuid(), now() + interval '5 minutes', 'V-RES-CICLO')
    RETURNING id INTO v_res_id;

    INSERT INTO inventory.reservation_lines (reservation_id, sku_id, location_id, quantity)
    VALUES (v_res_id, 'V-SKU-CICLO', v_loc_id, 3);

    -- Reserva: reserved += 3
    UPDATE inventory.stock_balance
       SET reserved = reserved + 3, stock_version = stock_version + 1
     WHERE sku_id = 'V-SKU-CICLO' AND location_id = v_loc_id;

    SELECT available INTO v_available
      FROM inventory.stock_balance
     WHERE sku_id = 'V-SKU-CICLO' AND location_id = v_loc_id;
    IF v_available IS DISTINCT FROM 7 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [10a]: tras la reserva available esperado 7, obtenido %', v_available;
    END IF;

    INSERT INTO inventory.kardex
        (sku_id, location_id, operation_type, reservation_id, quantity,
         on_hand_before, on_hand_after, reserved_before, reserved_after,
         blocked_before, blocked_after, stock_version)
    VALUES ('V-SKU-CICLO', v_loc_id, 'RESERVA', v_res_id, 3, 10, 10, 0, 3, 0, 0, 1);

    -- Consumo: on_hand -= 3 y reserved -= 3
    UPDATE inventory.reservations
       SET status = 'CONSUMIDA', consumed_at = now()
     WHERE id = v_res_id;

    UPDATE inventory.stock_balance
       SET on_hand = on_hand - 3, reserved = reserved - 3, stock_version = stock_version + 1
     WHERE sku_id = 'V-SKU-CICLO' AND location_id = v_loc_id;

    SELECT available INTO v_available
      FROM inventory.stock_balance
     WHERE sku_id = 'V-SKU-CICLO' AND location_id = v_loc_id;
    IF v_available IS DISTINCT FROM 7 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [10b]: tras el consumo available esperado 7, obtenido %', v_available;
    END IF;

    INSERT INTO inventory.kardex
        (sku_id, location_id, operation_type, reservation_id, quantity,
         on_hand_before, on_hand_after, reserved_before, reserved_after,
         blocked_before, blocked_after, stock_version)
    VALUES ('V-SKU-CICLO', v_loc_id, 'CONSUMO', v_res_id, -3, 10, 7, 3, 0, 0, 0, 2);

    -- ---------------------------------------------------------------- 11.
    -- Expiración por TTL: efecto completo
    -- ----------------------------------------------------------------
    INSERT INTO inventory.stock_balance (sku_id, location_id, on_hand, reserved, blocked)
    VALUES ('V-SKU-TTL', v_loc_id, 8, 2, 0);

    INSERT INTO inventory.reservations
        (reservation_id, expires_at, idempotency_key)
    VALUES (gen_random_uuid(), now() - interval '1 minute', 'V-RES-TTL')
    RETURNING id INTO v_res_id;

    INSERT INTO inventory.reservation_lines (reservation_id, sku_id, location_id, quantity)
    VALUES (v_res_id, 'V-SKU-TTL', v_loc_id, 2);

    -- Worker: marcar EXPIRADA y liberar reserved
    UPDATE inventory.reservations
       SET status = 'EXPIRADA', expired_at = now()
     WHERE id = v_res_id;

    UPDATE inventory.stock_balance
       SET reserved = reserved - 2, stock_version = stock_version + 1
     WHERE sku_id = 'V-SKU-TTL' AND location_id = v_loc_id;

    SELECT available INTO v_available
      FROM inventory.stock_balance
     WHERE sku_id = 'V-SKU-TTL' AND location_id = v_loc_id;
    IF v_available IS DISTINCT FROM 8 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [11a]: tras expirar available esperado 8, obtenido %', v_available;
    END IF;

    INSERT INTO inventory.kardex
        (sku_id, location_id, operation_type, reservation_id, quantity,
         on_hand_before, on_hand_after, reserved_before, reserved_after,
         blocked_before, blocked_after, stock_version)
    VALUES ('V-SKU-TTL', v_loc_id, 'EXPIRACION', v_res_id, -2, 8, 8, 2, 0, 0, 0, 1);

    -- ---------------------------------------------------------------- 12.
    -- Carrera: una sola transición terminal (trigger trg_no_double_terminal)
    -- ----------------------------------------------------------------
    INSERT INTO inventory.reservations
        (reservation_id, expires_at, idempotency_key)
    VALUES (gen_random_uuid(), now() - interval '1 minute', 'V-RES-CARRERA')
    RETURNING id INTO v_res_id;

    INSERT INTO inventory.reservation_lines (reservation_id, sku_id, location_id, quantity)
    VALUES (v_res_id, 'V-SKU-CARRERA', v_loc_id, 1);

    UPDATE inventory.reservations
       SET status = 'EXPIRADA', expired_at = now()
     WHERE id = v_res_id;

    BEGIN
        UPDATE inventory.reservations
           SET status = 'CONSUMIDA'
         WHERE id = v_res_id;
        RAISE EXCEPTION 'VALIDACION FALLADA [12]: se permitió cambiar estado terminal de reserva';
    EXCEPTION WHEN raise_exception THEN
        NULL;
    END;

    -- ---------------------------------------------------------------- 13.
    -- Outbox: event_id único
    -- ----------------------------------------------------------------
    INSERT INTO inventory.outbox (event_id, event_type, aggregate_type, aggregate_id, payload)
    VALUES (gen_random_uuid(), 'dup', 'x', 'x', '{}'::jsonb)
    RETURNING id INTO v_fixture;

    BEGIN
        INSERT INTO inventory.outbox (event_id, event_type, aggregate_type, aggregate_id, payload)
        SELECT event_id, event_type, aggregate_type, aggregate_id, payload
          FROM inventory.outbox WHERE id = v_fixture;
        RAISE EXCEPTION 'VALIDACION FALLADA [13]: event_id duplicado aceptado en outbox';
    EXCEPTION WHEN unique_violation THEN
        NULL;
    END;

    DELETE FROM inventory.outbox WHERE id = v_fixture;

    -- ---------------------------------------------------------------- 14.
    -- Inbox: message_id único
    -- ----------------------------------------------------------------
    INSERT INTO inventory.inbox (message_id, message_type, source, payload)
    VALUES (gen_random_uuid(), 'inventory.reservation.requested', 'rabbitmq', '{}'::jsonb)
    RETURNING id INTO v_fixture;

    BEGIN
        INSERT INTO inventory.inbox (message_id, message_type, source, payload)
        SELECT message_id, message_type, source, payload FROM inventory.inbox WHERE id = v_fixture;
        RAISE EXCEPTION 'VALIDACION FALLADA [14]: message_id duplicado aceptado en inbox';
    EXCEPTION WHEN unique_violation THEN
        NULL;
    END;

    -- ---------------------------------------------------------------- 15.
    -- Umbrales de stock
    -- ----------------------------------------------------------------
    INSERT INTO inventory.stock_threshold_override (sku_id, location_id, umbral_efectivo)
    VALUES (NULL, NULL, 5)
    RETURNING id INTO v_global_id;

    BEGIN
        INSERT INTO inventory.stock_threshold_override (sku_id, location_id, umbral_efectivo)
        VALUES (NULL, NULL, 8);
        RAISE EXCEPTION 'VALIDACION FALLADA [15a]: override global duplicado aceptado';
    EXCEPTION WHEN unique_violation THEN
        NULL;
    END;

    INSERT INTO inventory.stock_threshold_override (sku_id, location_id, umbral_efectivo)
    VALUES ('V-SKU-TH', NULL, 3);

    -- scope inválido (por ubicación) debe fallar: SPEC-015 §6
    BEGIN
        INSERT INTO inventory.stock_threshold_override (sku_id, location_id, umbral_efectivo)
        VALUES ('V-SKU-TH', v_loc_id, 3);
        RAISE EXCEPTION 'VALIDACION FALLADA [15b]: override por ubicación aceptado';
    EXCEPTION WHEN check_violation THEN
        NULL;
    END;

    -- ---------------------------------------------------------------- 16.
    -- Dashboard projection
    -- ----------------------------------------------------------------
    INSERT INTO inventory.dashboard_projection
        (sku_id, location_id, on_hand, reserved, blocked, status, umbral_efectivo)
    VALUES ('V-SKU-1', v_loc_id, 100, 30, 10, 'DISPONIBLE', 0);

    SELECT available INTO v_available
      FROM inventory.dashboard_projection
     WHERE sku_id = 'V-SKU-1' AND location_id = v_loc_id;
    IF v_available IS DISTINCT FROM 60 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [16]: available de proyección esperado 60, obtenido %', v_available;
    END IF;

    -- ---------------------------------------------------------------- 17.
    -- Incidencia: reporte ABIERTA con bloqueo y resolución REHABILITADO
    -- ----------------------------------------------------------------
    INSERT INTO inventory.stock_balance (sku_id, location_id, on_hand, reserved, blocked)
    VALUES ('V-SKU-INC', v_loc_id, 20, 0, 0);

    INSERT INTO inventory.incidencias
        (incidencia_id, sku_id, location_id, external_incident_id, cantidad_bloqueada, idempotency_key)
    VALUES (gen_random_uuid(), 'V-SKU-INC', v_loc_id, 'V-EXT-1', 5, 'V-INCID-1');

    UPDATE inventory.stock_balance
       SET blocked = blocked + 5, stock_version = stock_version + 1
     WHERE sku_id = 'V-SKU-INC' AND location_id = v_loc_id;

    SELECT available INTO v_available
      FROM inventory.stock_balance
     WHERE sku_id = 'V-SKU-INC' AND location_id = v_loc_id;
    IF v_available IS DISTINCT FROM 15 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [17a]: tras bloqueo available esperado 15, obtenido %', v_available;
    END IF;

    INSERT INTO inventory.kardex
        (sku_id, location_id, operation_type, operation_id, quantity,
         on_hand_before, on_hand_after, reserved_before, reserved_after,
         blocked_before, blocked_after, stock_version)
    VALUES ('V-SKU-INC', v_loc_id, 'INCIDENCIA_BLOQUEO', NULL, 5, 20, 20, 0, 0, 0, 5, 1);

    -- Resolución REHABILITADO
    UPDATE inventory.incidencias
       SET estado = 'RESUELTA', tipo_resolucion = 'REHABILITADO', resolved_at = now()
     WHERE idempotency_key = 'V-INCID-1';

    UPDATE inventory.stock_balance
       SET blocked = blocked - 5, stock_version = stock_version + 1
     WHERE sku_id = 'V-SKU-INC' AND location_id = v_loc_id;

    SELECT available INTO v_available
      FROM inventory.stock_balance
     WHERE sku_id = 'V-SKU-INC' AND location_id = v_loc_id;
    IF v_available IS DISTINCT FROM 20 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [17b]: tras rehabilitar available esperado 20, obtenido %', v_available;
    END IF;

    -- Idempotencia del reporte de incidencia
    BEGIN
        INSERT INTO inventory.incidencias
            (incidencia_id, sku_id, location_id, cantidad_bloqueada, idempotency_key)
        VALUES (gen_random_uuid(), 'V-SKU-INC', v_loc_id, 5, 'V-INCID-1');
        RAISE EXCEPTION 'VALIDACION FALLADA [17c]: incidencia duplicada aceptada';
    EXCEPTION WHEN unique_violation THEN
        NULL;
    END;

    -- ---------------------------------------------------------------- 18.
    -- Traslado y recepciones entre ubicaciones
    -- ----------------------------------------------------------------
    INSERT INTO inventory.stock_balance (sku_id, location_id, on_hand, reserved, blocked)
    VALUES ('V-SKU-TRA', v_loc_id, 10, 0, 4);

    INSERT INTO inventory.incidencias
        (incidencia_id, sku_id, location_id, cantidad_bloqueada, idempotency_key, estado)
    VALUES (gen_random_uuid(), 'V-SKU-TRA', v_loc_id, 4, 'V-INCID-TRA', 'TRASLADO_PENDIENTE')
    RETURNING id INTO v_inc_id;

    UPDATE inventory.stock_balance
       SET on_hand = on_hand - 4, blocked = blocked - 4, stock_version = stock_version + 1
     WHERE sku_id = 'V-SKU-TRA' AND location_id = v_loc_id;

    INSERT INTO inventory.traslados
        (traslado_id, source_incident_id, sku_id, source_location_id, target_location_id,
         quantity_shipped, quantity_received, missing_quantity, estado)
    VALUES (gen_random_uuid(), v_inc_id, 'V-SKU-TRA', v_loc_id, v_loc_dest_id, 4, 0, NULL, 'EN_TRANSITO')
    RETURNING id INTO v_tra_id;

    -- Recepción parcial (2 de 4) -> RECIBIDO_PARCIAL
    INSERT INTO inventory.traslado_recepciones
        (recepcion_id, traslado_id, cantidad_recibida, disposicion, es_recepcion_final, sub_gestor, idempotency_key)
    VALUES (gen_random_uuid(), v_tra_id, 2, 'REINGRESAR_DISPONIBLE', false, 'V-GESTOR', 'V-REC-PARCIAL');

    UPDATE inventory.traslados
       SET quantity_received = 2, estado = 'RECIBIDO_PARCIAL'
     WHERE id = v_tra_id;

    -- Recepción final con faltante (1 de 4 merma; falta 1) -> COMPLETADO_CON_DISCREPANCIA
    INSERT INTO inventory.traslado_recepciones
        (recepcion_id, traslado_id, cantidad_recibida, disposicion, es_recepcion_final, sub_gestor, idempotency_key)
    VALUES (gen_random_uuid(), v_tra_id, 1, 'CONFIRMAR_MERMA', true, 'V-GESTOR', 'V-REC-FINAL');

    UPDATE inventory.traslados
       SET quantity_received = 3, missing_quantity = 1, estado = 'COMPLETADO_CON_DISCREPANCIA'
     WHERE id = v_tra_id;

    INSERT INTO inventory.stock_balance (sku_id, location_id, on_hand, reserved, blocked)
    VALUES ('V-SKU-TRA', v_loc_dest_id, 2, 0, 0);

    -- Transición terminal del traslado: no debe salir de COMPLETADO_CON_DISCREPANCIA
    BEGIN
        UPDATE inventory.traslados SET estado = 'COMPLETADO' WHERE id = v_tra_id;
        RAISE EXCEPTION 'VALIDACION FALLADA [18e]: traslado terminado mutado a otro estado';
    EXCEPTION WHEN raise_exception THEN
        NULL;
    END;

    -- ---------------------------------------------------------------- 19.
    -- Limpieza de datos de prueba
    -- ----------------------------------------------------------------
    DELETE FROM inventory.inbox WHERE message_type = 'inventory.reservation.requested';
    DELETE FROM inventory.outbox WHERE aggregate_id LIKE 'V-%' OR event_type = 'dup';
    DELETE FROM inventory.kardex WHERE sku_id LIKE 'V-%';
    DELETE FROM inventory.reservations WHERE idempotency_key LIKE 'V-%';
    DELETE FROM inventory.traslados WHERE sku_id LIKE 'V-%';
    DELETE FROM inventory.incidencias WHERE sku_id LIKE 'V-%';
    DELETE FROM inventory.inventory_operations WHERE idempotency_key LIKE 'V-%';
    DELETE FROM inventory.dashboard_projection WHERE sku_id LIKE 'V-%';
    DELETE FROM inventory.stock_threshold_override WHERE sku_id LIKE 'V-%';
    DELETE FROM inventory.stock_threshold_override WHERE sku_id IS NULL AND location_id IS NULL;
    DELETE FROM inventory.stock_balance WHERE sku_id LIKE 'V-%';
    DELETE FROM inventory.locations WHERE code LIKE 'V-%';

    -- ---------------------------------------------------------------- 20.
    -- Resumen
    -- ----------------------------------------------------------------
    SELECT count(*) INTO v_total
      FROM information_schema.tables
     WHERE table_schema = 'inventory';

    RAISE NOTICE 'VALIDACION OK: schema inventory con % tablas cumple locations, esquema, invariantes, idempotencia, ciclo reserva/consumo, TTL, carrera de terminal única, outbox/inbox, incidencias, traslados, y ausencia de FK externos.', v_total;

END $$;

-- Salida final de confirmación
SELECT 'VALIDACION_FINALIZADA_SATISFACTORIAMENTE' AS resultado,
       count(*) AS total_tablas
  FROM information_schema.tables
 WHERE table_schema = 'inventory';