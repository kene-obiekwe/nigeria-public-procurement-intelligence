-- ============================================================
-- NOCOPO — Phase 7 validation: 09 Analytical view populations
-- ============================================================
-- Phase 7 exit gate: "each view's row population matches its documented
-- eligibility definition, verified against a manual spot-check".
--
-- AV-*: each view's population is recomputed directly from stg.* with an
--       independent formulation (ROW_NUMBER latest release, instead of the
--       DISTINCT ON core snapshot views) and must match exactly.
-- SP-*: spot checks on named records with known expected outcomes.
-- WF-*: INFO exclusion waterfalls and disclosures behind each population.
-- ============================================================
WITH
rel AS (SELECT release_id, ocid, release_seq, buyer_id, party_flag FROM stg.releases),
-- Latest-release selection recomputed with ROW_NUMBER (the core views use
-- DISTINCT ON), so a defect in either formulation surfaces as a mismatch.
latest_tender AS (
    SELECT * FROM (SELECT r.ocid, t.*,
                          row_number() OVER (PARTITION BY r.ocid ORDER BY r.release_seq DESC) AS rn
                   FROM stg.tender t JOIN rel r USING (release_id)) x
    WHERE rn = 1),
latest_award AS (
    SELECT * FROM (SELECT r.ocid, a.*,
                          row_number() OVER (PARTITION BY r.ocid ORDER BY r.release_seq DESC) AS rn
                   FROM stg.awards a JOIN rel r USING (release_id)) x
    WHERE rn = 1),
latest_line AS (
    SELECT * FROM (SELECT r.ocid, r.buyer_id, r.party_flag, p.*,
                          row_number() OVER (PARTITION BY r.ocid, p.budget_project_id ORDER BY r.release_seq DESC) AS rn
                   FROM stg.planning p JOIN rel r USING (release_id)
                   WHERE p.budget_project_id IS NOT NULL) x
    WHERE rn = 1),
award_ok AS (SELECT * FROM latest_award
             WHERE status = 'active' AND award_value_flag IS NULL AND award_monetary_flag IS NULL),
line_count AS (SELECT ocid, count(*) AS n FROM latest_line GROUP BY ocid),
single_line AS (SELECT ocid FROM line_count WHERE n = 1),
c (check_id, check_name, severity, expected, actual) AS (VALUES
 -- Independent population recounts ------------------------------------------
 ('AV-01', 'M-P01 vw_budget_eligible = independent recount', 'GATE',
    (SELECT count(*) FROM latest_line WHERE budget_amount >= 0 AND budget_amount_flag IS NULL
        AND budget_monetary_flag IS NULL AND party_flag IS NULL AND buyer_id <> 'NG-BPP-')::text,
    (SELECT count(*) FROM analytics.vw_budget_eligible)::text),
 ('AV-02', 'M-C01/C02 primary population = independent recount', 'GATE',
    (SELECT count(*) FROM latest_tender WHERE status IS NOT NULL AND tenderer_count_flag = 'NORMAL')::text,
    (SELECT count(*) FROM analytics.vw_competition_eligible WHERE in_primary_population)::text),
 ('AV-03', 'M-C01 sensitivity population = independent recount', 'GATE',
    (SELECT count(*) FROM latest_tender WHERE status IS NOT NULL AND tenderer_count_flag IN ('NORMAL', 'ELEVATED'))::text,
    (SELECT count(*) FROM analytics.vw_competition_eligible)::text),
 ('AV-04', 'M-V01 vw_award_value_eligible = independent recount', 'GATE',
    (SELECT count(*) FROM award_ok)::text,
    (SELECT count(*) FROM analytics.vw_award_value_eligible)::text),
 ('AV-05', 'M-S01 eligible awards = independent recount (complete supplier ID)', 'GATE',
    (SELECT count(*) FROM award_ok a WHERE EXISTS (SELECT 1 FROM stg.award_suppliers s
                                                   WHERE s.award_id = a.award_id AND s.supplier_id <> 'NG-BPP-'))::text,
    (SELECT count(DISTINCT award_id) FROM analytics.vw_supplier_award_eligible)::text),
 ('AV-06', 'M-S01 one row per award (repeated suppliers[] collapsed, O-3)', 'GATE',
    (SELECT count(DISTINCT award_id) FROM analytics.vw_supplier_award_eligible)::text,
    (SELECT count(*) FROM analytics.vw_supplier_award_eligible)::text),
 ('AV-07', 'M-S01 max distinct suppliers per award (full-value attribution holds)', 'GATE', '1',
    (SELECT max(distinct_supplier_count) FROM analytics.vw_supplier_award_eligible)::text),
 ('AV-08', 'Budget-to-award comparison = independent recount', 'GATE',
    (SELECT count(*) FROM award_ok a JOIN single_line s USING (ocid) JOIN latest_line l USING (ocid)
      WHERE l.budget_amount > 0 AND l.budget_amount_flag IS NULL AND l.budget_monetary_flag IS NULL)::text,
    (SELECT count(*) FROM analytics.vw_budget_award_comparison)::text),
 ('AV-09', 'M-E01 tender duration = independent recount', 'GATE',
    (SELECT count(*) FROM latest_tender WHERE tender_start_date_flag = 'VALID' AND tender_end_date_flag = 'VALID'
        AND tender_end_date >= tender_start_date)::text,
    (SELECT count(*) FROM analytics.vw_tender_duration_eligible)::text),
 ('AV-10', 'M-E02 award lag = independent recount', 'GATE',
    (SELECT count(*) FROM latest_tender t JOIN latest_award a USING (ocid)
      WHERE t.tender_start_date_flag = 'VALID' AND a.award_date_flag = 'VALID' AND a.award_date >= t.tender_start_date)::text,
    (SELECT count(*) FROM analytics.vw_award_lag_eligible)::text),
 ('AV-11', 'Contract signature lag = independent recount', 'GATE',
    (SELECT count(*) FROM latest_award a JOIN stg.contracts c ON c.award_id = a.award_id
      WHERE a.award_date_flag = 'VALID' AND c.date_signed_flag = 'VALID' AND c.date_signed >= a.award_date)::text,
    (SELECT count(*) FROM analytics.vw_signature_lag_eligible)::text),
 ('AV-12', 'Negative durations in any timing view', 'GATE', '0',
    ((SELECT count(*) FROM analytics.vw_tender_duration_eligible WHERE tender_duration_days < 0)
   + (SELECT count(*) FROM analytics.vw_award_lag_eligible WHERE award_lag_days < 0)
   + (SELECT count(*) FROM analytics.vw_signature_lag_eligible WHERE signature_lag_days < 0))::text),
 ('AV-13', 'M-E03 rows = all OCIDs', 'GATE', '98866', (SELECT count(*) FROM analytics.vw_lifecycle_stage)::text),
 ('AV-14', 'M-I01 rows = one contract per OCID with a contract', 'GATE',
    (SELECT count(DISTINCT r.ocid) FROM stg.contracts c JOIN rel r USING (release_id))::text,
    (SELECT count(*) FROM analytics.vw_contract_implementation_coverage)::text),
 ('AV-15', 'Entity benchmark rows with an INCOMPLETE buyer (DQ-19)', 'GATE', '0',
    (SELECT count(*) FROM analytics.vw_entity_benchmark WHERE buyer_id = 'NG-BPP-')::text),
 ('AV-16', 'Entity benchmark: sum of process_count = OCIDs with a complete buyer', 'GATE',
    (SELECT count(*) FROM analytics.vw_lifecycle_stage WHERE buyer_id <> 'NG-BPP-')::text,
    (SELECT sum(process_count) FROM analytics.vw_entity_benchmark)::text),
 ('AV-17', 'Entity benchmark: sum of planned_budget_total = M-P01 total', 'GATE',
    (SELECT sum(budget_amount) FROM analytics.vw_budget_eligible)::text,
    (SELECT sum(planned_budget_total) FROM analytics.vw_entity_benchmark)::text),
 ('AV-18', 'Entity benchmark: sum of award_value_total = M-V01 total (complete buyers)', 'GATE',
    (SELECT sum(award_value_amount) FROM analytics.vw_award_value_eligible WHERE buyer_id_flag IS NULL)::text,
    (SELECT sum(award_value_total) FROM analytics.vw_entity_benchmark)::text),
 -- Spot checks on named records ---------------------------------------------
 ('SP-01', 'FCTA NGN 1.004T award (DQ-07 EXTREME) absent from M-V01 / M-S01', 'GATE', '0',
    ((SELECT count(*) FROM analytics.vw_award_value_eligible WHERE award_value_amount >= 1e12)
   + (SELECT count(*) FROM analytics.vw_supplier_award_eligible WHERE award_value_amount >= 1e12))::text),
 ('SP-02', 'ocds-gyl66f-521027024-000087: M-V01 uses latest correction (109,739,262.78)', 'GATE', '109739262.7800',
    (SELECT award_value_amount FROM analytics.vw_award_value_eligible WHERE ocid = 'ocds-gyl66f-521027024-000087')::text),
 ('SP-03', 'ocds-gyl66f-124004001-000772: M-S01 supplier is the named supplier, not placeholder ''1''', 'GATE', 'SADAMI GLOBAL PROJECTS LTD',
    (SELECT max(supplier_name) FROM analytics.vw_supplier_award_eligible WHERE ocid = 'ocds-gyl66f-124004001-000772')),
 ('SP-04', 'Placeholder date 2001-01-01 in any timing view', 'GATE', '0',
    ((SELECT count(*) FROM analytics.vw_tender_duration_eligible WHERE DATE '2001-01-01' IN (tender_start_date, tender_end_date))
   + (SELECT count(*) FROM analytics.vw_award_lag_eligible WHERE DATE '2001-01-01' IN (tender_start_date, award_date))
   + (SELECT count(*) FROM analytics.vw_signature_lag_eligible WHERE DATE '2001-01-01' IN (award_date, date_signed)))::text),
 ('SP-05', 'Bare NG-BPP- buyer in M-P01 budget view', 'GATE', '0',
    (SELECT count(*) FROM analytics.vw_budget_eligible WHERE buyer_id = 'NG-BPP-')::text),
 ('SP-06', 'Repeated-supplier awards (O-3, NG-BPP-62660) counted once each in M-S01', 'GATE', '0',
    (SELECT count(*) FROM (SELECT award_id FROM analytics.vw_supplier_award_eligible
                           WHERE supplier_id = 'NG-BPP-62660' GROUP BY award_id HAVING count(*) > 1) x)::text),
 -- Exclusion waterfalls and disclosures (INFO) -------------------------------
 ('WF-01', 'M-V01 excluded: snapshot award status not active', 'INFO', NULL,
    (SELECT count(*) FROM latest_award WHERE status IS DISTINCT FROM 'active')::text),
 ('WF-02', 'M-V01 excluded: active but EXTREME or ZERO_VALUE', 'INFO', NULL,
    (SELECT count(*) FROM latest_award WHERE status = 'active'
        AND (award_value_flag IS NOT NULL OR award_monetary_flag IS NOT NULL))::text),
 ('WF-03', 'M-S01 excluded: eligible awards with bare NG-BPP- supplier (count)', 'INFO', NULL,
    ((SELECT count(*) FROM analytics.vw_award_value_eligible)
   - (SELECT count(DISTINCT award_id) FROM analytics.vw_supplier_award_eligible))::text),
 ('WF-04', 'M-S01 excluded award value, NGN (unresolvable supplier identity)', 'INFO', NULL,
    ((SELECT sum(award_value_amount) FROM analytics.vw_award_value_eligible)
   - (SELECT sum(award_value_amount) FROM analytics.vw_supplier_award_eligible))::text),
 ('WF-05', 'M-S01 excluded share of M-V01 award value, %', 'INFO', NULL,
    (SELECT round(100 * (1 - (SELECT sum(award_value_amount) FROM analytics.vw_supplier_award_eligible)
                             / sum(award_value_amount)), 2) FROM analytics.vw_award_value_eligible)::text),
 ('WF-06a', 'Budget-to-award excluded: eligible award OCIDs with no budget line', 'INFO', NULL,
    (SELECT count(*) FROM award_ok a LEFT JOIN line_count l USING (ocid) WHERE l.ocid IS NULL)::text),
 ('WF-06b', 'Budget-to-award excluded: eligible award OCIDs with >1 budget line (MULTI_PROJECT)', 'INFO', NULL,
    (SELECT count(*) FROM award_ok a JOIN line_count l USING (ocid) WHERE l.n > 1)::text),
 ('WF-06c', 'Budget-to-award excluded: single budget line but zero or EXTREME budget', 'INFO', NULL,
    (SELECT count(*) FROM award_ok a JOIN single_line s USING (ocid) JOIN latest_line l USING (ocid)
      WHERE NOT (l.budget_amount > 0 AND l.budget_amount_flag IS NULL AND l.budget_monetary_flag IS NULL))::text),
 ('WF-07', 'M-E02 excluded: VALID dates but award before tender start', 'INFO', NULL,
    (SELECT count(*) FROM latest_tender t JOIN latest_award a USING (ocid)
      WHERE t.tender_start_date_flag = 'VALID' AND a.award_date_flag = 'VALID' AND a.award_date < t.tender_start_date)::text),
 ('WF-08', 'Signature lag excluded: VALID dates but signed before award', 'INFO', NULL,
    (SELECT count(*) FROM latest_award a JOIN stg.contracts c ON c.award_id = a.award_id
      WHERE a.award_date_flag = 'VALID' AND c.date_signed_flag = 'VALID' AND c.date_signed < a.award_date)::text),
 ('WF-09', 'M-C01 primary median tenderers (Phase 3 caveat states 2)', 'INFO', '2',
    (SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY number_of_tenderers)
       FROM analytics.vw_competition_eligible WHERE in_primary_population)::text),
 ('WF-10', 'M-E01 eligible tender releases with VALID start (Phase 3: ~9,593) vs eligible OCIDs', 'INFO', NULL,
    ((SELECT count(*) FROM stg.tender WHERE tender_start_date_flag = 'VALID')::text || ' releases / '
     || (SELECT count(*) FROM analytics.vw_tender_duration_eligible)::text || ' OCIDs'))
)
SELECT check_id, 'Analytical views (Phase 7)' AS check_group, check_name, severity, expected, actual,
       CASE WHEN severity = 'GATE' THEN expected = actual END AS passed
FROM c;
