-- ============================================================
-- NOCOPO — Phase 8, business question 4: procurement-cycle timing
-- ============================================================
-- Question: What can valid tender, award and contract dates tell us about
--           procurement-cycle duration, and where is date completeness
--           insufficient for reliable measurement?  (Scope s.6, Pillar 5)
-- Metrics:  M-E01 tender open duration (days, tender start -> tender end)
--           M-E02 award lag (days, tender start -> award date)
--           P5-SIG contract signature lag (days, award date -> dateSigned)
-- Sources:  analytics.vw_tender_duration_eligible, vw_award_lag_eligible,
--           vw_signature_lag_eligible (one row per OCID / contract)
-- Run:      psql -h localhost -p 5433 -U postgres -d nocopo_db -f sql/06_analysis/04_procurement_cycle_timing.sql
-- DQ-20 (Phase 8.1): the portal test entity NG-BPP-BPP-NOC-90 is excluded by every
--           analytics view used here, so it appears in no population or ranking.
--
-- ELIGIBLE POPULATION
--   Both dates of the interval are present, flagged VALID (not the 2001-01-01
--   placeholder, DQ-08; not a future/impossible date, DQ-09) and the later
--   date is not before the earlier one. release_date is never used (DQ-10).
--   Coverage is low: the register (RS1b) shows the eligible share of each
--   candidate population (about 52% / 45% / 74%).
--
-- LIMITATIONS TO STATE WITH EVERY RESULT
--   1. Coverage first. Medians describe only the minority of processes that
--      published usable dates. The tender start date is missing for about 48% of
--      tenders. Dates are not imputed, so the results cannot be generalised to
--      all procurement. Missing dates are reporting gaps, not delays.
--   2. Who publishes dates may differ from who does not. A different mix of
--      entities or methods in the covered group could shift the medians.
--   3. Chronology conflicts (award before tender start: 141; signed before
--      award: 756, process level) are excluded rather than corrected.
--   4. Long durations (over a year, up to ten) are retained. They may be genuine
--      long processes or date-entry errors; they are counted in RS2, not removed
--      (no outlier rule). Medians are the headline because they are robust to them.
--   5. The M-E02 award lag measures from tender START, not from tender close.
--   6. Year groups use the year of the start date (RS5) or award date (RS6).
--      Groups below min_n (30) are shown but flagged. The year-on-year change is
--      given only when the previous calendar year is also present.
-- ============================================================

-- [RS1] Eligible population sizes and medians (headline timing metrics)
WITH tender_duration AS MATERIALIZED (
    SELECT 'M-E01 tender open duration (days)'::text AS measure, 1 AS sort_order, count(*) AS eligible_n,
           percentile_cont(0.5) WITHIN GROUP (ORDER BY tender_duration_days) AS median_days
    FROM analytics.vw_tender_duration_eligible
),
award_lag AS MATERIALIZED (
    SELECT 'M-E02 award lag, tender start to award (days)', 2, count(*),
           percentile_cont(0.5) WITHIN GROUP (ORDER BY award_lag_days)
    FROM analytics.vw_award_lag_eligible
),
signature_lag AS MATERIALIZED (
    SELECT 'P5-SIG signature lag, award to signing (days)', 3, count(*),
           percentile_cont(0.5) WITHIN GROUP (ORDER BY signature_lag_days)
    FROM analytics.vw_signature_lag_eligible
)
SELECT measure, eligible_n, median_days
FROM (SELECT * FROM tender_duration UNION ALL SELECT * FROM award_lag UNION ALL SELECT * FROM signature_lag) u
ORDER BY sort_order;

-- [RS1b] Coverage: candidate population, eligible count and eligible share (analytics.vw_metric_population; a few seconds)
SELECT metric_id, metric_name, candidate_population, candidate_count, eligible_count, eligible_pct
FROM analytics.vw_metric_population
WHERE metric_id IN ('M-E01', 'M-E02', 'P5-SIG')
ORDER BY metric_id;

-- [RS2] Distribution of each interval, with counts of unusually long intervals (kept, not removed)
WITH intervals AS MATERIALIZED (
    SELECT 'M-E01 tender open duration' AS measure, tender_duration_days AS days FROM analytics.vw_tender_duration_eligible
    UNION ALL
    SELECT 'M-E02 award lag',            award_lag_days       FROM analytics.vw_award_lag_eligible
    UNION ALL
    SELECT 'P5-SIG signature lag',       signature_lag_days   FROM analytics.vw_signature_lag_eligible
)
SELECT measure,
       count(*)                                                         AS eligible_n,
       min(days)                                                        AS min_days,
       percentile_cont(0.25) WITHIN GROUP (ORDER BY days)               AS p25,
       percentile_cont(0.50) WITHIN GROUP (ORDER BY days)               AS median,
       percentile_cont(0.75) WITHIN GROUP (ORDER BY days)               AS p75,
       percentile_cont(0.90) WITHIN GROUP (ORDER BY days)               AS p90,
       percentile_cont(0.99) WITHIN GROUP (ORDER BY days)               AS p99,
       max(days)                                                        AS max_days,
       round((avg(days))::numeric, 1)                                   AS mean_days,
       count(*) FILTER (WHERE days = 0)                                 AS same_day,
       count(*) FILTER (WHERE days > 365)                               AS over_1_year,
       round(100.0 * count(*) FILTER (WHERE days > 365) / count(*), 2)  AS over_1_year_pct
FROM intervals
GROUP BY measure
ORDER BY measure;

-- [RS3] Duration bands (CASE classification)
WITH intervals AS MATERIALIZED (
    SELECT 'M-E01 tender open duration' AS measure, tender_duration_days AS days FROM analytics.vw_tender_duration_eligible
    UNION ALL
    SELECT 'M-E02 award lag',            award_lag_days       FROM analytics.vw_award_lag_eligible
    UNION ALL
    SELECT 'P5-SIG signature lag',       signature_lag_days   FROM analytics.vw_signature_lag_eligible
),
banded AS (
    SELECT measure,
           CASE WHEN days <= 7   THEN '1  up to 7 days'
                WHEN days <= 30  THEN '2  8-30 days'
                WHEN days <= 90  THEN '3  31-90 days'
                WHEN days <= 180 THEN '4  91-180 days'
                WHEN days <= 365 THEN '5  181-365 days'
                ELSE                  '6  over 1 year'
           END AS duration_band
    FROM intervals
)
SELECT measure, duration_band,
       count(*)                                                                   AS processes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY measure), 2)     AS pct_of_measure,
       round(100.0 * sum(count(*)) OVER (PARTITION BY measure ORDER BY duration_band)
             / sum(count(*)) OVER (PARTITION BY measure), 2)                      AS cumulative_pct
FROM banded
GROUP BY measure, duration_band
ORDER BY measure, duration_band;

-- [RS4] Timing by procurement method (eligible populations only; n shown for each measure)
WITH params AS (SELECT 30 AS min_n),
duration AS MATERIALIZED (
    SELECT coalesce(procurement_method_details, '(method not stated)') AS procurement_method,
           count(*) AS tender_duration_n,
           percentile_cont(0.5) WITHIN GROUP (ORDER BY tender_duration_days) AS median_tender_duration_days
    FROM analytics.vw_tender_duration_eligible
    GROUP BY 1
),
lag AS MATERIALIZED (
    SELECT coalesce(procurement_method_details, '(method not stated)') AS procurement_method,
           count(*) AS award_lag_n,
           percentile_cont(0.5) WITHIN GROUP (ORDER BY award_lag_days) AS median_award_lag_days
    FROM analytics.vw_award_lag_eligible
    GROUP BY 1
)
SELECT coalesce(d.procurement_method, l.procurement_method)   AS procurement_method,
       coalesce(d.tender_duration_n, 0)                       AS tender_duration_n,
       d.median_tender_duration_days,
       coalesce(l.award_lag_n, 0)                             AS award_lag_n,
       l.median_award_lag_days,
       CASE WHEN least(coalesce(d.tender_duration_n, 0), coalesce(l.award_lag_n, 0)) < (SELECT min_n FROM params)
            THEN 'small n in at least one measure: read with caution' ELSE '' END AS reliability_note
FROM duration d
FULL OUTER JOIN lag l ON l.procurement_method = d.procurement_method
ORDER BY coalesce(d.tender_duration_n, 0) + coalesce(l.award_lag_n, 0) DESC;

-- [RS5] Tender open duration by year of tender start, with year-on-year change in the median
WITH params AS (SELECT 30 AS min_n),
by_year AS (
    SELECT extract(year FROM tender_start_date)::int AS tender_start_year,
           count(*)                                  AS eligible_n,
           percentile_cont(0.5) WITHIN GROUP (ORDER BY tender_duration_days) AS median_days
    FROM analytics.vw_tender_duration_eligible
    GROUP BY 1
)
SELECT tender_start_year, eligible_n, median_days,
       CASE WHEN tender_start_year - lag(tender_start_year) OVER (ORDER BY tender_start_year) = 1
            THEN median_days - lag(median_days) OVER (ORDER BY tender_start_year)
       END                                                                    AS change_vs_previous_year_days,
       CASE WHEN eligible_n < (SELECT min_n FROM params) THEN 'small n: read with caution' ELSE '' END AS reliability_note
FROM by_year
ORDER BY tender_start_year;

-- [RS6] Award lag by year of award date, with year-on-year change in the median
WITH params AS (SELECT 30 AS min_n),
by_year AS (
    SELECT extract(year FROM award_date)::int AS award_year,
           count(*)                           AS eligible_n,
           percentile_cont(0.5) WITHIN GROUP (ORDER BY award_lag_days) AS median_days
    FROM analytics.vw_award_lag_eligible
    GROUP BY 1
)
SELECT award_year, eligible_n, median_days,
       CASE WHEN award_year - lag(award_year) OVER (ORDER BY award_year) = 1
            THEN median_days - lag(median_days) OVER (ORDER BY award_year)
       END                                                                    AS change_vs_previous_year_days,
       CASE WHEN eligible_n < (SELECT min_n FROM params) THEN 'small n: read with caution' ELSE '' END AS reliability_note
FROM by_year
ORDER BY award_year;
