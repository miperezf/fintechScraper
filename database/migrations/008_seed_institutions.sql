-- ============================================================
-- MIGRACIÓN: Paso 3 de 4
-- Seed de instituciones y productos reales a monitorear
-- ============================================================

-- ------------------------------------------------------------
-- INSTITUCIONES
-- ------------------------------------------------------------
INSERT INTO institutions (name, country, website, type, is_active)
VALUES
    ('Mercado Pago',     'CL', 'https://www.mercadopago.cl',    'fintech',           TRUE),
    ('Tenpo',            'CL', 'https://www.tenpo.cl',          'fintech',           TRUE),
    ('Banco Estado',     'CL', 'https://www.bancoestado.cl',    'banco',             TRUE),
    ('Santander',        'CL', 'https://www.santander.cl',      'banco',             TRUE),
    ('Banco Falabella',  'CL', 'https://www.bancofalabella.cl', 'banco',             TRUE),
    ('Coopeuch',         'CL', 'https://www.coopeuch.cl',       'cooperativa',       TRUE),
    ('Los Andes',        'CL', 'https://www.losandes.cl',       'caja_compensacion', TRUE)
ON CONFLICT (name) DO NOTHING;

-- ------------------------------------------------------------
-- PRODUCTOS
-- Usamos subqueries para resolver institution_id dinámicamente
-- ------------------------------------------------------------
INSERT INTO products (institution_id, name, product_type, currency, is_active)
VALUES
    (
        (SELECT id FROM institutions WHERE name = 'Mercado Pago'),
        'Cuenta Remunerada',
        'cuenta_remunerada',
        'CLP',
        TRUE
    ),
    (
        (SELECT id FROM institutions WHERE name = 'Tenpo'),
        'Cuenta Remunerada',
        'cuenta_remunerada',
        'CLP',
        TRUE
    ),
    (
        (SELECT id FROM institutions WHERE name = 'Banco Estado'),
        'CuentaRUT',
        'cuenta_vista',
        'CLP',
        TRUE
    ),
    (
        (SELECT id FROM institutions WHERE name = 'Banco Estado'),
        'Cuenta de Ahorro',
        'cuenta_ahorro',
        'CLP',
        TRUE
    ),
    (
        (SELECT id FROM institutions WHERE name = 'Santander'),
        'Cuenta de Ahorro',
        'cuenta_ahorro',
        'CLP',
        TRUE
    ),
    (
        (SELECT id FROM institutions WHERE name = 'Banco Falabella'),
        'Cuenta Vista CMR',
        'cuenta_vista',
        'CLP',
        TRUE
    ),
    (
        (SELECT id FROM institutions WHERE name = 'Coopeuch'),
        'Cuenta de Ahorro',
        'cuenta_ahorro',
        'CLP',
        TRUE
    ),
    (
        (SELECT id FROM institutions WHERE name = 'Los Andes'),
        'Cuenta de Ahorro',
        'cuenta_ahorro',
        'CLP',
        TRUE
    )
ON CONFLICT (institution_id, name) DO NOTHING;