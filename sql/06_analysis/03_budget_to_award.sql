-- ============================================================
-- NOCOPO — Phase 8, business question 3: budget-to-award variance
-- ============================================================
-- Question: How does awarded value compare with recorded planning budgets, and
--           which entities or procurement areas exhibit notable
--           budget-to-award variance?  (Scope s.6, Pillar 4)
-- Source:   analytics.vw_budget_award_comparison (one row per OCID)
-- Run:      psql -h localhost -p 5433 -U postgres -d nocopo_db -f sql/06_analysis/03_budget_to_award.sql
-- DQ-20 (Phase 8.1): the portal test entity NG-BPP-BPP-NOC-90 is excluded by every
--           analytics view used here, so it appears in no population or ranking.
--
-- ELIGIBLE POPULATION
--   An OCID with an award that is active, not EXTREME (DQ-07) and not zero
--   (DQ-16) [Kene I-1], exactly one planning budget line [Kene I-2: the 3
--   MULTI_PROJECT OCIDs are excluded], and that budget > 0 and not EXTREME
--   (DQ-06). Budget versus award is the only valid financial comparison:
--   tender and contract values equal the award value (C-08).
--
-- DEFINITIONS
--   variance_amount        = award value - budget      (positive: award above budget)
--   award_to_budget_ratio  = award value / budget
--   aggregate ratio        = SUM(award) / SUM(budget). It is dominated by the
--                            largest processes; the median ratio describes the
--                            typical process. Both are shown.
--
-- LIMITATIONS TO STATE WITH EVERY RESULT
--   1. A budget is a plan, not a contract estimate. A ratio above or below 1 is
--      a difference between two recorded figures, not an overrun, saving or
--      loss. Causes (scope change, phasing, a budget line shared by several
--      lots, unit or entry errors) cannot be told apart in this data.
--   2. The ratio spans 0.0000 to about 1.7 billion. Extreme ratios are retained
--      (no outlier rule is applied); RS3 isolates them in their own band so they
--      are visible rather than hidden or silently dropped.
--   3. Excluded: eligible-award OCIDs with no budget line, with several
--      unrelated budget lines, or with a zero / EXTREME budget (see RS1).
--      Where each exclusion comes from is in 07_data_quality_impact.sql.
--   4. Budget project IDs are compared as published; RS7 tests whether any one
--      budget line is reused across OCIDs (it is not in this population). Whether
--      different IDs describe the same underlying budget cannot be tested.
--   5. Entity and method comparisons use groups with at least min_ocids
--      comparable OCIDs (parameter in RS4 / RS5).
-- ============================================================

-- [RS1] Eligible population, totals and headline ratios
-- (both inputs are materialised so each view is read once)
WITH candidate AS MATERIALIZED (
    SELECT count(*) AS candidate_awards FROM analytics.vw_award_value_eligible   -- M-V01 eligible awards
),
comparable AS MATERIALIZED (
    SELECT count(*)                                                       AS eligible_ocids,
           sum(budget_amount)                                             AS total_budget,
           sum(award_value_amount)                                        AS total_award,
           sum(variance_amount)                                           AS net_variance,
           percentile_cont(0.5) WITHIN GROUP (ORDER BY award_to_budget_ratio) AS median_ratio
    FROM analytics.vw_budget_award_comparison
)
SELECT c.candidate_awards,
       v.eligible_ocids,
       round(100.0 * v.eligible_ocids / c.candidate_awards, 1)            AS eligible_pct_of_candidate,
       c.candidate_awards - v.eligible_ocids                              AS excluded_ocids,
       round(v.total_budget / 1e9, 1)                                     AS total_budget_ngn_bn,
       round(v.total_award / 1e9, 1)                                      AS total_award_ngn_bn,
       round(v.net_variance / 1e9, 1)                                     AS net_variance_ngn_bn,
       round(v.total_award / v.total_budget, 4)                           AS aggregate_award_to_budget_ratio,
       round(v.median_ratio::numeric, 4)                                  AS median_ratio
FROM candidate c
CROSS JOIN comparable v;

-- [RS1b] Register entry (analytics.vw_metric_population; a few seconds)
SELECT metric_id, candidate_population, candidate_count, eligible_count, eligible_pct
FROM analytics.vw_metric_population
WHERE metric_id = 'P4-BvA';

-- [RS2] Distribution of the award-to-budget ratio (percentiles; nothing trimmed)
SELECT count(*)                                                                  AS eligible_ocids,
       min(award_to_budget_ratio)                                                AS min_ratio,
       round((percentile_cont(0.01) WITHIN GROUP (ORDER BY award_to_budget_ratio))::numeric, 4) AS p01,
       round((percentile_cont(0.10) WITHIN GROUP (ORDER BY award_to_budget_ratio))::numeric, 4) AS p10,
       round((percentile_cont(0.25) WITHIN GROUP (ORDER BY award_to_budget_ratio))::numeric, 4) AS p25,
       round((percentile_cont(0.50) WITHIN GROUP (ORDER BY award_to_budget_ratio))::numeric, 4) AS median,
       round((percentile_cont(0.75) WITHIN GROUP (ORDER BY award_to_budget_ratio))::numeric, 4) AS p75,
       round((percentile_cont(0.90) WITHIN GROUP (ORDER BY award_to_budget_ratio))::numeric, 4) AS p90,
       round((percentile_cont(0.99) WITHIN GROUP (ORDER BY award_to_budget_ratio))::numeric, 4) AS p99,
       max(award_to_budget_ratio)                                                AS max_ratio
FROM analytics.vw_budget_award_comparison;

-- [RS3] Ratio bands (CASE classification): how many OCIDs, how much value in each
SELECT CASE
           WHEN award_to_budget_ratio < 0.5   THEN '1  award below half of budget (<0.5)'
           WHEN award_to_budget_ratio < 0.9   THEN '2  award 50-90% of budget'
           WHEN award_to_budget_ratio <= 1.1  THEN '3  award within 10% of budget (0.9-1.1)'
           WHEN award_to_budget_ratio <= 1.5  THEN '4  award 110-150% of budget'
           WHEN award_to_budget_ratio <= 10   THEN '5  award 1.5x-10x budget'
           ELSE                                    '6  award above 10x budget (check units / budget entry)'
       END                                                                       AS ratio_band,
       count(*)                                                                  AS ocids,
       round(100.0 * count(*) / sum(count(*)) OVER (), 2)                        AS pct_of_ocids,
       round(sum(budget_amount) / 1e9, 2)                                        AS budget_ngn_bn,
       round(sum(award_value_amount) / 1e9, 2)                                   AS award_ngn_bn,
       round(100.0 * sum(award_value_amount) / sum(sum(award_value_amount)) OVER (), 2) AS pct_of_award_value
FROM analytics.vw_budget_award_comparison
GROUP BY 1
ORDER BY 1;

-- [RS4] Variance by procurement method
WITH params AS (SELECT 30 AS min_ocids)
SELECT coalesce(procurement_method_details, '(method not stated)')               AS procurement_method,
       count(*)                                                                  AS eligible_ocids,
       round(sum(budget_amount) / 1e9, 2)                                        AS budget_ngn_bn,
       round(sum(award_value_amount) / 1e9, 2)                                   AS award_ngn_bn,
       round(sum(variance_amount) / 1e9, 2)                                      AS net_variance_ngn_bn,
       round(sum(award_value_amount) / sum(budget_amount), 4)                    AS aggregate_ratio,
       round((percentile_cont(0.5) WITHIN GROUP (ORDER BY award_to_budget_ratio))::numeric, 4) AS median_ratio,
       round(100.0 * count(*) FILTER (WHERE award_to_budget_ratio > 1.1) / count(*), 1)  AS pct_award_above_110pct_of_budget,
       round(100.0 * count(*) FILTER (WHERE award_to_budget_ratio < 0.9) / count(*), 1)  AS pct_award_below_90pct_of_budget,
       CASE WHEN count(*) < (SELECT min_ocids FROM params) THEN 'small n: read with caution' ELSE '' END AS reliability_note
FROM analytics.vw_budget_award_comparison
GROUP BY 1
ORDER BY eligible_ocids DESC;

-- [RS5] Entities with the largest net variance between awards and budgets (absolute NGN)
WITH params AS (SELECT 10 AS min_ocids),
entity AS (
    SELECT buyer_id, max(buyer_name) AS buyer_name,
           count(*)                                                  AS eligible_ocids,
           sum(budget_amount)                                        AS budget,
           sum(award_value_amount)                                   AS award,
           sum(variance_amount)                                      AS net_variance,
           sum(award_value_amount) / sum(budget_amount)              AS aggregate_ratio,
           percentile_cont(0.5) WITHIN GROUP (ORDER BY award_to_budget_ratio) AS median_ratio
    FROM analytics.vw_budget_award_comparison
    WHERE buyer_id_flag IS NULL                                      -- DQ-19: bare buyer ID is not an entity
    GROUP BY buyer_id
),
scored AS (
    SELECT e.*,
           count(*) OVER ()                                          AS entities_in_comparison,
           rank()   OVER (ORDER BY abs(net_variance) DESC)           AS rank_by_abs_variance,
           sum(abs(net_variance)) OVER (ORDER BY abs(net_variance) DESC, buyer_id)
               / sum(abs(net_variance)) OVER ()                      AS cumulative_share_of_abs_variance
    FROM entity e, params p
    WHERE e.eligible_ocids >= p.min_ocids
)
SELECT rank_by_abs_variance, buyer_id, buyer_name, eligible_ocids,
       round(budget / 1e9, 2)                       AS budget_ngn_bn,
       round(award / 1e9, 2)                        AS award_ngn_bn,
       round(net_variance / 1e9, 2)                 AS net_variance_ngn_bn,
       round(aggregate_ratio::numeric, 4)           AS aggregate_ratio,
       round(median_ratio::numeric, 4)              AS median_ratio,
       round((100 * cumulative_share_of_abs_variance)::numeric, 1) AS cumulative_share_of_abs_variance_pct,
       entities_in_comparison
FROM scored
WHERE rank_by_abs_variance <= 15
ORDER BY rank_by_abs_variance;

-- [RS6] Entities whose typical process departs most from budget (median ratio), same comparison set
WITH params AS (SELECT 10 AS min_ocids),
entity AS (
    SELECT buyer_id, max(buyer_name) AS buyer_name,
           count(*)                                                  AS eligible_ocids,
           percentile_cont(0.5) WITHIN GROUP (ORDER BY award_to_budget_ratio) AS median_ratio,
           avg(CASE WHEN award_to_budget_ratio BETWEEN 0.9 AND 1.1 THEN 1.0 ELSE 0.0 END) AS share_within_10pct
    FROM analytics.vw_budget_award_comparison
    WHERE buyer_id_flag IS NULL
    GROUP BY buyer_id
),
scored AS (
    SELECT e.*,
           count(*) OVER ()                                          AS entities_in_comparison,
           rank()   OVER (ORDER BY abs(median_ratio - 1) DESC)       AS rank_by_median_departure,
           ntile(4) OVER (ORDER BY share_within_10pct)               AS alignment_quartile   -- 1 = least aligned
    FROM entity e, params p
    WHERE e.eligible_ocids >= p.min_ocids
)
SELECT rank_by_median_departure, buyer_id, buyer_name, eligible_ocids,
       round(median_ratio::numeric, 4)              AS median_ratio,
       round((100 * share_within_10pct)::numeric, 1) AS pct_ocids_within_10pct_of_budget,
       alignment_quartile, entities_in_comparison
FROM scored
WHERE rank_by_median_departure <= 15
ORDER BY rank_by_median_departure;

-- [RS7] Double-count check: is any planning budget line compared against more than one OCID?
WITH per_project AS (
    SELECT budget_project_id, count(*) AS ocids, sum(budget_amount) AS summed_budget, max(budget_amount) AS one_budget
    FROM analytics.vw_budget_award_comparison
    GROUP BY budget_project_id
)
SELECT count(*)                                                    AS budget_project_ids,
       count(*) FILTER (WHERE ocids > 1)                           AS ids_used_by_several_ocids,
       round(sum(summed_budget) / 1e9, 1)                          AS summed_budget_ngn_bn,
       round(sum(one_budget) / 1e9, 1)                             AS budget_counted_once_ngn_bn,
       CASE WHEN sum(summed_budget) = sum(one_budget)
            THEN 'no budget line is repeated across OCIDs: totals are not inflated by sharing'
            ELSE 'some budget lines are repeated across OCIDs: totals overstate budget' END AS reading
FROM per_project;

-- [RS8] Placeholder-like budgets: how many comparable OCIDs record a budget under NGN 100,000, and what ratios result
-- (a known limitation, not an exclusion; the extreme end of the ratio comes from these entries)
WITH tiny AS MATERIALIZED (
    SELECT * FROM analytics.vw_budget_award_comparison WHERE budget_amount < 100000
)
SELECT (SELECT count(*) FROM analytics.vw_budget_award_comparison)                      AS comparable_ocids,
       count(*)                                                                         AS ocids_with_budget_under_100k,
       min(budget_amount)                                                               AS smallest_budget_ngn,
       max(award_to_budget_ratio)                                                       AS largest_ratio_among_them,
       count(*) FILTER (WHERE award_to_budget_ratio >= 1000000)                         AS of_which_ratio_1m_or_more,
       (SELECT count(*) FROM analytics.vw_budget_award_comparison
         WHERE award_to_budget_ratio >= 1000000)                                        AS all_ocids_with_ratio_1m_or_more,
       (SELECT count(*) FROM analytics.vw_budget_award_comparison
         WHERE award_to_budget_ratio >= 1000000 AND budget_amount >= 100000)            AS ratio_1m_or_more_with_budget_100k_plus
FROM tiny;

-- [RS9] The above-10x band by entity: where the band's value sits (pattern only; no cause is attributed)
WITH band AS MATERIALIZED (
    SELECT * FROM analytics.vw_budget_award_comparison WHERE award_to_budget_ratio > 10
)
SELECT rank() OVER (ORDER BY sum(award_value_amount) DESC)                              AS rank_in_band,
       buyer_id, max(buyer_name)                                                        AS buyer_name,
       count(*)                                                                         AS ocids_above_10x,
       round(sum(award_value_amount) / 1e9, 1)                                          AS award_ngn_bn,
       round(100.0 * sum(award_value_amount) / sum(sum(award_value_amount)) OVER (), 1) AS pct_of_band_value,
       round((percentile_cont(0.5) WITHIN GROUP (ORDER BY award_to_budget_ratio))::numeric, 1) AS median_ratio,
       sum(count(*)) OVER ()                                                            AS band_ocids,
       round(sum(sum(award_value_amount)) OVER () / 1e9, 1)                             AS band_award_ngn_bn
FROM band
GROUP BY buyer_id
ORDER BY rank_in_band
LIMIT 5;

-- [RS10] Unit test: is an award about 1,000 times its budget (budget recorded in thousands)?
SELECT count(*) FILTER (WHERE award_to_budget_ratio BETWEEN 900 AND 1100)                       AS ocids_with_ratio_900_to_1100,
       count(*) FILTER (WHERE award_to_budget_ratio BETWEEN 900 AND 1100
                          AND budget_amount >= 100000)                                          AS of_which_budget_100k_plus,
       count(*) FILTER (WHERE award_to_budget_ratio > 10)                                       AS ocids_above_10x,
       round(100.0 * count(*) FILTER (WHERE award_to_budget_ratio BETWEEN 900 AND 1100)
             / nullif(count(*) FILTER (WHERE award_to_budget_ratio > 10), 0), 1)                AS ratio_900_to_1100_pct_of_above_10x,
       'a "budget recorded in thousands" pattern would put most of the above-10x OCIDs near 1,000; it does not' AS reading
FROM analytics.vw_budget_award_comparison;
