-- ============================================================
-- SEED: Fuentes iniciales para desarrollo y testing
-- ============================================================

INSERT INTO sources (name, country, base_url, is_active)
VALUES
    ('Banco Central de Chile',    'CL', 'https://www.bcentral.cl',      TRUE),
    ('Banco Estado',              'CL', 'https://www.bancoestado.cl',   TRUE),
    ('Santander Chile',           'CL', 'https://www.santander.cl',     TRUE)
ON CONFLICT (name, country) DO NOTHING;
```

---

## 3. ESTRUCTURA DE ARCHIVOS
```
project-root/
│
└── database/
    └── migrations/
        ├── 001_create_schema.sql
        ├── 002_create_indexes.sql
        ├── 003_create_trigger_functions.sql
        ├── 004_create_triggers.sql
        └── 005_seed_sources.sql