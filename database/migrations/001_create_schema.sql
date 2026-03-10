-- ============================================================
-- MIGRACIÓN 001: Esquema base de la plataforma
-- Autor: Sistema
-- Descripción: Crea las tablas principales con sus constraints
-- ============================================================

-- Extensión para generación de UUIDs
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ------------------------------------------------------------
-- TABLA: sources
-- Representa cada institución financiera que scrapeamos
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sources (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(100) NOT NULL,
    country     CHAR(2) NOT NULL,                          -- ISO 3166-1 alpha-2 (ej: "CL", "US")
    base_url    TEXT NOT NULL,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT sources_name_country_unique UNIQUE (name, country),
    CONSTRAINT sources_country_format CHECK (country ~ '^[A-Z]{2}$')
);

COMMENT ON TABLE sources IS 'Instituciones financieras desde las que se obtienen tipos de cambio';
COMMENT ON COLUMN sources.country IS 'Código de país ISO 3166-1 alpha-2 en mayúsculas';

-- ------------------------------------------------------------
-- TABLA: currency_rates
-- Almacena cada lectura de tipo de cambio obtenida por el scraper
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS currency_rates (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_id     UUID NOT NULL REFERENCES sources(id) ON DELETE CASCADE,
    currency_code CHAR(3) NOT NULL,                        -- ISO 4217 (ej: "USD", "EUR")
    buy_rate      NUMERIC(18, 6) NOT NULL,
    sell_rate     NUMERIC(18, 6) NOT NULL,
    timestamp     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT currency_rates_buy_positive  CHECK (buy_rate > 0),
    CONSTRAINT currency_rates_sell_positive CHECK (sell_rate > 0),
    CONSTRAINT currency_rates_currency_format CHECK (currency_code ~ '^[A-Z]{3}$')
);

COMMENT ON TABLE currency_rates IS 'Historial de tipos de cambio scrapeados por fuente y moneda';
COMMENT ON COLUMN currency_rates.currency_code IS 'Código de moneda ISO 4217 en mayúsculas';
COMMENT ON COLUMN currency_rates.buy_rate IS 'Tasa de compra con 6 decimales de precisión';
COMMENT ON COLUMN currency_rates.sell_rate IS 'Tasa de venta con 6 decimales de precisión';

-- ------------------------------------------------------------
-- TABLA: rate_changes
-- Registro inmutable de cada vez que una tasa cambió
-- Esta tabla es append-only — nunca se actualiza ni elimina
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS rate_changes (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rate_id       UUID NOT NULL REFERENCES currency_rates(id) ON DELETE CASCADE,
    old_buy_rate  NUMERIC(18, 6),                          -- NULL en el primer registro de una moneda
    new_buy_rate  NUMERIC(18, 6) NOT NULL,
    old_sell_rate NUMERIC(18, 6),                          -- NULL en el primer registro de una moneda
    new_sell_rate NUMERIC(18, 6) NOT NULL,
    detected_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT rate_changes_new_buy_positive  CHECK (new_buy_rate > 0),
    CONSTRAINT rate_changes_new_sell_positive CHECK (new_sell_rate > 0)
);

COMMENT ON TABLE rate_changes IS 'Registro inmutable de cambios detectados en tipos de cambio';