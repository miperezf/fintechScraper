-- ============================================================
-- MIGRACIÓN: Nuevo schema para monitoreo de tasas de interés
-- Paso 1 de 4: Crear nuevas tablas (no destructivo)
-- ============================================================

-- ------------------------------------------------------------
-- TABLA: institutions
-- Reemplaza a `sources` con campos específicos al dominio
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS institutions (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(100) NOT NULL,
    country     CHAR(2) NOT NULL DEFAULT 'CL',
    website     TEXT,
    type        VARCHAR(30) NOT NULL,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT institutions_name_unique UNIQUE (name),
    CONSTRAINT institutions_country_format CHECK (country ~ '^[A-Z]{2}$'),
    CONSTRAINT institutions_type_valid CHECK (
        type IN ('banco', 'fintech', 'cooperativa', 'caja_compensacion')
    )
);

COMMENT ON TABLE institutions IS 'Instituciones financieras monitoreadas';
COMMENT ON COLUMN institutions.type IS 'banco | fintech | cooperativa | caja_compensacion';

-- ------------------------------------------------------------
-- TABLA: products
-- Representa cada producto financiero de una institución
-- Ej: "Cuenta Remunerada" de Mercado Pago
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS products (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id  UUID NOT NULL REFERENCES institutions(id) ON DELETE CASCADE,
    name            VARCHAR(150) NOT NULL,
    product_type    VARCHAR(50) NOT NULL,
    currency        CHAR(3) NOT NULL DEFAULT 'CLP',
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT products_name_institution_unique UNIQUE (institution_id, name),
    CONSTRAINT products_type_valid CHECK (
        product_type IN ('cuenta_remunerada', 'cuenta_ahorro', 'cuenta_vista', 'deposito_plazo')
    ),
    CONSTRAINT products_currency_format CHECK (currency ~ '^[A-Z]{3}$')
);

COMMENT ON TABLE products IS 'Productos financieros que ofrecen tasa de interés';
COMMENT ON COLUMN products.product_type IS 'cuenta_remunerada | cuenta_ahorro | cuenta_vista | deposito_plazo';

-- ------------------------------------------------------------
-- TABLA: interest_rates
-- Cada fila es una lectura scrapeada del porcentaje
-- mostrado en el sitio web de la institución
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS interest_rates (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id  UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    rate        NUMERIC(8, 4) NOT NULL,     -- Ej: 13.5000 = 13.5%
    scraped_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT interest_rates_rate_positive CHECK (rate >= 0),
    CONSTRAINT interest_rates_rate_max CHECK (rate <= 100)
);

COMMENT ON TABLE interest_rates IS 'Historial de tasas de interés scrapeadas por producto';
COMMENT ON COLUMN interest_rates.rate IS 'Porcentaje anual tal como aparece en el sitio web. Ej: 13.5 = 13.5%';

-- ------------------------------------------------------------
-- TABLA: interest_rate_changes
-- Registro inmutable de cada cambio detectado
-- Nombre diferente a rate_changes para coexistir durante migración
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS interest_rate_changes (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rate_id     UUID NOT NULL REFERENCES interest_rates(id) ON DELETE CASCADE,
    old_rate    NUMERIC(8, 4),              -- NULL en primera lectura
    new_rate    NUMERIC(8, 4) NOT NULL,
    detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT interest_rate_changes_new_rate_positive CHECK (new_rate >= 0)
);

COMMENT ON TABLE interest_rate_changes IS 'Registro inmutable de cambios detectados en tasas de interés';

-- ------------------------------------------------------------
-- ÍNDICES para rendimiento
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_institutions_type
    ON institutions(type);

CREATE INDEX IF NOT EXISTS idx_institutions_is_active
    ON institutions(is_active) WHERE is_active = TRUE;

CREATE INDEX IF NOT EXISTS idx_products_institution
    ON products(institution_id);

CREATE INDEX IF NOT EXISTS idx_products_active
    ON products(institution_id, is_active) WHERE is_active = TRUE;

CREATE INDEX IF NOT EXISTS idx_interest_rates_product_time
    ON interest_rates(product_id, scraped_at DESC);

CREATE INDEX IF NOT EXISTS idx_interest_rate_changes_detected
    ON interest_rate_changes(detected_at DESC);