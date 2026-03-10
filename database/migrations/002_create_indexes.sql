-- ============================================================
-- MIGRACIÓN 002: Índices para rendimiento en consultas críticas
-- ============================================================

-- Consultas frecuentes: "dame todas las tasas activas"
CREATE INDEX IF NOT EXISTS idx_sources_is_active
    ON sources(is_active)
    WHERE is_active = TRUE;

-- Consultas frecuentes: "última tasa de USD para el source X"
CREATE INDEX IF NOT EXISTS idx_currency_rates_source_currency
    ON currency_rates(source_id, currency_code);

-- Consultas de serie temporal: ordenar por tiempo descendente
CREATE INDEX IF NOT EXISTS idx_currency_rates_timestamp
    ON currency_rates(timestamp DESC);

-- Índice compuesto para la query más crítica del trigger:
-- "dame la tasa más reciente de esta moneda para esta fuente"
CREATE INDEX IF NOT EXISTS idx_currency_rates_source_currency_timestamp
    ON currency_rates(source_id, currency_code, timestamp DESC);

-- Consultas de auditoría: "qué cambios hubo en esta tasa?"
CREATE INDEX IF NOT EXISTS idx_rate_changes_rate_id
    ON rate_changes(rate_id);

-- Consultas de monitoreo: "qué cambios ocurrieron en las últimas N horas?"
CREATE INDEX IF NOT EXISTS idx_rate_changes_detected_at
    ON rate_changes(detected_at DESC);