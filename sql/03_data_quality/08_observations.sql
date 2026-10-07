-- ============================================================
-- NOCOPO — Phase 6 validation: 08 Recorded observations
-- ============================================================
-- Measurements behind decisions taken in Phase 6 (O-1, O-3). INFO only:
-- they document data behaviour that constrains later metrics.
-- ============================================================
WITH c (check_id, check_name, severity, expected, actual) AS (VALUES
 ('OB-01', 'O-1: tender-award pairs (same release) with tender value = award value', 'INFO', NULL,
    (SELECT count(*) FILTER (WHERE t.tender_value_amount = a.award_value_amount) || ' of ' || count(*)
       FROM stg.tender t JOIN stg.awards a USING (release_id))),
 ('OB-02', 'O-1: contracts with contract value = award value', 'INFO', NULL,
    (SELECT count(*) FILTER (WHERE c.contract_value_amount = a.award_value_amount) || ' of ' || count(*)
       FROM stg.contracts c JOIN stg.awards a USING (award_id))),
 ('OB-03', 'O-1: tenders without an award whose tender value is 0', 'INFO', NULL,
    (SELECT count(*) FILTER (WHERE t.tender_value_amount = 0) || ' of ' || count(*)
       FROM stg.tender t WHERE NOT EXISTS (SELECT 1 FROM stg.awards a WHERE a.release_id = t.release_id))),
 ('OB-04', 'O-3: repeated supplier entries on one award (deduplicate in M-S01, Phase 7)', 'INFO', NULL,
    (SELECT (count(*) - count(DISTINCT (award_id, supplier_id)))::text FROM stg.award_suppliers)),
 ('OB-05', 'O-3: awards carrying repeated supplier entries', 'INFO', NULL,
    (SELECT count(*)::text FROM (SELECT award_id FROM stg.award_suppliers GROUP BY 1
                                  HAVING count(*) > count(DISTINCT supplier_id)) x))
)
SELECT check_id, 'Observations' AS check_group, check_name, severity, expected, actual,
       CASE WHEN severity = 'GATE' THEN expected = actual END AS passed
FROM c;
