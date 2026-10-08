-- ============================================================
-- NOCOPO — Phase 8, business question 7: data-quality impact on metrics
-- ============================================================
-- Question: Which data-quality issues could materially affect the
--           interpretation of procurement metrics?  (Scope s.6)
-- Source:   analytics.vw_dq_impact (sql/05_views/09_dq_impact.sql; Kene option 1,
--           2026-10-08). The view attributes each exclusion to the data-quality
--           issue that caused it, which the eligible-only analytics views cannot
--           show. This script reads only that view.
-- Run:      psql -h localhost -p 5433 -U postgres -d nocopo_db -f sql/06_analysis/07_data_quality_impact.sql
--           (each result set reads the view, which takes about 50 s)
--
-- HOW TO READ THE COUNTS
--   records_with_issue          candidate records that trip the issue. Issues
--                               overlap, so these are NOT additive across issues.
--   records_lost_only_to_issue  records removed by this issue and nothing else.
--                               These ARE additive; with the overlap records they
--                               explain candidate minus eligible exactly (RS1).
--   value_pct_of_candidate      affected NGN as a share of the metric's candidate
--                               value (eligible value + all excluded value). It can
--                               be large when a few extreme records are involved.
--
-- MATERIALITY (an analyst's reading rule, not a project rule)
--   HIGH      the issue touches at least 10% of candidate records or candidate value
--   MODERATE  at least 1%
--   LOW       under 1%
--   The thresholds are parameters in the `params` CTE of RS2 and RS3. Materiality
--   says how much of a metric an issue can move or limit; it does not say the
--   issue has been fixed or that the data are wrong.
--
-- LIMITATIONS
--   1. Counts are for the pinned source file (SHA-256 6151466...bc90c, published
--      2021-05-03) and its process snapshot.
--   2. DISCLOSED rows are not exclusions: the records stay in the metric and the
--      issue limits how it can be read (e.g. DQ-13: concentration is a lower bound).
--   3. 'OTHER' covers eligibility rules that are not numbered DQ issues (award
--      status, missing values, missing dates, no budget line). Missing values are
--      never imputed.
--   4. Issues DQ-03, DQ-10, DQ-15 and DQ-17 leave no record-level footprint in a
--      metric population (normal range, a definition, specifications, an
--      unconfirmed uniformity). They are described in the decision log and not
--      counted here.
-- ============================================================

-- [RS1] Exclusions by metric: candidate, eligible, and how the excluded records divide by cause
SELECT metric_order, metric_id, metric_name,
       max(candidate_records) FILTER (WHERE dq_ref = 'ALL')                              AS candidate_records,
       max(eligible_records)  FILTER (WHERE dq_ref = 'ALL')                              AS eligible_records,
       round(100.0 * max(eligible_records) FILTER (WHERE dq_ref = 'ALL')
             / max(candidate_records) FILTER (WHERE dq_ref = 'ALL'), 1)                  AS eligible_pct,
       max(records_with_issue) FILTER (WHERE dq_ref = 'ALL')                             AS excluded_records,
       coalesce(sum(records_lost_only_to_issue) FILTER (WHERE impact_type IN ('EXCLUDES', 'EXCLUDES_FROM_PRIMARY')), 0)
                                                                                         AS lost_to_one_dq_issue_only,
       coalesce(max(records_lost_only_to_issue) FILTER (WHERE dq_ref = 'OTHER'), 0)      AS lost_to_non_dq_rule_only,
       max(records_with_issue) FILTER (WHERE dq_ref = 'ALL')
         - coalesce(sum(records_lost_only_to_issue) FILTER (WHERE impact_type IN ('EXCLUDES', 'EXCLUDES_FROM_PRIMARY')), 0)
         - coalesce(max(records_lost_only_to_issue) FILTER (WHERE dq_ref = 'OTHER'), 0)  AS lost_to_two_or_more_reasons,
       CASE WHEN max(candidate_records) FILTER (WHERE dq_ref = 'ALL')
                 - max(eligible_records) FILTER (WHERE dq_ref = 'ALL')
                 = max(records_with_issue) FILTER (WHERE dq_ref = 'ALL')
            THEN 'yes' ELSE 'NO' END                                                     AS reconciles_candidate_minus_eligible
FROM analytics.vw_dq_impact
WHERE dq_ref IN ('ALL', 'OTHER') OR impact_type IN ('EXCLUDES', 'EXCLUDES_FROM_PRIMARY')
GROUP BY metric_order, metric_id, metric_name
HAVING max(candidate_records) FILTER (WHERE dq_ref = 'ALL') IS NOT NULL
ORDER BY metric_order;

-- [RS2] Issue-by-metric matrix: size of each issue's footprint, value at stake, materiality
WITH params AS (SELECT 10.0 AS high_pct, 1.0 AS moderate_pct),
base AS (
    SELECT i.*,
           -- value base: for an exclusion, candidate value = eligible value + value of everything excluded;
           -- for a disclosure the records stay in the metric, so the base is the eligible value
           CASE WHEN i.impact_type = 'DISCLOSED' THEN i.eligible_value_ngn
                ELSE i.eligible_value_ngn
                     + coalesce(max(i.affected_value_ngn) FILTER (WHERE i.dq_ref = 'ALL') OVER (PARTITION BY i.metric_id), 0)
           END AS candidate_value_ngn
    FROM analytics.vw_dq_impact i
),
measured AS (
    SELECT b.*,
           round(100.0 * b.affected_value_ngn / nullif(b.candidate_value_ngn, 0), 1) AS value_pct_of_candidate
    FROM base b
    WHERE b.dq_ref NOT IN ('ALL', 'OTHER')
)
SELECT m.metric_id, m.dq_ref, m.dq_issue, m.impact_type, m.treatment,
       m.candidate_records,
       m.records_with_issue,
       m.pct_of_candidate,
       m.records_lost_only_to_issue,
       round(m.affected_value_ngn / 1e9, 1)               AS affected_value_ngn_bn,
       m.value_pct_of_candidate,
       CASE WHEN greatest(m.pct_of_candidate, coalesce(m.value_pct_of_candidate, 0)) >= p.high_pct     THEN 'HIGH'
            WHEN greatest(m.pct_of_candidate, coalesce(m.value_pct_of_candidate, 0)) >= p.moderate_pct THEN 'MODERATE'
            ELSE 'LOW' END                                 AS materiality,
       rank() OVER (PARTITION BY m.metric_id ORDER BY m.records_with_issue DESC)  AS rank_within_metric,
       m.note
FROM measured m
CROSS JOIN params p
ORDER BY m.metric_order, rank_within_metric, m.dq_ref;

-- [RS3] Which issues matter most across metrics (how many metrics each touches materially)
WITH params AS (SELECT 10.0 AS high_pct, 1.0 AS moderate_pct),
base AS (
    SELECT i.*,
           -- value base: for an exclusion, candidate value = eligible value + value of everything excluded;
           -- for a disclosure the records stay in the metric, so the base is the eligible value
           CASE WHEN i.impact_type = 'DISCLOSED' THEN i.eligible_value_ngn
                ELSE i.eligible_value_ngn
                     + coalesce(max(i.affected_value_ngn) FILTER (WHERE i.dq_ref = 'ALL') OVER (PARTITION BY i.metric_id), 0)
           END AS candidate_value_ngn
    FROM analytics.vw_dq_impact i
),
graded AS (
    SELECT b.metric_id, b.metric_order, b.dq_ref, b.dq_issue, b.treatment, b.impact_type,
           greatest(b.pct_of_candidate, coalesce(100.0 * b.affected_value_ngn / nullif(b.candidate_value_ngn, 0), 0)) AS driver_pct,
           p.high_pct, p.moderate_pct
    FROM base b
    CROSS JOIN params p
    WHERE b.dq_ref NOT IN ('ALL', 'OTHER')
),
classified AS (
    SELECT g.*,
           CASE WHEN driver_pct >= high_pct     THEN 'HIGH'
                WHEN driver_pct >= moderate_pct THEN 'MODERATE'
                ELSE 'LOW' END AS materiality
    FROM graded g
)
SELECT rank() OVER (ORDER BY count(*) FILTER (WHERE materiality = 'HIGH') DESC,
                             count(*) FILTER (WHERE materiality = 'MODERATE') DESC) AS issue_rank,
       dq_ref, max(dq_issue) AS dq_issue, max(treatment) AS treatment,
       count(*)                                                    AS metrics_touched,
       count(*) FILTER (WHERE materiality = 'HIGH')                AS metrics_high,
       count(*) FILTER (WHERE materiality = 'MODERATE')            AS metrics_moderate,
       string_agg(metric_id || ' (' || materiality || ', ' || round(driver_pct, 1) || '% of records or value)', '; '
                  ORDER BY metric_order)                           AS metrics_affected
FROM classified
GROUP BY dq_ref
ORDER BY issue_rank, dq_ref;
