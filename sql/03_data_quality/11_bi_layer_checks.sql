-- ============================================================
-- NOCOPO — Phase 9 validation: 11 Power BI layer (Gate C)
-- ============================================================
-- BI-*:  the read-only role nocopo_bi can read analytics.* and nothing else
--        (database/seed_and_setup/01_create_bi_role.sql). Gate C, enforced.
-- DIM-*: the presentation dimensions (analytics.vw_dim_buyer,
--        analytics.vw_dim_procurement_method) have unique keys, the right
--        membership, and every fact row finds its dimension row (except the
--        bare NG-BPP- buyer, which is deliberately not a dimension member).
-- ============================================================
WITH
fact_buyers AS MATERIALIZED (
    SELECT 'vw_budget_eligible' AS v, buyer_id FROM analytics.vw_budget_eligible
    UNION ALL SELECT 'vw_competition_eligible', buyer_id FROM analytics.vw_competition_eligible
    UNION ALL SELECT 'vw_award_value_eligible', buyer_id FROM analytics.vw_award_value_eligible
    UNION ALL SELECT 'vw_supplier_award_eligible', buyer_id FROM analytics.vw_supplier_award_eligible
    UNION ALL SELECT 'vw_budget_award_comparison', buyer_id FROM analytics.vw_budget_award_comparison
    UNION ALL SELECT 'vw_tender_duration_eligible', buyer_id FROM analytics.vw_tender_duration_eligible
    UNION ALL SELECT 'vw_award_lag_eligible', buyer_id FROM analytics.vw_award_lag_eligible
    UNION ALL SELECT 'vw_signature_lag_eligible', buyer_id FROM analytics.vw_signature_lag_eligible
    UNION ALL SELECT 'vw_lifecycle_stage', buyer_id FROM analytics.vw_lifecycle_stage
    UNION ALL SELECT 'vw_contract_implementation_coverage', buyer_id FROM analytics.vw_contract_implementation_coverage
    UNION ALL SELECT 'vw_entity_benchmark', buyer_id FROM analytics.vw_entity_benchmark),
fact_methods AS MATERIALIZED (
    SELECT coalesce(procurement_method_details, '(method not stated)') AS m FROM analytics.vw_competition_eligible
    UNION ALL SELECT coalesce(procurement_method_details, '(method not stated)') FROM analytics.vw_award_value_eligible
    UNION ALL SELECT coalesce(procurement_method_details, '(method not stated)') FROM analytics.vw_supplier_award_eligible
    UNION ALL SELECT coalesce(procurement_method_details, '(method not stated)') FROM analytics.vw_budget_award_comparison
    UNION ALL SELECT coalesce(procurement_method_details, '(method not stated)') FROM analytics.vw_tender_duration_eligible
    UNION ALL SELECT coalesce(procurement_method_details, '(method not stated)') FROM analytics.vw_award_lag_eligible),
-- independent source for the buyer dimension: distinct buyer IDs in staging, minus DQ-19 / DQ-20 by literal ID
stg_buyers AS (
    SELECT DISTINCT buyer_id FROM stg.releases
    WHERE buyer_id IS NOT NULL AND buyer_id NOT IN ('NG-BPP-', 'NG-BPP-BPP-NOC-90')),
-- independent source for the method dimension: methods on snapshot tenders of non-test buyers
ob AS (SELECT DISTINCT ON (ocid) ocid, buyer_id FROM stg.releases ORDER BY ocid, release_seq DESC),
stg_methods AS (
    SELECT DISTINCT t.procurement_method_details AS m
    FROM stg.tender t JOIN stg.releases r USING (release_id) JOIN ob ON ob.ocid = r.ocid
    WHERE ob.buyer_id <> 'NG-BPP-BPP-NOC-90' AND t.procurement_method_details IS NOT NULL),
c (check_id, check_name, severity, expected, actual) AS (VALUES
 -- Gate C: the read-only role -------------------------------------------------
 ('BI-01', 'Role nocopo_bi exists: login, not superuser, no createdb / createrole / replication', 'GATE', 'true|false|false|false|false',
    (SELECT rolcanlogin::text || '|' || rolsuper::text || '|' || rolcreatedb::text || '|' || rolcreaterole::text || '|' || rolreplication::text
       FROM pg_roles WHERE rolname = 'nocopo_bi')),
 ('BI-02', 'Role privileges: CONNECT, USAGE on analytics; no USAGE on stg or core; no CREATE on analytics', 'GATE', 'true|true|false|false|false',
    (SELECT has_database_privilege('nocopo_bi', current_database(), 'CONNECT')::text || '|'
         || has_schema_privilege('nocopo_bi', 'analytics', 'USAGE')::text || '|'
         || has_schema_privilege('nocopo_bi', 'stg', 'USAGE')::text || '|'
         || has_schema_privilege('nocopo_bi', 'core', 'USAGE')::text || '|'
         || has_schema_privilege('nocopo_bi', 'analytics', 'CREATE')::text)),
 ('BI-03', 'Objects outside analytics that the role can SELECT', 'GATE', '0',
    (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE c.relkind IN ('r', 'v', 'm', 'p', 'f')
        AND n.nspname NOT IN ('analytics', 'pg_catalog', 'information_schema', 'pg_toast')
        AND has_table_privilege('nocopo_bi', c.oid, 'SELECT'))::text),
 ('BI-04', 'analytics relations the role cannot SELECT (every view must be readable)', 'GATE', '0',
    (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = 'analytics' AND c.relkind IN ('r', 'v', 'm')
        AND NOT has_table_privilege('nocopo_bi', c.oid, 'SELECT'))::text),
 ('BI-05', 'analytics relations on which the role holds INSERT / UPDATE / DELETE / TRUNCATE', 'GATE', '0',
    (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = 'analytics' AND c.relkind IN ('r', 'v', 'm')
        AND (has_table_privilege('nocopo_bi', c.oid, 'INSERT') OR has_table_privilege('nocopo_bi', c.oid, 'UPDATE')
          OR has_table_privilege('nocopo_bi', c.oid, 'DELETE') OR has_table_privilege('nocopo_bi', c.oid, 'TRUNCATE')))::text),
 -- Buyer dimension ---------------------------------------------------------------
 ('DIM-01', 'vw_dim_buyer rows = distinct staging buyer IDs excluding the DQ-19 and DQ-20 buyers', 'GATE',
    (SELECT count(*) FROM stg_buyers)::text, (SELECT count(*) FROM analytics.vw_dim_buyer)::text),
 ('DIM-02', 'vw_dim_buyer: duplicate buyer_id values', 'GATE', '0',
    (SELECT count(*) - count(DISTINCT buyer_id) FROM analytics.vw_dim_buyer)::text),
 ('DIM-03', 'vw_dim_buyer: null or duplicate buyer_label values', 'GATE', '0',
    (SELECT count(*) - count(DISTINCT buyer_label) + count(*) FILTER (WHERE buyer_label IS NULL) FROM analytics.vw_dim_buyer)::text),
 ('DIM-04', 'vw_dim_buyer: the bare NG-BPP- buyer or the test entity present', 'GATE', '0',
    (SELECT count(*) FROM analytics.vw_dim_buyer WHERE buyer_id IN ('NG-BPP-', 'NG-BPP-BPP-NOC-90'))::text),
 ('DIM-05', 'vw_dim_buyer vs vw_entity_benchmark: buyers in one but not the other', 'GATE', '0',
    ((SELECT count(*) FROM analytics.vw_dim_buyer d WHERE NOT EXISTS (SELECT 1 FROM analytics.vw_entity_benchmark e WHERE e.buyer_id = d.buyer_id))
   + (SELECT count(*) FROM analytics.vw_entity_benchmark e WHERE NOT EXISTS (SELECT 1 FROM analytics.vw_dim_buyer d WHERE d.buyer_id = e.buyer_id)))::text),
 ('DIM-06', 'Fact rows (11 views) whose buyer_id is neither in vw_dim_buyer nor the bare NG-BPP- ID', 'GATE', '0',
    (SELECT count(*) FROM fact_buyers f
      WHERE f.buyer_id <> 'NG-BPP-' AND f.buyer_id NOT IN (SELECT buyer_id FROM analytics.vw_dim_buyer))::text),
 ('DIM-07', 'Fact rows carrying the bare NG-BPP- buyer ID (shown as (Blank) when split by buyer)', 'INFO', NULL,
    (SELECT count(*) FROM fact_buyers WHERE buyer_id = 'NG-BPP-')::text),
 -- Procurement-method dimension --------------------------------------------------
 ('DIM-08', 'vw_dim_procurement_method: duplicate or null keys', 'GATE', '0',
    (SELECT count(*) - count(DISTINCT procurement_method) + count(*) FILTER (WHERE procurement_method IS NULL)
       FROM analytics.vw_dim_procurement_method)::text),
 ('DIM-09', 'vw_dim_procurement_method = methods on non-test snapshot tenders + (method not stated)', 'GATE',
    ((SELECT count(*) FROM stg_methods) + 1)::text, (SELECT count(*) FROM analytics.vw_dim_procurement_method)::text),
 ('DIM-10', 'Fact rows (6 views) whose method has no dimension row', 'GATE', '0',
    (SELECT count(*) FROM fact_methods f WHERE f.m NOT IN (SELECT procurement_method FROM analytics.vw_dim_procurement_method))::text),
 ('DIM-11', 'vw_dim_procurement_method members used by no fact row', 'GATE', '0',
    (SELECT count(*) FROM analytics.vw_dim_procurement_method d WHERE d.procurement_method NOT IN (SELECT m FROM fact_methods))::text),
 ('DIM-12', 'vw_dim_procurement_method: members flagged is_not_stated', 'GATE', '1',
    (SELECT count(*) FROM analytics.vw_dim_procurement_method WHERE is_not_stated)::text)
)
SELECT check_id, 'Power BI layer (Phase 9)' AS check_group, check_name, severity, expected, actual,
       CASE WHEN severity = 'GATE' THEN expected = actual END AS passed
FROM c;
