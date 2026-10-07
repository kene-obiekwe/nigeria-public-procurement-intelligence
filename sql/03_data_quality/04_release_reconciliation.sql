-- ============================================================
-- NOCOPO — Phase 6 validation: 04 Duplicate / release reconciliation
-- ============================================================
-- Proves the process snapshot collapses repeated releases without
-- double counting. Snapshot totals are re-derived with a second,
-- independent SQL formulation (NOT EXISTS a later release) rather than
-- the DISTINCT ON used in the views, and must agree exactly.
-- Documented expectations: docs/phase4_data_model/phase4_1_snapshot_validation_report.md
-- ============================================================
WITH
alt_budget AS (           -- independent: latest release per (ocid, project) via NOT EXISTS
    SELECT p.budget_amount
    FROM stg.planning p JOIN stg.releases r USING (release_id)
    WHERE p.budget_project_id IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM stg.planning p2 JOIN stg.releases r2 USING (release_id)
                      WHERE r2.ocid = r.ocid AND p2.budget_project_id = p.budget_project_id
                        AND r2.release_seq > r.release_seq)
),
alt_award AS (            -- independent: latest award release per OCID via NOT EXISTS
    SELECT a.award_value_amount
    FROM stg.awards a JOIN stg.releases r USING (release_id)
    WHERE NOT EXISTS (SELECT 1 FROM stg.awards a2 JOIN stg.releases r2 USING (release_id)
                      WHERE r2.ocid = r.ocid AND r2.release_seq > r.release_seq)
),
snap_award AS (
    SELECT a.award_value_amount FROM core.vw_process_snapshot s JOIN stg.awards a USING (award_id)
),
c (check_id, check_name, severity, expected, actual) AS (VALUES
 ('RL-01', 'Snapshot rows = distinct OCIDs in staging', 'GATE',
    (SELECT count(DISTINCT ocid) FROM stg.releases)::text, (SELECT count(*) FROM core.vw_process_snapshot)::text),
 ('RL-02', 'Multi-release OCIDs (Phase 4.1: 6,280)', 'GATE', '6280',
    (SELECT count(*) FROM core.vw_process_snapshot WHERE release_count > 1)::text),
 ('RL-03', 'Budget lines (Phase 4.1: 97,749)', 'GATE', '97749', (SELECT count(*) FROM core.vw_budget_lines)::text),
 ('RL-04', 'OCIDs flagged MULTI_PROJECT (Phase 4.1 / C-06: 192)', 'GATE', '192',
    (SELECT count(*) FROM core.vw_process_snapshot WHERE multi_project_flag = 'MULTI_PROJECT')::text),
 ('RL-05', 'Budget-line total excl. EXTREME, NGN bn (Phase 4.1 R3: 93,827.8)', 'GATE', '93827.8',
    (SELECT round(sum(budget_amount) / 1e9, 1) FROM core.vw_budget_lines WHERE budget_amount_flag IS NULL)::text),
 ('RL-06', 'Budget-line total: view = independent NOT EXISTS formulation (NGN)', 'GATE',
    (SELECT sum(budget_amount) FROM alt_budget)::text, (SELECT sum(budget_amount) FROM core.vw_budget_lines)::text),
 ('RL-07', 'Snapshot OCIDs with a tender = distinct OCIDs having a tender', 'GATE',
    (SELECT count(DISTINCT r.ocid) FROM stg.tender t JOIN stg.releases r USING (release_id))::text,
    (SELECT count(tender_id) FROM core.vw_process_snapshot)::text),
 ('RL-08', 'Snapshot OCIDs with an award = distinct OCIDs having an award', 'GATE',
    (SELECT count(DISTINCT r.ocid) FROM stg.awards a JOIN stg.releases r USING (release_id))::text,
    (SELECT count(award_id) FROM core.vw_process_snapshot)::text),
 ('RL-09', 'Snapshot award total = independent NOT EXISTS formulation (NGN)', 'GATE',
    (SELECT sum(award_value_amount) FROM alt_award)::text, (SELECT sum(award_value_amount) FROM snap_award)::text),
 ('RL-10', 'Award value across ALL releases (would double count), NGN', 'INFO', NULL,
    (SELECT sum(award_value_amount) FROM stg.awards)::text),
 ('RL-11', 'Award value in snapshot (one award per OCID), NGN', 'INFO', NULL,
    (SELECT sum(award_value_amount) FROM snap_award)::text),
 ('RL-12', 'Budget across ALL releases incl. repeats (would double count), NGN', 'INFO', NULL,
    (SELECT sum(budget_amount) FROM stg.planning)::text),
 ('RL-13', 'Multi-release OCIDs where text order of release_id picks a different latest release (Phase 4.1: 1,508)', 'GATE', '1508',
    (SELECT count(*) FROM (SELECT ocid FROM stg.releases GROUP BY ocid HAVING count(*) > 1
                             AND max(release_id) <> (array_agg(release_id ORDER BY release_seq DESC))[1]) x)::text)
)
SELECT check_id, 'Release reconciliation' AS check_group, check_name, severity, expected, actual,
       CASE WHEN severity = 'GATE' THEN expected = actual END AS passed
FROM c;
