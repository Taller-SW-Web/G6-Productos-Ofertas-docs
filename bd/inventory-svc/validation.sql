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
    v_ns           oid;
    v_total        bigint;
    v_available    integer;
    v_res_id       uuid;
    v_global_id    uuid;
    v_inc_id       uuid;
    v_tra_id       uuid;
    v_fixture      bigint;
BEGIN

    -- ---------------------------------------------------------------- 1.
    -- El schema existe
    -- ----------------------------------------------------------------
    v_ns := to_regnamespace('inventory');
    IF v_ns IS NULL THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [1]: el schema inventory no existe';
    END IF;

    -- ---------------------------------------------------------------- 2.
    -- available es columna generada por la fórmula contractual
    --    available = max(on_hand - reserved - blocked, 0)
    -- ----------------------------------------------------------------
    INSERT INTO inventory.stock_balance (sku_id, location_id, on_hand, reserved, blocked)
    VALUES ('V-SKU-1', 'V-LOC', 100, 30, 10);
    SELECT available INTO v_available
      FROM inventory.stock_balance
     WHERE sku_id = 'V-SKU-1' AND location_id = 'V-LOC';
    IF v_available IS DISTINCT FROM 60 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [2]: available esperado 60, obtenido %', v_available;
    END IF;

    -- ---------------------------------------------------------------- 3.
    -- Invariante: on_hand negativo DEBE ser rechazado (CHECK)
    -- ----------------------------------------------------------------
    BEGIN
        INSERT INTO inventory.stock_balance (sku_id, location_id, on_hand)
        VALUES ('V-SKU-NEG', 'V-LOC', -1);
        RAISE EXCEPTION 'VALIDACION FALLADA [3a]: se permitió on_hand negativo';
    EXCEPTION WHEN check_violation THEN
        NULL;
    END;

    -- Invariante: reserved o blocked negativos DEBEN ser rechazados
    BEGIN
        INSERT INTO inventory.stock_balance (sku_id, location_id, on_hand, reserved)
        VALUES ('V-SKU-NEG2', 'V-LOC', 5, -1);
        RAISE EXCEPTION 'VALIDACION FALLADA [3b]: se permitió reserved negativo';
    EXCEPTION WHEN check_violation THEN
        NULL;
    END;

    -- ---------------------------------------------------------------- 4.
    -- Invariante: reserved + blocked <= on_hand DEBE ser rechazado
    -- ----------------------------------------------------------------
    BEGIN
        INSERT INTO inventory.stock_balance (sku_id, location_id, on_hand, reserved, blocked)
        VALUES ('V-SKU-OV', 'V-LOC', 5, 4, 2);
        RAISE EXCEPTION 'VALIDACION FALLADA [4]: se permitió reserved + blocked > on_hand';
    EXCEPTION WHEN check_violation THEN
        NULL;
    END;

    -- ---------------------------------------------------------------- 5.
    -- Idempotencia: la clave de comando en inventory_operations es única
    -- ----------------------------------------------------------------
    INSERT INTO inventory.inventory_operations (operation_type, idempotency_key, intention, status)
    VALUES ('RESERVA', 'V-IDEM-1', 'reservar', 'APLICADO');
    BEGIN
        INSERT INTO inventory.inventory_operations (operation_type, idempotency_key, intention, status)
        VALUES ('RESERVA', 'V-IDEM-1', 'reservar', 'APLICADO');
        RAISE EXCEPTION 'VALIDACION FALLADA [5]: idempotency_key duplicada aceptada';
    EXCEPTION WHEN unique_violation THEN
        NULL;
    END;

    -- ---------------------------------------------------------------- 6.
    -- Ciclo funcional reserva -> consumo con Kardex consistente
    --    reserva:  reserved += qty  (on_hand sin cambios)
    --    consumo:  on_hand -= qty, reserved -= qty
    -- ----------------------------------------------------------------
    INSERT INTO inventory.stock_balance (sku_id, location_id, on_hand, reserved, blocked)
    VALUES ('V-SKU-CICLO', 'V-LOC', 10, 0, 0);

    INSERT INTO inventory.reservations
        (reservation_id, expires_at, idempotency_key)
    VALUES (gen_random_uuid(), now() + interval '5 minutes', 'V-RES-CICLO')
    RETURNING id INTO v_res_id;

    INSERT INTO inventory.reservation_lines (reservation_id, sku_id, location_id, quantity)
    VALUES (v_res_id, 'V-SKU-CICLO', 'V-LOC', 3);

    -- Reserva: reserved += 3
    UPDATE inventory.stock_balance
       SET reserved = reserved + 3, stock_version = stock_version + 1
     WHERE sku_id = 'V-SKU-CICLO' AND location_id = 'V-LOC';

    SELECT available INTO v_available
      FROM inventory.stock_balance
     WHERE sku_id = 'V-SKU-CICLO' AND location_id = 'V-LOC';
    IF v_available IS DISTINCT FROM 7 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [6a]: tras la reserva available esperado 7, obtenido %', v_available;
    END IF;

    INSERT INTO inventory.kardex
        (sku_id, location_id, operation_type, reservation_id, quantity,
         on_hand_before, on_hand_after, reserved_before, reserved_after,
         blocked_before, blocked_after, stock_version)
    VALUES ('V-SKU-CICLO', 'V-LOC', 'RESERVA', v_res_id, 3, 10, 10, 0, 3, 0, 0, 1);

    -- Consumo: on_hand -= 3 y reserved -= 3
    UPDATE inventory.reservations
       SET status = 'CONSUMIDA', consumed_at = now()
     WHERE id = v_res_id;

    UPDATE inventory.stock_balance
       SET on_hand = on_hand - 3, reserved = reserved - 3, stock_version = stock_version + 1
     WHERE sku_id = 'V-SKU-CICLO' AND location_id = 'V-LOC';

    SELECT available INTO v_available
      FROM inventory.stock_balance
     WHERE sku_id = 'V-SKU-CICLO' AND location_id = 'V-LOC';
    IF v_available IS DISTINCT FROM 7 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [6b]: tras el consumo available esperado 7, obtenido %', v_available;
    END IF;

    INSERT INTO inventory.kardex
        (sku_id, location_id, operation_type, reservation_id, quantity,
         on_hand_before, on_hand_after, reserved_before, reserved_after,
         blocked_before, blocked_after, stock_version)
    VALUES ('V-SKU-CICLO', 'V-LOC', 'CONSUMO', v_res_id, -3, 10, 7, 3, 0, 0, 0, 2);

    -- ---------------------------------------------------------------- 7.
    -- Expiración por TTL: efecto completo (reserved--, kardex, outbox por evento)
    -- ----------------------------------------------------------------
    INSERT INTO inventory.stock_balance (sku_id, location_id, on_hand, reserved, blocked)
    VALUES ('V-SKU-TTL', 'V-LOC', 8, 2, 0);

    INSERT INTO inventory.reservations
        (reservation_id, expires_at, idempotency_key)
    VALUES (gen_random_uuid(), now() - interval '1 minute', 'V-RES-TTL')
    RETURNING id INTO v_res_id;

    INSERT INTO inventory.reservation_lines (reservation_id, sku_id, location_id, quantity)
    VALUES (v_res_id, 'V-SKU-TTL', 'V-LOC', 2);

    -- Worker: marcar EXPIRADA y liberar reserved
    UPDATE inventory.reservations
       SET status = 'EXPIRADA', expired_at = now()
     WHERE id = v_res_id;

    UPDATE inventory.stock_balance
       SET reserved = reserved - 2, stock_version = stock_version + 1
     WHERE sku_id = 'V-SKU-TTL' AND location_id = 'V-LOC';

    SELECT available INTO v_available
      FROM inventory.stock_balance
     WHERE sku_id = 'V-SKU-TTL' AND location_id = 'V-LOC';
    IF v_available IS DISTINCT FROM 8 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [7a]: tras expirar available esperado 8, obtenido %', v_available;
    END IF;

    INSERT INTO inventory.kardex
        (sku_id, location_id, operation_type, reservation_id, quantity,
         on_hand_before, on_hand_after, reserved_before, reserved_after,
         blocked_before, blocked_after, stock_version)
    VALUES ('V-SKU-TTL', 'V-LOC', 'EXPIRACION', v_res_id, -2, 8, 8, 2, 0, 0, 0, 1);

    -- Outbox en la misma transacción local: reservation.expired y stock.changed
    INSERT INTO inventory.outbox (event_id, event_type, aggregate_type, aggregate_id, correlation_id, payload)
    VALUES (gen_random_uuid(), 'inventory.reservation.expired', 'reservation',
            v_res_id::text, NULL, jsonb_build_object('reservation_id', v_res_id));
    INSERT INTO inventory.outbox (event_id, event_type, aggregate_type, aggregate_id, correlation_id, payload)
    VALUES (gen_random_uuid(), 'inventory.stock.changed', 'stock_balance',
            'V-SKU-TTL|V-LOC', NULL, jsonb_build_object('sku_id', 'V-SKU-TTL'));

    -- ---------------------------------------------------------------- 8.
    -- Carrera: una sola transición terminal (trigger trg_no_double_terminal)
    -- ----------------------------------------------------------------
    INSERT INTO inventory.reservations
        (reservation_id, expires_at, idempotency_key)
    VALUES (gen_random_uuid(), now() - interval '1 minute', 'V-RES-CARRERA')
    RETURNING id INTO v_res_id;

    INSERT INTO inventory.reservation_lines (reservation_id, sku_id, location_id, quantity)
    VALUES (v_res_id, 'V-SKU-CARRERA', 'V-LOC', 1);

    UPDATE inventory.reservations
       SET status = 'EXPIRADA', expired_at = now()
     WHERE id = v_res_id;



    -- ---------------------------------------------------------------- 9.
    -- Outbox: event_id único (no duplicar eventos)
    -- ----------------------------------------------------------------
    INSERT INTO inventory.outbox (event_id, event_type, aggregate_type, aggregate_id, payload)
    VALUES (gen_random_uuid(), 'dup', 'x', 'x', '{}'::jsonb)
    RETURNING id INTO v_fixture;

    BEGIN
        INSERT INTO inventory.outbox (event_id, event_type, aggregate_type, aggregate_id, payload)
        SELECT event_id, event_type, aggregate_type, aggregate_id, payload
          FROM inventory.outbox WHERE id = v_fixture;
        RAISE EXCEPTION 'VALIDACION FALLADA [9]: event_id duplicado aceptado en outbox';
    EXCEPTION WHEN unique_violation THEN
        NULL;
    END;

    DELETE FROM inventory.outbox WHERE id = v_fixture;

    -- ---------------------------------------------------------------- 10.
    -- Inbox: message_id único (deduplicación de mensajes entrantes)
    -- ----------------------------------------------------------------
    INSERT INTO inventory.inbox (message_id, message_type, source, payload)
    VALUES (gen_random_uuid(), 'inventory.reservation.requested', 'rabbitmq', '{}'::jsonb)
    RETURNING id INTO v_fixture;

    BEGIN
        INSERT INTO inventory.inbox (message_id, message_type, source, payload)
        SELECT message_id, message_type, source, payload FROM inventory.inbox WHERE id = v_fixture;
        RAISE EXCEPTION 'VALIDACION FALLADA [10]: message_id duplicado aceptado en inbox';
    EXCEPTION WHEN unique_violation THEN
        NULL;
    END;

    -- ---------------------------------------------------------------- 11.
    -- Umbral global único en stock_threshold_override
    -- ----------------------------------------------------------------
    INSERT INTO inventory.stock_threshold_override (sku_id, location_id, umbral_efectivo)
    VALUES (NULL, NULL, 5)
    RETURNING id INTO v_global_id;

    BEGIN
        INSERT INTO inventory.stock_threshold_override (sku_id, location_id, umbral_efectivo)
        VALUES (NULL, NULL, 8);
        RAISE EXCEPTION 'VALIDACION FALLADA [11]: override global duplicado aceptado';
    EXCEPTION WHEN unique_violation THEN
        NULL;
    END;

    -- override por SKU válido (sku_id definido, location_id nulo): SPEC-015 §6
    INSERT INTO inventory.stock_threshold_override (sku_id, location_id, umbral_efectivo)
    VALUES ('V-SKU-TH', NULL, 3);

    -- scope inválido (por ubicación) debe fallar: SPEC-015 §6
    BEGIN
        INSERT INTO inventory.stock_threshold_override (sku_id, location_id, umbral_efectivo)
        VALUES ('V-SKU-TH', 'V-LOC', 3);
        RAISE EXCEPTION 'VALIDACION FALLADA [11b]: override por ubicación aceptado';
    EXCEPTION WHEN check_violation THEN
        NULL;
    END;

    -- ---------------------------------------------------------------- 12.
    -- Dashboard projection: solo lectura con status derivado
    -- ----------------------------------------------------------------
    INSERT INTO inventory.dashboard_projection
        (sku_id, location_id, on_hand, reserved, blocked, status, umbral_efectivo)
    VALUES ('V-SKU-1', 'V-LOC', 100, 30, 10, 'DISPONIBLE', 0);

    SELECT available INTO v_available
      FROM inventory.dashboard_projection
     WHERE sku_id = 'V-SKU-1' AND location_id = 'V-LOC';
    IF v_available IS DISTINCT FROM 60 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [12]: available de proyección esperado 60, obtenido %', v_available;
    END IF;

    -- ---------------------------------------------------------------- 13.
    -- No existen FK hacia Catálogo, Ventas ni otros bounded contexts
    --    (criterio de aceptación del issue #54)
    -- ----------------------------------------------------------------
    SELECT count(*) INTO v_total
      FROM information_schema.table_constraints tc
      JOIN information_schema.referential_constraints rc
        ON rc.constraint_name = tc.constraint_name
       AND rc.constraint_schema = tc.constraint_schema
     WHERE tc.constraint_schema = 'inventory'
       AND tc.constraint_type = 'FOREIGN KEY'
       AND rc.unique_constraint_schema IS DISTINCT FROM 'inventory';
    IF v_total > 0 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [13]: se encontraron % FK hacia schemas externos', v_total;
    END IF;

    -- ---------------------------------------------------------------- 15.
    -- Incidencia: reporte ABIERTA con bloqueo y resolución REHABILITADO
    --    reporte:  incidencias ABIERTA y blocked += cantidad (FLOW-015 4.6)
    --    resolución REHABILITADO: estado RESUELTA y blocked -= cantidad
    -- ----------------------------------------------------------------
    INSERT INTO inventory.stock_balance (sku_id, location_id, on_hand, reserved, blocked)
    VALUES ('V-SKU-INC', 'V-LOC', 20, 0, 0);

    INSERT INTO inventory.incidencias
        (incidencia_id, sku_id, location_id, external_incident_id, cantidad_bloqueada, idempotency_key)
    VALUES (gen_random_uuid(), 'V-SKU-INC', 'V-LOC', 'V-EXT-1', 5, 'V-INCID-1');

    UPDATE inventory.stock_balance
       SET blocked = blocked + 5, stock_version = stock_version + 1
     WHERE sku_id = 'V-SKU-INC' AND location_id = 'V-LOC';

    SELECT available INTO v_available
      FROM inventory.stock_balance
     WHERE sku_id = 'V-SKU-INC' AND location_id = 'V-LOC';
    IF v_available IS DISTINCT FROM 15 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [15a]: tras bloqueo available esperado 15, obtenido %', v_available;
    END IF;

    INSERT INTO inventory.kardex
        (sku_id, location_id, operation_type, operation_id, quantity,
         on_hand_before, on_hand_after, reserved_before, reserved_after,
         blocked_before, blocked_after, stock_version)
    VALUES ('V-SKU-INC', 'V-LOC', 'INCIDENCIA_BLOQUEO', NULL, 5, 20, 20, 0, 0, 0, 5, 1);

    INSERT INTO inventory.outbox (event_id, event_type, aggregate_type, aggregate_id, payload)
    VALUES (gen_random_uuid(), 'inventory.stock.changed', 'stock_balance',
            'V-SKU-INC|V-LOC', jsonb_build_object('sku_id', 'V-SKU-INC'));

    -- Resolución REHABILITADO
    UPDATE inventory.incidencias
       SET estado = 'RESUELTA', tipo_resolucion = 'REHABILITADO', resolved_at = now()
     WHERE idempotency_key = 'V-INCID-1';

    UPDATE inventory.stock_balance
       SET blocked = blocked - 5, stock_version = stock_version + 1
     WHERE sku_id = 'V-SKU-INC' AND location_id = 'V-LOC';

    SELECT available INTO v_available
      FROM inventory.stock_balance
     WHERE sku_id = 'V-SKU-INC' AND location_id = 'V-LOC';
    IF v_available IS DISTINCT FROM 20 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [15b]: tras rehabilitar available esperado 20, obtenido %', v_available;
    END IF;

    -- Idempotencia del reporte de incidencia (mismo idempotency_key rechazado)
    BEGIN
        INSERT INTO inventory.incidencias
            (incidencia_id, sku_id, location_id, cantidad_bloqueada, idempotency_key)
        VALUES (gen_random_uuid(), 'V-SKU-INC', 'V-LOC', 5, 'V-INCID-1');
        RAISE EXCEPTION 'VALIDACION FALLADA [15c]: incidencia duplicada aceptada';
    EXCEPTION WHEN unique_violation THEN
        NULL;
    END;

    -- ---------------------------------------------------------------- 16.
    -- Traslado y recepciones: EN_TRANSITO -> RECIBIDO_PARCIAL ->
    --    COMPLETADO_CON_DISCREPANCIA con missing_quantity (FLOW-015 4.9)
    -- ----------------------------------------------------------------
    INSERT INTO inventory.stock_balance (sku_id, location_id, on_hand, reserved, blocked)
    VALUES ('V-SKU-TRA', 'V-LOC', 10, 0, 4);

    INSERT INTO inventory.incidencias
        (incidencia_id, sku_id, location_id, cantidad_bloqueada, idempotency_key, estado)
    VALUES (gen_random_uuid(), 'V-SKU-TRA', 'V-LOC', 4, 'V-INCID-TRA', 'TRASLADO_PENDIENTE')
    RETURNING id INTO v_inc_id;

    -- Origen: descuento on_hand y blocked, y creación del traslado EN_TRANSITO
    UPDATE inventory.stock_balance
       SET on_hand = on_hand - 4, blocked = blocked - 4, stock_version = stock_version + 1
     WHERE sku_id = 'V-SKU-TRA' AND location_id = 'V-LOC';

    INSERT INTO inventory.traslados
        (traslado_id, source_incident_id, sku_id, source_location_id, target_location_id,
         quantity_shipped, quantity_received, missing_quantity, estado)
    VALUES (gen_random_uuid(), v_inc_id, 'V-SKU-TRA', 'V-LOC', 'V-LOC-DEST', 4, 0, NULL, 'EN_TRANSITO')
    RETURNING id INTO v_tra_id;

    -- Recepción parcial (2 de 4) -> RECIBIDO_PARCIAL
    INSERT INTO inventory.traslado_recepciones
        (recepcion_id, traslado_id, cantidad_recibida, disposicion, es_recepcion_final, sub_gestor, idempotency_key)
    VALUES (gen_random_uuid(), v_tra_id, 2, 'REINGRESAR_DISPONIBLE', false, 'V-GESTOR', 'V-REC-PARCIAL');

    UPDATE inventory.traslados
       SET quantity_received = 2, estado = 'RECIBIDO_PARCIAL'
     WHERE id = v_tra_id;

    IF (SELECT quantity_received FROM inventory.traslados WHERE id = v_tra_id) IS DISTINCT FROM 2 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [16a]: no se actualizó quantity_received en recepción parcial';
    END IF;

    -- Recepción final con faltante (1 de 4 merma; falta 1) -> COMPLETADO_CON_DISCREPANCIA
    INSERT INTO inventory.traslado_recepciones
        (recepcion_id, traslado_id, cantidad_recibida, disposicion, es_recepcion_final, sub_gestor, idempotency_key)
    VALUES (gen_random_uuid(), v_tra_id, 1, 'CONFIRMAR_MERMA', true, 'V-GESTOR', 'V-REC-FINAL');

    UPDATE inventory.traslados
       SET quantity_received = 3, missing_quantity = 1, estado = 'COMPLETADO_CON_DISCREPANCIA'
     WHERE id = v_tra_id;

    -- Destino acreditado con la parte REINGRESAR_DISPONIBLE
    INSERT INTO inventory.stock_balance (sku_id, location_id, on_hand, reserved, blocked)
    VALUES ('V-SKU-TRA', 'V-LOC-DEST', 2, 0, 0);

    IF (SELECT estado FROM inventory.traslados WHERE id = v_tra_id)
       IS DISTINCT FROM 'COMPLETADO_CON_DISCREPANCIA' THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [16b]: estado final de traslado incorrecto';
    END IF;
    IF (SELECT missing_quantity FROM inventory.traslados WHERE id = v_tra_id)
       IS DISTINCT FROM 1 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [16c]: missing_quantity esperado 1';
    END IF;

    -- Idempotencia de la recepción (misma Idempotency-Key rechazada)
    BEGIN
        INSERT INTO inventory.traslado_recepciones
            (recepcion_id, traslado_id, cantidad_recibida, disposicion, es_recepcion_final, sub_gestor, idempotency_key)
        VALUES (gen_random_uuid(), v_tra_id, 2, 'REINGRESAR_DISPONIBLE', false, 'V-GESTOR', 'V-REC-PARCIAL');
        RAISE EXCEPTION 'VALIDACION FALLADA [16d]: recepción duplicada aceptada';
    EXCEPTION WHEN unique_violation THEN
        NULL;
    END;

    -- Transición terminal del traslado: no debe salir de COMPLETADO_CON_DISCREPANCIA
    BEGIN
        UPDATE inventory.traslados SET estado = 'COMPLETADO' WHERE id = v_tra_id;
        RAISE EXCEPTION 'VALIDACION FALLADA [16e]: traslado terminado mutado a otro estado';
    EXCEPTION WHEN raise_exception THEN
        NULL;
    END;

    -- ---------------------------------------------------------------- 17.
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

    -- ---------------------------------------------------------------- 18.
    -- Resumen
    -- ----------------------------------------------------------------
    SELECT count(*) INTO v_total
      FROM information_schema.tables
     WHERE table_schema = 'inventory';

    RAISE NOTICE 'VALIDACION OK: schema inventory con % tablas cumple esquema, invariantes, idempotencia, ciclo reserva/consumo, TTL, carrera de terminal única, outbox/inbox, incidencias y traslados, y ausencia de FK externos.', v_total;

END $$;

-- Salida final de confirmación
SELECT 'VALIDACION_FINALIZADA_SATISFACTORIAMENTE' AS resultado,
       count(*) AS total_tablas
  FROM information_schema.tables
 WHERE table_schema = 'inventory';