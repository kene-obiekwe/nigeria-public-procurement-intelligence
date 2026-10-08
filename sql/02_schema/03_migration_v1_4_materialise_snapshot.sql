-- ============================================================
-- NOCOPO — Schema migration v1.4 (Phase 8.1): materialise the process snapshot
-- ============================================================
-- Existing databases only. Drops the PLAIN views core.vw_budget_lines and
-- core.vw_process_snapshot together with every view that depends on them (all
-- analytics.* views). Nothing in stg.* or core.dim_* is touched.
-- If the objects are already materialised this script does nothing.
--
-- Then rebuild, in order:
--   sql/04_transformations/03_process_snapshot.sql
--   sql/05_views/01_budget_eligible.sql ... 09_dq_impact.sql
-- ============================================================
DO $$
DECLARE
    obj text;
BEGIN
    FOREACH obj IN ARRAY ARRAY['core.vw_process_snapshot', 'core.vw_budget_lines'] LOOP
        IF to_regclass(obj) IS NOT NULL
           AND (SELECT relkind FROM pg_class WHERE oid = to_regclass(obj)) = 'v' THEN
            EXECUTE 'DROP VIEW ' || obj || ' CASCADE';
            RAISE NOTICE 'dropped plain view % (and dependants)', obj;
        END IF;
    END LOOP;
END $$;
