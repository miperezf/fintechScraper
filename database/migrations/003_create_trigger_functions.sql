-- ============================================================
-- MIGRACIÓN 003: Función de detección de cambios de tasas
-- ============================================================

CREATE OR REPLACE FUNCTION detect_rate_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_previous_rate RECORD;  -- Fila previa de currency_rates para esta moneda/fuente
    v_has_changed   BOOLEAN := FALSE;
BEGIN
    -- --------------------------------------------------------
    -- PASO 1: Buscar la tasa más reciente ANTERIOR a este INSERT
    -- Usamos el índice compuesto creado en 002 para máxima velocidad
    -- --------------------------------------------------------
    SELECT
        buy_rate,
        sell_rate
    INTO v_previous_rate
    FROM currency_rates
    WHERE
        source_id     = NEW.source_id
        AND currency_code = NEW.currency_code
        AND id            != NEW.id          -- excluir el registro recién insertado
    ORDER BY timestamp DESC
    LIMIT 1;

    -- --------------------------------------------------------
    -- PASO 2: Determinar si hubo cambio
    -- Si no existe tasa previa (primer INSERT de esta moneda),
    -- también registramos el evento como "cambio inicial"
    -- --------------------------------------------------------
    IF NOT FOUND THEN
        -- Primera vez que vemos esta moneda para esta fuente
        v_has_changed := TRUE;
    ELSIF
        -- Comparamos con tolerancia de NUMERIC para evitar falsos positivos
        -- por diferencias de punto flotante imperceptibles
        v_previous_rate.buy_rate  IS DISTINCT FROM NEW.buy_rate
        OR v_previous_rate.sell_rate IS DISTINCT FROM NEW.sell_rate
    THEN
        v_has_changed := TRUE;
    END IF;

    -- --------------------------------------------------------
    -- PASO 3: Si hubo cambio, registrar en rate_changes
    -- --------------------------------------------------------
    IF v_has_changed THEN
        INSERT INTO rate_changes (
            rate_id,
            old_buy_rate,
            new_buy_rate,
            old_sell_rate,
            new_sell_rate,
            detected_at
        ) VALUES (
            NEW.id,
            v_previous_rate.buy_rate,   -- NULL si es primera vez (RECORD vacío)
            NEW.buy_rate,
            v_previous_rate.sell_rate,  -- NULL si es primera vez
            NEW.sell_rate,
            NOW()
        );
    END IF;

    -- Los triggers AFTER no modifican la fila, retornamos NULL
    RETURN NULL;

EXCEPTION
    -- --------------------------------------------------------
    -- PASO 4: Manejo de errores — nunca dejar fallar el INSERT
    -- principal por un problema en la detección de cambios
    -- --------------------------------------------------------
    WHEN OTHERS THEN
        -- Registrar el error en el log de PostgreSQL sin propagar
        RAISE WARNING 'detect_rate_change() falló para rate_id=%, error: %', NEW.id, SQLERRM;
        RETURN NULL;
END;
$$;

COMMENT ON FUNCTION detect_rate_change() IS
    'Detecta cambios en buy_rate o sell_rate tras cada INSERT en currency_rates. '
    'Si la tasa cambió respecto a la última lectura, registra el evento en rate_changes.';