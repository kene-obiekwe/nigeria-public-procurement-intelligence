-- ============================================================
-- NOCOPO — Phase 8 analytical view: data-quality impact on metrics (business question 7)
-- ============================================================
-- Spec:   Scope business question 7 ("Which data-quality issues could materially
--         affect the interpretation of procurement metrics?"); decision log
--         DQ-01 to DQ-19; phase3_metric_eligibility.md v1.2.
-- Decision: Kene, 2026-10-08, option 1 for BQ7 (add this view instead of letting
--         the analysis script read stg/core).
-- Grain:  one row per (metric, data-quality issue). Plus one SUMMARY row per
--         metric for the union of all exclusion reasons.
--
-- WHY THIS VIEW READS core.* AND stg.*
--   The other analytics views hold only ELIGIBLE records, so they cannot show
--   which issue removed a record. This view re-derives, for each metric's
--   CANDIDATE population, which DQ rules a record trips. It is the one analytics
--   view built to look at the excluded side. The BQ7 script then reads only
--   analytics.vw_dq_impact (Phase 8 rule: scripts query analytics.* only).
--
-- THE TWO COUNTS PER ROW
--   records_with_issue          candidates that trip this issue. Issues overlap,
--                               so these counts are NOT additive across issues.
--   records_lost_only_to_issue  candidates removed from the metric by this issue
--                               and nothing else. These ARE additive: summed with
--                               the overlap records they explain the SUMMARY row.
--   candidate - eligible = SUMMARY.records_with_issue (checked in the Phase 8
--   validation suite). Eligible counts come from the analytics views themselves,
--   so the attribution here is tested against the eligibility rules, not
--   assumed to match them.
--
-- impact_type
--   EXCLUDES              record is removed from the metric
--   EXCLUDES_FROM_PRIMARY removed from the primary result, kept in a sensitivity
--                         population (DQ-04 only)
--   DISCLOSED             record is kept; the issue limits how the metric may be read
--   SUMMARY               union across issues (SUMMARY_ALL), or the non-DQ rules
--                         (SUMMARY_OTHER: status, missing values)
-- Missing dates and missing values carry no DQ number; they appear under dq_ref
-- 'OTHER' so the exclusion total reconciles.
-- Value columns are NGN and only filled for monetary metrics; a record's whole
-- value is attributed to each issue it trips (overlapping, like the counts).
-- ============================================================
CREATE OR REPLACE VIEW analytics.vw_dq_impact AS
WITH
-- ---- Candidate records with the DQ rules they trip -------------------------
rec AS MATERIALIZED (
    -- M-P01: budget lines (core.vw_budget_lines = latest release per line)
    SELECT 'M-P01'::text AS metric_id,
           b.budget_amount AS val,
           array_remove(ARRAY[
               CASE WHEN b.budget_amount_flag   IS NOT NULL THEN 'DQ-06' END,
               CASE WHEN b.budget_monetary_flag IS NOT NULL THEN 'DQ-16' END,
               CASE WHEN r.party_flag           IS NOT NULL THEN 'DQ-18' END,
               CASE WHEN d.buyer_id_flag        IS NOT NULL THEN 'DQ-19' END], NULL) AS issues,
           (b.budget_amount IS NULL OR b.budget_amount < 0) AS other_reason
    FROM core.vw_budget_lines b
    JOIN stg.releases r ON r.release_id = b.release_id
    JOIN core.dim_buyer d ON d.buyer_id = b.buyer_id

    UNION ALL
    -- M-C01 / M-C02 (primary): snapshot tenders
    SELECT 'M-C01 / M-C02', NULL::numeric,
           array_remove(ARRAY[
               CASE WHEN t.tenderer_count_flag = 'ELEVATED'  THEN 'DQ-04' END,
               CASE WHEN t.tenderer_count_flag = 'ANOMALOUS' THEN 'DQ-05' END], NULL),
           (t.status IS NULL)
    FROM core.vw_process_snapshot s
    JOIN stg.tender t ON t.release_id = s.tender_release_id

    UNION ALL
    -- M-V01: snapshot awards
    SELECT 'M-V01', a.award_value_amount,
           array_remove(ARRAY[
               CASE WHEN a.award_value_flag    IS NOT NULL THEN 'DQ-07' END,
               CASE WHEN a.award_monetary_flag IS NOT NULL THEN 'DQ-16' END], NULL),
           (a.status IS DISTINCT FROM 'active')
    FROM core.vw_process_snapshot s
    JOIN stg.awards a ON a.award_id = s.award_id

    UNION ALL
    -- M-S01: M-V01-eligible awards, tested for a usable supplier ID
    SELECT 'M-S01', v.award_value_amount,
           array_remove(ARRAY[
               CASE WHEN NOT coalesce(sp.has_complete, false) AND coalesce(sp.has_bare, false)
                    THEN 'DQ-14' END], NULL),
           (NOT coalesce(sp.has_complete, false) AND NOT coalesce(sp.has_bare, false))
    FROM analytics.vw_award_value_eligible v
    LEFT JOIN (SELECT x.award_id,
                      bool_or(sup.supplier_id_flag IS NULL)     AS has_complete,
                      bool_or(sup.supplier_id_flag IS NOT NULL) AS has_bare
               FROM (SELECT DISTINCT award_id, supplier_id FROM stg.award_suppliers) x
               JOIN core.dim_supplier sup ON sup.supplier_id = x.supplier_id
               GROUP BY x.award_id) sp ON sp.award_id = v.award_id

    UNION ALL
    -- P4-BvA: M-V01-eligible awards, tested for one valid budget line (I-1, I-2)
    SELECT 'P4-BvA', v.award_value_amount,
           array_remove(ARRAY[
               CASE WHEN s.budget_line_count > 1                          THEN 'C-06' END,
               CASE WHEN s.budget_line_count = 1 AND b.budget_amount_flag   IS NOT NULL THEN 'DQ-06' END,
               CASE WHEN s.budget_line_count = 1 AND b.budget_monetary_flag IS NOT NULL THEN 'DQ-16' END], NULL),
           (s.budget_line_count = 0
            OR (s.budget_line_count = 1 AND (b.budget_amount IS NULL OR b.budget_amount <= 0)
                AND b.budget_amount_flag IS NULL AND b.budget_monetary_flag IS NULL))
    FROM analytics.vw_award_value_eligible v
    JOIN core.vw_process_snapshot s ON s.ocid = v.ocid
    LEFT JOIN core.vw_budget_lines b ON b.ocid = v.ocid AND s.budget_line_count = 1

    UNION ALL
    -- M-E01: snapshot tenders, tender open duration
    SELECT 'M-E01', NULL::numeric,
           array_remove(ARRAY[
               CASE WHEN 'PLACEHOLDER' IN (t.tender_start_date_flag, t.tender_end_date_flag) THEN 'DQ-08' END,
               CASE WHEN t.tender_start_date_flag IN ('FUTURE', 'IMPOSSIBLE')
                      OR t.tender_end_date_flag   IN ('FUTURE', 'IMPOSSIBLE')               THEN 'DQ-09' END,
               CASE WHEN t.tender_start_date_flag = 'VALID' AND t.tender_end_date_flag = 'VALID'
                     AND t.tender_end_date < t.tender_start_date                            THEN 'DATE-ORDER' END], NULL),
           (t.tender_start_date_flag IS NULL OR t.tender_end_date_flag IS NULL)
    FROM core.vw_process_snapshot s
    JOIN stg.tender t ON t.release_id = s.tender_release_id

    UNION ALL
    -- M-E02: snapshot OCIDs with a tender and an award, award lag
    SELECT 'M-E02', NULL::numeric,
           array_remove(ARRAY[
               CASE WHEN 'PLACEHOLDER' IN (t.tender_start_date_flag, a.award_date_flag) THEN 'DQ-08' END,
               CASE WHEN t.tender_start_date_flag IN ('FUTURE', 'IMPOSSIBLE')
                      OR a.award_date_flag        IN ('FUTURE', 'IMPOSSIBLE')           THEN 'DQ-09' END,
               CASE WHEN t.tender_start_date_flag = 'VALID' AND a.award_date_flag = 'VALID'
                     AND a.award_date < t.tender_start_date                             THEN 'DATE-ORDER' END], NULL),
           (t.tender_start_date_flag IS NULL OR a.award_date_flag IS NULL)
    FROM core.vw_process_snapshot s
    JOIN stg.tender t ON t.release_id = s.tender_release_id
    JOIN stg.awards a ON a.award_id   = s.award_id

    UNION ALL
    -- P5-SIG: snapshot contracts, award -> signature lag
    SELECT 'P5-SIG', NULL::numeric,
           array_remove(ARRAY[
               CASE WHEN 'PLACEHOLDER' IN (a.award_date_flag, c.date_signed_flag) THEN 'DQ-08' END,
               CASE WHEN a.award_date_flag  IN ('FUTURE', 'IMPOSSIBLE')
                      OR c.date_signed_flag IN ('FUTURE', 'IMPOSSIBLE')             THEN 'DQ-09' END,
               CASE WHEN a.award_date_flag = 'VALID' AND c.date_signed_flag = 'VALID'
                     AND c.date_signed < a.award_date                               THEN 'DATE-ORDER' END], NULL),
           (a.award_date_flag IS NULL OR c.date_signed_flag IS NULL)
    FROM core.vw_process_snapshot s
    JOIN stg.contracts c ON c.contract_id = s.contract_id
    LEFT JOIN stg.awards a ON a.award_id  = s.award_id

    UNION ALL
    -- ENTITY: buyer IDs
    SELECT 'ENTITY', NULL::numeric,
           array_remove(ARRAY[CASE WHEN d.buyer_id_flag IS NOT NULL THEN 'DQ-19' END], NULL),
           false
    FROM core.dim_buyer d
),

-- ---- Aggregates ------------------------------------------------------------
hit AS (
    SELECT r.metric_id, i.dq_ref,
           count(*)                                                              AS records_with_issue,
           count(*) FILTER (WHERE cardinality(r.issues) = 1 AND NOT r.other_reason) AS records_lost_only_to_issue,
           sum(r.val)                                                            AS affected_value_ngn
    FROM rec r
    CROSS JOIN LATERAL unnest(r.issues) AS i(dq_ref)
    GROUP BY r.metric_id, i.dq_ref
),
tot AS (
    SELECT metric_id,
           count(*)                                                                    AS candidate_records,
           count(*) FILTER (WHERE cardinality(issues) > 0 OR other_reason)             AS excluded_records,
           sum(val) FILTER (WHERE cardinality(issues) > 0 OR other_reason)             AS excluded_value_ngn,
           count(*) FILTER (WHERE other_reason)                                        AS other_records,
           count(*) FILTER (WHERE other_reason AND cardinality(issues) = 0)            AS other_only_records,
           sum(val) FILTER (WHERE other_reason)                                        AS other_value_ngn
    FROM rec
    GROUP BY metric_id
),

-- ---- Eligible populations, taken from the analytics views -------------------
elig AS MATERIALIZED (
    SELECT 'M-P01' AS metric_id, count(*) AS eligible_records, sum(budget_amount) AS eligible_value_ngn
    FROM analytics.vw_budget_eligible
    UNION ALL
    SELECT 'M-C01 / M-C02', count(*), NULL::numeric
    FROM analytics.vw_competition_eligible WHERE in_primary_population
    UNION ALL
    SELECT 'M-V01', count(*), sum(award_value_amount) FROM analytics.vw_award_value_eligible
    UNION ALL
    SELECT 'M-S01', count(DISTINCT award_id), sum(award_value_amount) FROM analytics.vw_supplier_award_eligible
    UNION ALL
    SELECT 'P4-BvA', count(*), sum(award_value_amount) FROM analytics.vw_budget_award_comparison
    UNION ALL
    SELECT 'M-E01', count(*), NULL::numeric FROM analytics.vw_tender_duration_eligible
    UNION ALL
    SELECT 'M-E02', count(*), NULL::numeric FROM analytics.vw_award_lag_eligible
    UNION ALL
    SELECT 'P5-SIG', count(*), NULL::numeric FROM analytics.vw_signature_lag_eligible
    UNION ALL
    SELECT 'ENTITY', count(*), NULL::numeric FROM analytics.vw_entity_benchmark
),

-- ---- Reference tables -------------------------------------------------------
meta (metric_id, metric_order, metric_name, grain) AS (VALUES
    ('ALL',            0,  'All OCID-level metrics (process snapshot)',   'OCID'),
    ('M-P01',          1,  'Total planned budget by entity',              'budget line'),
    ('M-C01 / M-C02',  2,  'Median tenderers; single-bidder rate (primary)', 'OCID'),
    ('M-V01',          3,  'Median award value',                          'OCID (one award)'),
    ('M-S01',          4,  'Top-supplier award value concentration',      'award'),
    ('P4-BvA',         5,  'Budget-to-award comparison',                  'OCID'),
    ('M-E01',          6,  'Median tender duration (days)',               'OCID'),
    ('M-E02',          7,  'Median award lag (days)',                     'OCID'),
    ('P5-SIG',         8,  'Contract signature lag (days)',               'contract'),
    ('M-E03',          9,  'Lifecycle conversion',                        'OCID'),
    ('M-I01',          10, 'Implementation reporting coverage',           'contract'),
    ('ENTITY',         11, 'Procuring-entity benchmark',                  'buyer')
),
issue (dq_ref, dq_issue, treatment, note) AS (VALUES
    ('DQ-01', 'Repeated OCIDs (multi-release processes)', 'RETAIN',
        'Not excluded. The process snapshot (Phase 4 v1.1) takes the latest release per section, so values are not double-counted.'),
    ('DQ-02', 'Planning-only processes', 'RETAIN',
        'Not excluded. Most processes were published only at planning stage, so later-stage metrics describe a small share of all OCIDs.'),
    ('DQ-04', 'Elevated tenderer count (101-1,000)', 'FLAG',
        'Excluded from the primary result; kept in the sensitivity population (M-C01).'),
    ('DQ-05', 'Anomalous tenderer count (>1,000)', 'EXCLUDE_FROM_METRIC',
        'Excluded from primary and sensitivity populations.'),
    ('DQ-06', 'Extreme budget (>= NGN 1 trillion)', 'EXCLUDE_FROM_METRIC',
        'Retained in core and flagged; value would dominate any total or ratio.'),
    ('DQ-07', 'Extreme award value (FCTA NGN 1.004T)', 'EXCLUDE_FROM_METRIC',
        'Retained in core and flagged; value would dominate any total or median.'),
    ('DQ-08', 'Placeholder date (2001-01-01)', 'EXCLUDE_FROM_METRIC',
        'Excluded from the timing metric that needs the date.'),
    ('DQ-09', 'Future or impossible date (e.g. year 2922)', 'EXCLUDE_FROM_METRIC',
        'Excluded from the timing metric that needs the date.'),
    ('DQ-11', 'Implementation transaction dates absent', 'RETAIN',
        'Transactions are used for presence only; payment timing cannot be measured.'),
    ('DQ-12', 'Implementation transaction value semantics unclear', 'RETAIN',
        'Transaction values are not summed; the field meaning is unresolved.'),
    ('DQ-13', 'Supplier ID with several name variants', 'RETAIN',
        'Not merged. Supplier concentration is a lower bound where one real supplier carries several IDs (DQ-14, DQ-15).'),
    ('DQ-14', 'Incomplete supplier ID (bare NG-BPP-)', 'EXCLUDE_FROM_METRIC',
        'Supplier identity cannot be resolved, so the award is left out of supplier concentration. State this with every M-S01 figure.'),
    ('DQ-16', 'Zero monetary value', 'EXCLUDE_FROM_METRIC',
        'Zero is treated as unusable for value metrics, not as a real amount of nothing.'),
    ('DQ-18', 'Release with no parties array', 'EXCLUDE_FROM_METRIC',
        'Buyer cannot be derived, so the line is left out of buyer-level budget totals.'),
    ('DQ-19', 'Incomplete buyer ID (bare NG-BPP-)', 'EXCLUDE_FROM_METRIC',
        'Excluded from per-entity measures; kept in overall process counts.'),
    ('C-06',  'Several unrelated budget lines on one OCID (MULTI_PROJECT)', 'EXCLUDE_FROM_METRIC',
        'Kene I-2: no rule says which budget line an award answers, so the OCID is left out of budget-to-award.'),
    ('DATE-ORDER', 'Date chronology conflict (end before start)', 'EXCLUDE_FROM_METRIC',
        'No DQ number. Negative durations are excluded, not corrected (Kene decision, Phase 7).'),
    ('OTHER', 'Other eligibility rule (status, missing value, missing date, no budget line)', 'EXCLUDE_FROM_METRIC',
        'Not a numbered DQ issue. Missing values are never imputed (cleaning plan, missing-value rules).')
),

-- ---- Disclosure rows: issues that keep the record but limit interpretation ---
disc (metric_id, dq_ref, candidate_records, eligible_records, records_with_issue, affected_value_ngn, eligible_value_ngn) AS (
    SELECT 'ALL', 'DQ-01',
           count(*), count(*), count(*) FILTER (WHERE release_count > 1), NULL::numeric, NULL::numeric
    FROM core.vw_process_snapshot
    UNION ALL
    SELECT 'M-E03', 'DQ-02',
           count(*), count(*), count(*) FILTER (WHERE highest_stage_rank = 1), NULL, NULL
    FROM analytics.vw_lifecycle_stage
    UNION ALL
    SELECT 'M-S01', 'DQ-13',
           count(*), count(*), count(*) FILTER (WHERE name_variant_count > 1),
           sum(award_value_amount) FILTER (WHERE name_variant_count > 1), sum(award_value_amount)
    FROM analytics.vw_supplier_award_eligible
    UNION ALL
    SELECT 'M-I01', d.dq_ref,
           count(*), count(*), count(*) FILTER (WHERE transaction_count > 0), NULL, NULL
    FROM analytics.vw_contract_implementation_coverage
    CROSS JOIN (VALUES ('DQ-11'), ('DQ-12')) AS d(dq_ref)
    GROUP BY d.dq_ref
),

-- ---- Final assembly ----------------------------------------------------------
final AS (
    -- (metric, numbered or named issue)
    SELECT h.metric_id, h.dq_ref,
           CASE WHEN h.dq_ref = 'DQ-04' THEN 'EXCLUDES_FROM_PRIMARY' ELSE 'EXCLUDES' END AS impact_type,
           t.candidate_records, e.eligible_records,
           h.records_with_issue, h.records_lost_only_to_issue,
           h.affected_value_ngn, e.eligible_value_ngn
    FROM hit h
    JOIN tot  t USING (metric_id)
    JOIN elig e USING (metric_id)

    UNION ALL
    -- non-DQ rules (status, missing values, missing dates)
    SELECT t.metric_id, 'OTHER', 'SUMMARY_OTHER',
           t.candidate_records, e.eligible_records,
           t.other_records, t.other_only_records, t.other_value_ngn, e.eligible_value_ngn
    FROM tot t
    JOIN elig e USING (metric_id)
    WHERE t.other_records > 0

    UNION ALL
    -- union of all reasons: candidate - eligible
    SELECT t.metric_id, 'ALL', 'SUMMARY_ALL',
           t.candidate_records, e.eligible_records,
           t.excluded_records, NULL::bigint, t.excluded_value_ngn, e.eligible_value_ngn
    FROM tot t
    JOIN elig e USING (metric_id)

    UNION ALL
    SELECT metric_id, dq_ref, 'DISCLOSED', candidate_records, eligible_records,
           records_with_issue, NULL::bigint, affected_value_ngn, eligible_value_ngn
    FROM disc
)
SELECT m.metric_order,
       f.metric_id,
       m.metric_name,
       m.grain,
       f.dq_ref,
       CASE WHEN f.dq_ref = 'ALL' THEN 'All exclusion reasons combined (candidate minus eligible)'
            ELSE i.dq_issue END                                  AS dq_issue,
       CASE WHEN f.dq_ref = 'ALL' THEN NULL ELSE i.treatment END AS treatment,
       f.impact_type,
       f.candidate_records,
       f.eligible_records,
       f.records_with_issue,
       f.records_lost_only_to_issue,
       round(100.0 * f.records_with_issue / nullif(f.candidate_records, 0), 2) AS pct_of_candidate,
       f.affected_value_ngn,
       f.eligible_value_ngn,
       i.note
FROM final f
JOIN meta  m USING (metric_id)
LEFT JOIN issue i USING (dq_ref);

COMMENT ON VIEW analytics.vw_dq_impact IS
    'Business question 7: per metric and data-quality issue, how many candidate records trip the '
    'issue (overlapping) and how many are lost to it alone (additive). SUMMARY_ALL = candidate minus '
    'eligible. DISCLOSED rows are retained records whose interpretation is limited. Reads core/stg '
    'to see the excluded side; eligible counts come from the analytics views.';
