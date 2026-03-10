-- ============================================================
-- MIGRACIÓN 004: Triggers sobre currency_rates
-- ============================================================

-- Eliminar si existe (para poder re-ejecutar migraciones en dev)
DROP TRIGGER IF EXISTS trg_detect_rate_change ON currency_rates;

-- El trigger se dispara AFTER INSERT para que el registro ya
-- esté confirmado en la tabla antes de que la función lo lea.
-- FOR EACH ROW garantiza ejecución por cada fila insertada.
CREATE TRIGGER trg_detect_rate_change
    AFTER INSERT ON currency_rates
    FOR EACH ROW
    EXECUTE FUNCTION detect_rate_change();

COMMENT ON TRIGGER trg_detect_rate_change ON currency_rates IS
    'Dispara detect_rate_change() tras cada inserción para detectar variaciones en tasas.';