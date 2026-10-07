-- ============================================================
-- NOCOPO — Phase 6 validation: 07 Raw -> staging -> core reconciliation
-- ============================================================
-- Raw counts are the values measured by an independent traversal of the
-- source JSON (python/ingest/02_reconcile_staging.py, which the suite
-- runner executes first). Here they are pinned as constants so the chain
-- raw = staging = core can be read in one place.
-- ============================================================
WITH c (check_id, check_name, severity, expected, actual) AS (VALUES
 ('LR-01', 'raw releases = stg.releases',           'GATE', '108277', (SELECT count(*) FROM stg.releases)::text),
 ('LR-02', 'raw planning = stg.planning',           'GATE', '108277', (SELECT count(*) FROM stg.planning)::text),
 ('LR-03', 'raw tenders = stg.tender',              'GATE', '18408',  (SELECT count(*) FROM stg.tender)::text),
 ('LR-04', 'raw awards = stg.awards',               'GATE', '17417',  (SELECT count(*) FROM stg.awards)::text),
 ('LR-05', 'raw award suppliers = stg.award_suppliers', 'GATE', '17441', (SELECT count(*) FROM stg.award_suppliers)::text),
 ('LR-06', 'raw contracts = stg.contracts',         'GATE', '17043',  (SELECT count(*) FROM stg.contracts)::text),
 ('LR-07', 'raw transactions = stg.transactions',   'GATE', '13617',  (SELECT count(*) FROM stg.transactions)::text),
 ('LR-08', 'raw milestones = stg.milestones',       'GATE', '42854',  (SELECT count(*) FROM stg.milestones)::text),
 ('LR-09', 'raw parties = stg.parties',             'GATE', '124530', (SELECT count(*) FROM stg.parties)::text),
 ('LR-10', 'raw OCIDs = core.vw_process_snapshot',  'GATE', '98866',  (SELECT count(*) FROM core.vw_process_snapshot)::text),
 ('LR-11', 'staging distinct buyer IDs = core.dim_buyer', 'GATE',
    (SELECT count(DISTINCT buyer_id) FROM stg.releases)::text, (SELECT count(*) FROM core.dim_buyer)::text),
 ('LR-12', 'staging releases = sum of dim_buyer.release_count', 'GATE',
    (SELECT count(*) FROM stg.releases)::text, (SELECT sum(release_count) FROM core.dim_buyer)::text),
 ('LR-13', 'staging releases = sum of snapshot release_count', 'GATE',
    (SELECT count(*) FROM stg.releases)::text, (SELECT sum(release_count) FROM core.vw_process_snapshot)::text),
 ('LR-14', 'staging distinct (ocid, budget line) = core.vw_budget_lines', 'GATE',
    (SELECT count(DISTINCT (r.ocid, p.budget_project_id)) FROM stg.planning p JOIN stg.releases r USING (release_id)
      WHERE p.budget_project_id IS NOT NULL)::text,
    (SELECT count(*) FROM core.vw_budget_lines)::text)
)
SELECT check_id, 'Layer reconciliation' AS check_group, check_name, severity, expected, actual,
       CASE WHEN severity = 'GATE' THEN expected = actual END AS passed
FROM c;
