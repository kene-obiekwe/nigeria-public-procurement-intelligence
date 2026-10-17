-- ============================================================
-- NOCOPO — Phase 10.1 validation: 12 DQ-21 award scale flag
-- ============================================================
-- SF-01..03  analytics.vw_award_scale_flag matches an independent recount of
--            each test (multiplication instead of division for the
--            dropped-decimal test; window ranking instead of a self-join for
--            the sibling-lot test).
-- SF-04..10  structure and scope: one row per award, inside the M-V01 population,
--            no DQ-07 EXTREME or DQ-20 test-entity award, every row satisfies the
--            test it claims, no sibling match on the bare DQ-19 buyer.
-- SF-11..13  spot checks on the records verified in the raw source
--            (docs/phase10_findings/source_verification.md §A to §C).
-- SF-14      the flag is additive: existing metric populations are unchanged.
-- SF-15..17  INFO: size of the flagged set.
-- ============================================================
WITH
flag AS MATERIALIZED (SELECT * FROM analytics.vw_award_scale_flag),
aw   AS MATERIALIZED (SELECT * FROM analytics.vw_award_value_eligible),
bva  AS MATERIALIZED (SELECT * FROM analytics.vw_budget_award_comparison),
-- independent recount, test 1: whole naira and 50 * budget <= award <= 200 * budget
dd AS (
    SELECT award_id FROM bva
    WHERE mod(award_value_amount, 1) = 0
      AND award_value_amount >= 50 * budget_amount
      AND award_value_amount <= 200 * budget_amount),
-- independent recount, test 2: the supplier's largest award from a buyer is at
-- least 500 times its second-largest award from the same buyer
sup_ranked AS (
    SELECT award_id, award_value_amount,
           row_number() OVER (PARTITION BY supplier_id, buyer_id ORDER BY award_value_amount DESC, award_id) AS rn,
           lead(award_value_amount) OVER (PARTITION BY supplier_id, buyer_id ORDER BY award_value_amount DESC, award_id) AS next_value
    FROM analytics.vw_supplier_award_eligible
    WHERE buyer_id_flag IS NULL),
sl AS (SELECT award_id FROM sup_ranked WHERE rn = 1 AND next_value IS NOT NULL AND award_value_amount >= 500 * next_value),
either AS (SELECT award_id FROM dd UNION SELECT award_id FROM sl),
pop AS MATERIALIZED (SELECT metric_id, eligible_count FROM analytics.vw_metric_population),
c (check_id, check_name, severity, expected, actual) AS (VALUES
 ('SF-01', 'vw_award_scale_flag rows = independent recount (either test)', 'GATE',
    (SELECT count(*) FROM either)::text, (SELECT count(*) FROM flag)::text),
 ('SF-02', 'Rows passing the dropped-decimal test = independent recount', 'GATE',
    (SELECT count(*) FROM dd)::text, (SELECT count(*) FROM flag WHERE dropped_decimal_test)::text),
 ('SF-03', 'Rows passing the sibling-lot test = independent recount', 'GATE',
    (SELECT count(*) FROM sl)::text, (SELECT count(*) FROM flag WHERE sibling_lot_test)::text),
 ('SF-04', 'Duplicate award_id values', 'GATE', '0',
    (SELECT count(*) - count(DISTINCT award_id) FROM flag)::text),
 ('SF-05', 'Flagged awards outside the M-V01 eligible population', 'GATE', '0',
    (SELECT count(*) FROM flag f WHERE NOT EXISTS (SELECT 1 FROM aw WHERE aw.award_id = f.award_id))::text),
 ('SF-06', 'Rows with a scale_flag other than POSSIBLE_SCALE_ERROR or an unknown flag_reason', 'GATE', '0',
    (SELECT count(*) FROM flag
      WHERE scale_flag IS DISTINCT FROM 'POSSIBLE_SCALE_ERROR'
         OR flag_reason NOT IN ('DROPPED_DECIMAL', 'SIBLING_LOT', 'DROPPED_DECIMAL+SIBLING_LOT'))::text),
 ('SF-07', 'Overlap with DQ-07 EXTREME awards', 'GATE', '0',
    (SELECT count(*) FROM flag f JOIN stg.awards a ON a.award_id = f.award_id WHERE a.award_value_flag = 'EXTREME')::text),
 ('SF-08', 'Flagged awards of the DQ-20 portal test entity', 'GATE', '0',
    (SELECT count(*) FROM flag WHERE buyer_id = 'NG-BPP-BPP-NOC-90')::text),
 ('SF-09', 'Rows that do not satisfy the test they claim', 'GATE', '0',
    (SELECT count(*) FROM flag
      WHERE (dropped_decimal_test AND NOT (mod(award_value_amount, 1) = 0 AND award_to_budget_ratio BETWEEN 50 AND 200))
         OR (sibling_lot_test AND NOT (ratio_to_sibling >= 500))
         OR NOT (dropped_decimal_test OR sibling_lot_test))::text),
 ('SF-10', 'Sibling-lot rows matched on the bare NG-BPP- buyer (DQ-19)', 'GATE', '0',
    (SELECT count(*) FROM flag WHERE sibling_lot_test AND buyer_id = 'NG-BPP-')::text),
 ('SF-11', 'Spot check A: the top supplier''s award 19325 (ocds-gyl66f-2-005025) is flagged SIBLING_LOT', 'GATE', 'SIBLING_LOT',
    (SELECT flag_reason FROM flag WHERE award_id = '19325')),
 ('SF-12', 'Spot check C: ocds-gyl66f-252041001-000254 (award exactly 100 x budget) is flagged DROPPED_DECIMAL', 'GATE', 'DROPPED_DECIMAL',
    (SELECT flag_reason FROM flag WHERE ocid = 'ocds-gyl66f-252041001-000254')),
 ('SF-13', 'Spot check B: FMC Taraba award 8319 is not flagged (no budget line, bare supplier ID: unresolved, not testable)', 'GATE', '0',
    (SELECT count(*) FROM flag WHERE award_id = '8319')::text),
 ('SF-14', 'Existing eligible populations unchanged (M-V01 | M-S01 | budget-to-award)', 'GATE', '15763|13537|15574',
    (SELECT max(eligible_count) FILTER (WHERE metric_id = 'M-V01')::text || '|'
         || max(eligible_count) FILTER (WHERE metric_id = 'M-S01')::text || '|'
         || max(eligible_count) FILTER (WHERE metric_id = 'P4-BvA')::text FROM pop)),
 ('SF-15', 'Flagged awards (DROPPED_DECIMAL | SIBLING_LOT | both)', 'INFO', NULL,
    (SELECT count(*) FILTER (WHERE flag_reason = 'DROPPED_DECIMAL')::text || '|'
         || count(*) FILTER (WHERE flag_reason = 'SIBLING_LOT')::text || '|'
         || count(*) FILTER (WHERE flag_reason = 'DROPPED_DECIMAL+SIBLING_LOT')::text FROM flag)),
 ('SF-16', 'Flagged award value, NGN bn', 'INFO', NULL,
    (SELECT round(sum(award_value_amount) / 1e9, 2)::text FROM flag)),
 ('SF-17', 'Flagged share of M-V01 eligible award value, %', 'INFO', NULL,
    (SELECT round(100 * (SELECT sum(award_value_amount) FROM flag) / sum(award_value_amount), 2)::text FROM aw))
)
SELECT check_id, 'Award scale flag (Phase 10.1, DQ-21)' AS check_group, check_name, severity, expected, actual,
       CASE WHEN severity = 'GATE' THEN expected = actual END AS passed
FROM c;
