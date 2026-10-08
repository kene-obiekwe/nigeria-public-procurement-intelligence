-- ============================================================
-- NOCOPO — Phase 8 validation: 10 Business-question outputs and DQ-impact view
-- ============================================================
-- Phase 8 exit gate: "every core business question has a reproducible SQL script
-- whose output has been spot-checked".
--
-- BQ-*:  headline figures used by the sql/06_analysis scripts are recomputed
--        directly from stg.* with an independent formulation (ROW_NUMBER latest
--        release, not the core snapshot views) and must match the analytics views
--        the scripts read.
-- DQI-*: analytics.vw_dq_impact reconciles to the metric populations and to
--        independently counted issue footprints.
-- DQ-20 (Phase 8.1): every independent recount first drops the portal test entity
--        NG-BPP-BPP-NOC-90 (literal ID; the views use core.dim_buyer.test_entity_flag).
-- ============================================================
WITH
rel AS (SELECT release_id, ocid, release_seq, buyer_id, party_flag, tag FROM stg.releases),
-- buyer of each process = buyer of its latest release
ob AS (SELECT DISTINCT ON (ocid) ocid, buyer_id FROM stg.releases ORDER BY ocid, release_seq DESC),
non_test  AS (SELECT ocid FROM ob WHERE buyer_id <> 'NG-BPP-BPP-NOC-90'),
test_ocid AS (SELECT ocid FROM ob WHERE buyer_id =  'NG-BPP-BPP-NOC-90'),
latest_tender AS (
    SELECT * FROM (SELECT r.ocid, t.*,
                          row_number() OVER (PARTITION BY r.ocid ORDER BY r.release_seq DESC) AS rn
                   FROM stg.tender t JOIN rel r USING (release_id)
                   JOIN non_test n ON n.ocid = r.ocid) x
    WHERE rn = 1),
latest_award AS (
    SELECT * FROM (SELECT r.ocid, a.*,
                          row_number() OVER (PARTITION BY r.ocid ORDER BY r.release_seq DESC) AS rn
                   FROM stg.awards a JOIN rel r USING (release_id)
                   JOIN non_test n ON n.ocid = r.ocid) x
    WHERE rn = 1),
latest_contract AS (
    SELECT * FROM (SELECT r.ocid, c.*,
                          row_number() OVER (PARTITION BY r.ocid ORDER BY r.release_seq DESC) AS rn
                   FROM stg.contracts c JOIN rel r USING (release_id)
                   JOIN non_test n ON n.ocid = r.ocid) x
    WHERE rn = 1),
latest_line AS (
    SELECT * FROM (SELECT r.ocid, r.party_flag, p.*,
                          row_number() OVER (PARTITION BY r.ocid, p.budget_project_id ORDER BY r.release_seq DESC) AS rn
                   FROM stg.planning p JOIN rel r USING (release_id)
                   WHERE p.budget_project_id IS NOT NULL
                     AND r.buyer_id <> 'NG-BPP-BPP-NOC-90') x
    WHERE rn = 1),
award_ok AS (SELECT * FROM latest_award
             WHERE status = 'active' AND award_value_flag IS NULL AND award_monetary_flag IS NULL),
line_count AS (SELECT ocid, count(*) AS n FROM latest_line GROUP BY ocid),
single_line AS (SELECT ocid FROM line_count WHERE n = 1),
-- M-S01: value per supplier, independent of the analytics view
complete_supplier AS (SELECT DISTINCT award_id, supplier_id FROM stg.award_suppliers WHERE supplier_id <> 'NG-BPP-'),
sup_val AS (
    SELECT s.supplier_id, sum(a.award_value_amount) AS v
    FROM award_ok a JOIN complete_supplier s USING (award_id)
    GROUP BY s.supplier_id),
view_sup_val AS (
    SELECT supplier_id, sum(award_value_amount) AS v
    FROM analytics.vw_supplier_award_eligible GROUP BY supplier_id),
-- Budget-to-award comparable set, independent
bva AS (
    SELECT a.award_value_amount AS award, l.budget_amount AS budget
    FROM award_ok a JOIN single_line s USING (ocid) JOIN latest_line l USING (ocid)
    WHERE l.budget_amount > 0 AND l.budget_amount_flag IS NULL AND l.budget_monetary_flag IS NULL),
-- Implementation coverage, independent (semi-joins through distinct contract lists)
tx_contract AS (SELECT DISTINCT contract_id FROM stg.transactions),
ms_contract AS (SELECT DISTINCT contract_id FROM stg.milestones WHERE milestone_source = 'IMPLEMENTATION'),
-- Materialised once: each of these views is expensive to evaluate
dq AS MATERIALIZED (SELECT * FROM analytics.vw_dq_impact),
reg AS MATERIALIZED (SELECT metric_id, candidate_count, eligible_count FROM analytics.vw_metric_population),
c (check_id, check_name, severity, expected, actual) AS (VALUES
 -- Business-question headline figures, recomputed independently ---------------
 ('BQ-01', 'BQ1 top supplier award value (M-S01), NGN', 'GATE',
    (SELECT max(v) FROM sup_val)::text,
    (SELECT max(v) FROM view_sup_val)::text),
 ('BQ-02', 'BQ1 distinct suppliers in scope (M-S01)', 'GATE',
    (SELECT count(*) FROM sup_val)::text,
    (SELECT count(*) FROM view_sup_val)::text),
 ('BQ-03', 'BQ1 value held by the ten largest suppliers (M-S01), NGN', 'GATE',
    (SELECT sum(v) FROM (SELECT v FROM sup_val ORDER BY v DESC LIMIT 10) x)::text,
    (SELECT sum(v) FROM (SELECT v FROM view_sup_val ORDER BY v DESC LIMIT 10) x)::text),
 ('BQ-04', 'BQ2 median tenderers, primary population (M-C01)', 'GATE',
    (SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY number_of_tenderers)
       FROM latest_tender WHERE status IS NOT NULL AND tenderer_count_flag = 'NORMAL')::text,
    (SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY number_of_tenderers)
       FROM analytics.vw_competition_eligible WHERE in_primary_population)::text),
 ('BQ-05', 'BQ2 single-bidder tenders, primary population (M-C02 numerator)', 'GATE',
    (SELECT count(*) FROM latest_tender
      WHERE status IS NOT NULL AND tenderer_count_flag = 'NORMAL' AND number_of_tenderers = 1)::text,
    (SELECT count(*) FROM analytics.vw_competition_eligible WHERE in_primary_population AND is_single_bidder)::text),
 ('BQ-06', 'BQ3 total budget of comparable OCIDs, NGN', 'GATE',
    (SELECT sum(budget) FROM bva)::text,
    (SELECT sum(budget_amount) FROM analytics.vw_budget_award_comparison)::text),
 ('BQ-07', 'BQ3 total award value of comparable OCIDs, NGN', 'GATE',
    (SELECT sum(award) FROM bva)::text,
    (SELECT sum(award_value_amount) FROM analytics.vw_budget_award_comparison)::text),
 ('BQ-08', 'BQ3 median award-to-budget ratio', 'GATE',
    (SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY round(award / budget, 4)) FROM bva)::text,
    (SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY award_to_budget_ratio)
       FROM analytics.vw_budget_award_comparison)::text),
 ('BQ-09', 'BQ4 median tender open duration, days (M-E01)', 'GATE',
    (SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY tender_end_date - tender_start_date)
       FROM latest_tender
      WHERE tender_start_date_flag = 'VALID' AND tender_end_date_flag = 'VALID'
        AND tender_end_date >= tender_start_date)::text,
    (SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY tender_duration_days)
       FROM analytics.vw_tender_duration_eligible)::text),
 ('BQ-10', 'BQ4 median award lag, days (M-E02)', 'GATE',
    (SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY a.award_date - t.tender_start_date)
       FROM latest_tender t JOIN latest_award a USING (ocid)
      WHERE t.tender_start_date_flag = 'VALID' AND a.award_date_flag = 'VALID'
        AND a.award_date >= t.tender_start_date)::text,
    (SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY award_lag_days)
       FROM analytics.vw_award_lag_eligible)::text),
 ('BQ-11', 'BQ4 median signature lag, days', 'GATE',
    (SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY c2.date_signed - a.award_date)
       FROM latest_award a JOIN stg.contracts c2 ON c2.award_id = a.award_id
      WHERE a.award_date_flag = 'VALID' AND c2.date_signed_flag = 'VALID'
        AND c2.date_signed >= a.award_date)::text,
    (SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY signature_lag_days)
       FROM analytics.vw_signature_lag_eligible)::text),
 ('BQ-12', 'BQ6 contracts with implementation data (M-I01 numerator)', 'GATE',
    (SELECT count(*) FROM latest_contract lc
       LEFT JOIN tx_contract tx ON tx.contract_id = lc.contract_id
       LEFT JOIN ms_contract ms ON ms.contract_id = lc.contract_id
      WHERE tx.contract_id IS NOT NULL OR ms.contract_id IS NOT NULL)::text,
    (SELECT count(*) FROM analytics.vw_contract_implementation_coverage WHERE has_implementation)::text),
 ('BQ-13', 'BQ6 OCIDs with an implementation-tagged release (M-E03 stage 5)', 'GATE',
    (SELECT count(DISTINCT ocid) FROM rel WHERE 'implementation' = ANY (tag)
        AND ocid IN (SELECT ocid FROM non_test))::text,
    (SELECT count(*) FROM analytics.vw_lifecycle_stage WHERE highest_stage_rank = 5)::text),
 ('BQ-14', 'BQ6 OCIDs reaching contract stage or beyond (M-E03)', 'GATE',
    (SELECT count(DISTINCT ocid) FROM rel WHERE tag && ARRAY['contract', 'implementation']::text[]
        AND ocid IN (SELECT ocid FROM non_test))::text,
    (SELECT count(*) FROM analytics.vw_lifecycle_stage WHERE highest_stage_rank >= 4)::text),
 -- Data-quality impact view (BQ7) ------------------------------------------------
 ('DQI-01', 'DQ impact: metrics where excluded records <> candidate - eligible', 'GATE', '0',
    (SELECT count(*) FROM dq WHERE dq_ref = 'ALL' AND records_with_issue <> candidate_records - eligible_records)::text),
 ('DQI-02', 'DQ impact: metrics whose candidate or eligible count differs from vw_metric_population', 'GATE', '0',
    (SELECT count(*) FROM dq JOIN reg USING (metric_id)
      WHERE dq.dq_ref = 'ALL'
        AND (dq.candidate_records <> reg.candidate_count OR dq.eligible_records <> reg.eligible_count))::text),
 ('DQI-03', 'DQ impact: metrics in the view that are absent from vw_metric_population', 'GATE', '0',
    (SELECT count(*) FROM dq LEFT JOIN reg USING (metric_id)
      WHERE dq.dq_ref = 'ALL' AND reg.metric_id IS NULL)::text),
 ('DQI-04', 'DQ impact: DQ-05 records (snapshot tenders > 1,000 tenderers) = independent count', 'GATE',
    (SELECT count(*) FROM latest_tender WHERE tenderer_count_flag = 'ANOMALOUS')::text,
    (SELECT records_with_issue FROM dq WHERE metric_id = 'M-C01 / M-C02' AND dq_ref = 'DQ-05')::text),
 ('DQI-05', 'DQ impact: DQ-04 records (101-1,000 tenderers) = independent count', 'GATE',
    (SELECT count(*) FROM latest_tender WHERE tenderer_count_flag = 'ELEVATED')::text,
    (SELECT records_with_issue FROM dq WHERE metric_id = 'M-C01 / M-C02' AND dq_ref = 'DQ-04')::text),
 ('DQI-06', 'DQ impact: DQ-07 records (extreme award value) = independent count', 'GATE',
    (SELECT count(*) FROM latest_award WHERE award_value_flag IS NOT NULL)::text,
    (SELECT records_with_issue FROM dq WHERE metric_id = 'M-V01' AND dq_ref = 'DQ-07')::text),
 ('DQI-07', 'DQ impact: DQ-06 budget lines (extreme budget) = independent count', 'GATE',
    (SELECT count(*) FROM latest_line WHERE budget_amount_flag IS NOT NULL)::text,
    (SELECT records_with_issue FROM dq WHERE metric_id = 'M-P01' AND dq_ref = 'DQ-06')::text),
 ('DQI-08', 'DQ impact: DQ-14 awards (no usable supplier ID) = independent count', 'GATE',
    (SELECT count(*) FROM award_ok a LEFT JOIN (SELECT DISTINCT award_id FROM complete_supplier) cs USING (award_id)
      WHERE cs.award_id IS NULL)::text,
    (SELECT records_with_issue FROM dq WHERE metric_id = 'M-S01' AND dq_ref = 'DQ-14')::text),
 ('DQI-09', 'DQ impact: DQ-14 excluded award value, NGN = independent sum', 'GATE',
    (SELECT sum(a.award_value_amount) FROM award_ok a LEFT JOIN (SELECT DISTINCT award_id FROM complete_supplier) cs USING (award_id)
      WHERE cs.award_id IS NULL)::text,
    (SELECT affected_value_ngn FROM dq WHERE metric_id = 'M-S01' AND dq_ref = 'DQ-14')::text),
 ('DQI-10', 'DQ impact: M-E02 DATE-ORDER records = Phase 7 award-before-tender count (WF-07)', 'GATE',
    (SELECT count(*) FROM latest_tender t JOIN latest_award a USING (ocid)
      WHERE t.tender_start_date_flag = 'VALID' AND a.award_date_flag = 'VALID'
        AND a.award_date < t.tender_start_date)::text,
    (SELECT records_with_issue FROM dq WHERE metric_id = 'M-E02' AND dq_ref = 'DATE-ORDER')::text),
 ('DQI-11', 'DQ impact: P5-SIG DATE-ORDER records = Phase 7 signed-before-award count (WF-08)', 'GATE',
    (SELECT count(*) FROM latest_award a JOIN stg.contracts c2 ON c2.award_id = a.award_id
      WHERE a.award_date_flag = 'VALID' AND c2.date_signed_flag = 'VALID'
        AND c2.date_signed < a.award_date)::text,
    (SELECT records_with_issue FROM dq WHERE metric_id = 'P5-SIG' AND dq_ref = 'DATE-ORDER')::text),
 ('DQI-12', 'DQ impact: metrics where single-cause losses exceed excluded records', 'GATE', '0',
    (SELECT count(*) FROM (
        SELECT metric_id,
               coalesce(sum(records_lost_only_to_issue) FILTER (WHERE impact_type IN ('EXCLUDES', 'EXCLUDES_FROM_PRIMARY')), 0)
             + coalesce(max(records_lost_only_to_issue) FILTER (WHERE dq_ref = 'OTHER'), 0) AS single_cause,
               max(records_with_issue) FILTER (WHERE dq_ref = 'ALL') AS excluded
        FROM dq GROUP BY metric_id) x
      WHERE x.excluded IS NOT NULL AND x.single_cause > x.excluded)::text),
 ('DQI-13', 'DQ impact: rows where records_with_issue > candidate_records', 'GATE', '0',
    (SELECT count(*) FROM dq WHERE records_with_issue > candidate_records)::text),
 ('DQI-16', 'DQ impact: DQ-20 pre-excluded snapshot awards (M-V01) = independent count', 'GATE',
    (SELECT count(DISTINCT r.ocid) FROM stg.awards a JOIN stg.releases r USING (release_id)
       JOIN test_ocid USING (ocid))::text,
    (SELECT records_with_issue FROM dq WHERE metric_id = 'M-V01' AND dq_ref = 'DQ-20')::text),
 ('DQI-17', 'DQ impact: DQ-20 pre-excluded snapshot tenders (M-C01/C02) = independent count', 'GATE',
    (SELECT count(DISTINCT r.ocid) FROM stg.tender t JOIN stg.releases r USING (release_id)
       JOIN test_ocid USING (ocid))::text,
    (SELECT records_with_issue FROM dq WHERE metric_id = 'M-C01 / M-C02' AND dq_ref = 'DQ-20')::text),
 ('DQI-18', 'DQ impact: DQ-20 pre-excluded budget lines (M-P01) = independent count', 'GATE',
    (SELECT count(*) FROM (SELECT DISTINCT r.ocid, p.budget_project_id FROM stg.planning p
                           JOIN stg.releases r USING (release_id)
                           WHERE p.budget_project_id IS NOT NULL AND r.buyer_id = 'NG-BPP-BPP-NOC-90') x)::text,
    (SELECT records_with_issue FROM dq WHERE metric_id = 'M-P01' AND dq_ref = 'DQ-20')::text),
 ('DQI-19', 'DQ impact: DQ-20 pre-excluded buyer IDs (ENTITY)', 'GATE', '1',
    (SELECT records_with_issue FROM dq WHERE metric_id = 'ENTITY' AND dq_ref = 'DQ-20')::text),
 ('DQI-14', 'DQ impact: M-S01 excluded share of M-V01 award value, % (matches WF-05 disclosure)', 'INFO', NULL,
    (SELECT round(100 * d.affected_value_ngn / (d.eligible_value_ngn + d.affected_value_ngn), 2)
       FROM dq d WHERE d.metric_id = 'M-S01' AND d.dq_ref = 'ALL')::text),
 ('DQI-15', 'DQ impact: rows in the view', 'INFO', NULL, (SELECT count(*) FROM dq)::text)
)
SELECT check_id, 'Business questions (Phase 8)' AS check_group, check_name, severity, expected, actual,
       CASE WHEN severity = 'GATE' THEN expected = actual END AS passed
FROM c;
