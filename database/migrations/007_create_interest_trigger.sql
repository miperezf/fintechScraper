-- ============================================================
-- MIGRACIÓN: Paso 2 de 4
-- Trigger de detección de cambios en interest_rates
-- ============================================================

CREATE OR REPLACE FUNCTION detect_interest_rate_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_previous_rate NUMERIC(8, 4);
    v_has_changed   BOOLEAN := FALSE;
BEGIN
    -- --------------------------------------------------------
    -- PASO 1: Buscar la lectura más reciente ANTERIOR
    -- para este mismo producto
    -- --------------------------------------------------------
    SELECT rate
    INTO v_previous_rate
    FROM interest_rates
    WHERE
        product_id = NEW.product_id
        AND id     != NEW.id
    ORDER BY scraped_at DESC
    LIMIT 1;

    -- --------------------------------------------------------
    -- PASO 2: Determinar si hubo cambio
    -- --------------------------------------------------------
    IF NOT FOUND THEN
        -- Primera lectura de este producto
        v_has_changed := TRUE;
    ELSIF v_previous_rate IS DISTINCT FROM NEW.rate THEN
        -- La tasa cambió respecto a la lectura anterior
        v_has_changed := TRUE;
    END IF;

    -- --------------------------------------------------------
    -- PASO 3: Registrar el cambio si corresponde
    -- --------------------------------------------------------
    IF v_has_changed THEN
        INSERT INTO interest_rate_changes (
            rate_id,
            old_rate,
            new_rate,
            detected_at
        ) VALUES (
            NEW.id,
            v_previous_rate,   -- NULL si es primera lectura
            NEW.rate,
            NOW()
        );
    END IF;

    RETURN NULL;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'detect_interest_rate_change() falló para rate_id=%, error: %',
            NEW.id, SQLERRM;
        RETURN NULL;
END;
$$;

-- ------------------------------------------------------------
-- Trigger sobre interest_rates
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_detect_interest_rate_change ON interest_rates;

CREATE TRIGGER trg_detect_interest_rate_change
    AFTER INSERT ON interest_rates
    FOR EACH ROW
    EXECUTE FUNCTION detect_interest_rate_change();

COMMENT ON TRIGGER trg_detect_interest_rate_change ON interest_rates IS
    'Detecta cambios en la tasa de interés tras cada inserción y registra en interest_rate_changes';