-- ============================================================
-- NOCOPO — Read-only role for Power BI (Phase 9, Gate C)
-- ============================================================
-- Gate C: Power BI may connect only to validated analytics.* views. This script
-- enforces that in the database instead of relying on convention:
--   * nocopo_bi can CONNECT to nocopo_db and USE the analytics schema;
--   * it can SELECT every object in analytics, and nothing else;
--   * it has no privilege on stg or core (schema USAGE is withheld, so every
--     stg.* / core.* query is refused);
--   * it cannot create, change or delete anything (read-only by default).
--
-- NO PASSWORD is set here and none must ever be stored in the repository.
-- The role has LOGIN but no password, so it cannot connect until you set one.
-- Set it yourself in psql (the password is not echoed or logged):
--     psql -h localhost -p 5433 -U postgres -d nocopo_db
--     \password nocopo_bi
-- (pg_hba.conf requires scram-sha-256 on localhost, so a password is mandatory.)
--
-- Re-runnable. Run it AFTER the analytics views exist, and again after any
-- rebuild that drops views (a DROP ... CASCADE removes their grants):
--     psql -h localhost -p 5433 -U postgres -d nocopo_db -v ON_ERROR_STOP=1 \
--          -f database/seed_and_setup/01_create_bi_role.sql
-- ============================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'nocopo_bi') THEN
        CREATE ROLE nocopo_bi LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
    END IF;
END $$;

-- Defensive: read-only sessions, and a ceiling on runaway queries.
ALTER ROLE nocopo_bi SET default_transaction_read_only = on;
ALTER ROLE nocopo_bi SET statement_timeout = '120s';

GRANT CONNECT ON DATABASE nocopo_db TO nocopo_bi;

-- Nothing in the working layers. (Both statements are no-ops on a clean
-- database and make the intent explicit.)
REVOKE ALL ON SCHEMA stg  FROM nocopo_bi;
REVOKE ALL ON SCHEMA core FROM nocopo_bi;

-- The analytics schema: read only.
GRANT USAGE ON SCHEMA analytics TO nocopo_bi;
GRANT SELECT ON ALL TABLES IN SCHEMA analytics TO nocopo_bi;          -- includes views
ALTER DEFAULT PRIVILEGES IN SCHEMA analytics GRANT SELECT ON TABLES TO nocopo_bi;
