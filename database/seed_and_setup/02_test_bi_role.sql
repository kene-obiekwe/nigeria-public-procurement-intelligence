-- ============================================================
-- NOCOPO — Test of the read-only BI role (Phase 9, Gate C)
-- ============================================================
-- Run as the database owner (postgres). It does not need the nocopo_bi password:
-- SET ROLE makes the session behave exactly as nocopo_bi for privilege checks.
--     psql -h localhost -p 5433 -U postgres -d nocopo_db -f database/seed_and_setup/02_test_bi_role.sql
-- Expected: the analytics queries return rows; every stg / core / write attempt
-- prints "ERROR: permission denied" (or "read-only transaction"). The errors are
-- the point of the test, so this script deliberately does not stop on them.
-- ============================================================
\set ON_ERROR_STOP off
\pset footer off
\echo
\echo '== 1. Role attributes (expect: login t, superuser f, createdb f, createrole f)'
SELECT rolname, rolcanlogin AS login, rolsuper AS superuser, rolcreatedb AS createdb,
       rolcreaterole AS createrole, rolreplication AS replication
FROM pg_roles WHERE rolname = 'nocopo_bi';

\echo
\echo '== 2. Allowed: analytics.* (expect rows)'
SET ROLE nocopo_bi;
SELECT 'vw_metric_population' AS object, count(*) AS rows FROM analytics.vw_metric_population;
SELECT 'vw_dim_buyer'          AS object, count(*) AS rows FROM analytics.vw_dim_buyer;
SELECT 'vw_budget_eligible'    AS object, count(*) AS rows FROM analytics.vw_budget_eligible;
SELECT 'vw_dq_impact'          AS object, count(*) AS rows FROM analytics.vw_dq_impact;

\echo
\echo '== 3. Denied: stg and core (expect permission denied)'
SELECT count(*) FROM stg.releases;
SELECT count(*) FROM stg.awards;
SELECT count(*) FROM core.dim_buyer;
SELECT count(*) FROM core.vw_process_snapshot;

\echo
\echo '== 4. Denied: writes and DDL (expect errors)'
DELETE FROM analytics.vw_dim_buyer;
INSERT INTO analytics.vw_dim_buyer (buyer_id) VALUES ('x');
CREATE TABLE analytics.should_not_exist (a int);
CREATE TABLE public.should_not_exist (a int);
RESET ROLE;

\echo
\echo '== 5. Catalogue check (expect: connect t; analytics usage t; stg usage f; core usage f)'
SELECT has_database_privilege('nocopo_bi', 'nocopo_db', 'CONNECT') AS connect,
       has_schema_privilege('nocopo_bi', 'analytics', 'USAGE')    AS analytics_usage,
       has_schema_privilege('nocopo_bi', 'stg',  'USAGE')         AS stg_usage,
       has_schema_privilege('nocopo_bi', 'core', 'USAGE')         AS core_usage,
       has_schema_privilege('nocopo_bi', 'analytics', 'CREATE')   AS analytics_create;

\echo
\echo '== 6. Objects the role can SELECT outside analytics (expect 0)'
SELECT count(*) AS selectable_outside_analytics
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind IN ('r', 'v', 'm', 'p', 'f')
  AND n.nspname NOT IN ('analytics', 'pg_catalog', 'information_schema', 'pg_toast')
  AND has_table_privilege('nocopo_bi', c.oid, 'SELECT');
