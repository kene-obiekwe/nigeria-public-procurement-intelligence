-- ============================================================
-- NOCOPO — Phase 8, business question 5: procuring-entity benchmarking
-- ============================================================
-- Question: Which procuring entities account for the greatest procurement
--           activity, and how do their procurement patterns compare across
--           selected KPIs?  (Scope s.6, Pillar: Procuring-Entity Benchmarking)
-- Source:   analytics.vw_entity_benchmark (one row per buyer with a complete
--           buyer ID). Each KPI there is built from its own metric view and so
--           inherits that metric's eligibility; its eligible n sits beside it.
-- Run:      psql -h localhost -p 5433 -U postgres -d nocopo_db -f sql/06_analysis/05_entity_benchmarking.sql
--
-- ELIGIBLE POPULATION
--   666 entities (667 buyer IDs minus the bare 'NG-BPP-', DQ-19). For each KPI
--   an entity is compared only if it has at least the minimum n listed in
--   RS0 below; otherwise its KPI is left out of that comparison (not set to zero).
--
-- KPIs                                                  eligible n column
--   activity     process_count, award_n, award_value_total, planned_budget_total
--   reach        tender_reach_rate                      process_count
--   competition  median_tenderers, single_bidder_rate   competition_n
--   concentration top_supplier_value_share              award_n (via distinct_supplier_n)
--   reporting    implementation_coverage_rate           contract_n
--
-- LIMITATIONS TO STATE WITH EVERY RESULT
--   1. A NULL KPI means "no eligible records for that metric", never zero.
--   2. KPIs have different eligible populations, so they are not additive across
--      columns. Always read a KPI with its own n.
--   3. Scale confounds comparison: large entities buy different things by
--      different methods. Percentile positions rank entities against each other;
--      they do not say a position is good or bad.
--   4. implementation_coverage_rate is reporting coverage, not contract
--      performance. tender_reach_rate reflects what was published to NOCOPO.
--   5. Entities are identified by buyer ID and not merged on name similarity.
--      One entity named "TEST MINISTRY - NOCOPO" appears in the data. No
--      approved rule removes it, so it is retained and visible; see the
--      Phase 8 write-up.
-- ============================================================

-- [RS0] Minimum eligible n applied to each KPI in this script (analytic parameters, not data rules)
SELECT kpi, min_n
FROM (VALUES ('single_bidder_rate / median_tenderers (competition_n)', 30),
             ('top_supplier_value_share (award_n)',                      10),
             ('implementation_coverage_rate (contract_n)',               20),
             ('tender_reach_rate (process_count)',                       30)) AS p(kpi, min_n);

-- [RS1] Population: entities and how many have data for each KPI
SELECT count(*)                                                  AS entities,
       sum(process_count)                                        AS processes_in_scope,
       count(*) FILTER (WHERE budget_line_n IS NOT NULL)         AS entities_with_budget_lines,
       count(*) FILTER (WHERE competition_n IS NOT NULL)         AS entities_with_competition_data,
       count(*) FILTER (WHERE competition_n >= 30)               AS entities_competition_n_30_plus,
       count(*) FILTER (WHERE award_n IS NOT NULL)               AS entities_with_awards,
       count(*) FILTER (WHERE award_n >= 10)                     AS entities_award_n_10_plus,
       count(*) FILTER (WHERE contract_n IS NOT NULL)            AS entities_with_contracts,
       count(*) FILTER (WHERE contract_n >= 20)                  AS entities_contract_n_20_plus,
       round(sum(award_value_total) / 1e9, 1)                    AS total_award_value_ngn_bn,
       round(sum(planned_budget_total) / 1e9, 1)                 AS total_planned_budget_ngn_bn
FROM analytics.vw_entity_benchmark;

-- [RS1b] Register entry (analytics.vw_metric_population; about 40 s because the register evaluates every view)
SELECT metric_id, candidate_population, candidate_count, eligible_count, eligible_pct
FROM analytics.vw_metric_population
WHERE metric_id = 'ENTITY';

-- [RS2] How much activity sits with the largest entities (window functions: rank and cumulative share)
WITH ranked AS (
    SELECT buyer_id,
           process_count,
           coalesce(award_n, 0)                    AS award_n,
           coalesce(award_value_total, 0)          AS award_value,
           coalesce(planned_budget_total, 0)       AS budget,
           row_number() OVER (ORDER BY coalesce(award_value_total, 0) DESC, buyer_id)    AS value_rank,
           row_number() OVER (ORDER BY process_count DESC, buyer_id)                     AS process_rank,
           row_number() OVER (ORDER BY coalesce(planned_budget_total, 0) DESC, buyer_id) AS budget_rank
    FROM analytics.vw_entity_benchmark
),
totals AS (
    SELECT sum(process_count) AS processes, sum(award_value) AS award_value, sum(budget) AS budget FROM ranked
)
SELECT g.top_n                                                                       AS largest_entities,
       round(100.0 * sum(r.award_value) FILTER (WHERE r.value_rank   <= g.top_n) / t.award_value, 1) AS pct_of_award_value,
       round(100.0 * sum(r.process_count) FILTER (WHERE r.process_rank <= g.top_n) / t.processes, 1)  AS pct_of_processes,
       round(100.0 * sum(r.budget) FILTER (WHERE r.budget_rank  <= g.top_n) / t.budget, 1)            AS pct_of_planned_budget
FROM ranked r
CROSS JOIN totals t
CROSS JOIN (VALUES (1), (5), (10), (20), (50), (100)) AS g(top_n)
GROUP BY g.top_n, t.award_value, t.processes, t.budget
ORDER BY g.top_n;

-- [RS3] Top 15 entities by awarded value, with their rank on each activity measure
WITH ranked AS (
    SELECT b.*,
           rank() OVER (ORDER BY coalesce(award_value_total, 0) DESC)    AS rank_award_value,
           rank() OVER (ORDER BY process_count DESC)                     AS rank_processes,
           rank() OVER (ORDER BY coalesce(award_n, 0) DESC)              AS rank_awards,
           rank() OVER (ORDER BY coalesce(planned_budget_total, 0) DESC) AS rank_budget,
           sum(coalesce(award_value_total, 0)) OVER (ORDER BY coalesce(award_value_total, 0) DESC, buyer_id)
               / sum(coalesce(award_value_total, 0)) OVER ()             AS cumulative_share
    FROM analytics.vw_entity_benchmark b
)
SELECT rank_award_value, buyer_id, buyer_name,
       round(award_value_total / 1e9, 1)             AS award_value_ngn_bn,
       round((100 * cumulative_share)::numeric, 1)   AS cumulative_share_of_award_value_pct,
       award_n, process_count,
       round(planned_budget_total / 1e9, 1)          AS planned_budget_ngn_bn,
       rank_processes, rank_awards, rank_budget
FROM ranked
WHERE rank_award_value <= 15
ORDER BY rank_award_value;

-- [RS4] KPI profile of the top 15 entities by awarded value, each KPI beside its own n and percentile position
-- (a blank KPI and percentile mean the entity is below the minimum n for that KPI, see RS0)
WITH params AS (SELECT 30 AS min_competition_n, 10 AS min_award_n, 20 AS min_contract_n, 30 AS min_process_n),
base AS (
    SELECT b.*,
           CASE WHEN competition_n >= p.min_competition_n THEN single_bidder_rate END AS sb_rate,
           CASE WHEN competition_n >= p.min_competition_n THEN median_tenderers END   AS med_tend,
           CASE WHEN award_n       >= p.min_award_n       THEN top_supplier_value_share END AS top_share,
           CASE WHEN contract_n    >= p.min_contract_n    THEN implementation_coverage_rate END AS impl_rate,
           CASE WHEN process_count >= p.min_process_n     THEN tender_reach_rate END   AS reach_rate
    FROM analytics.vw_entity_benchmark b, params p
),
pos AS (
    -- percent_rank within the entities that have a value (PARTITION BY isolates the NULL group)
    SELECT base.*,
           percent_rank() OVER (PARTITION BY (sb_rate  IS NULL) ORDER BY sb_rate)    AS pr_single_bidder,
           percent_rank() OVER (PARTITION BY (med_tend IS NULL) ORDER BY med_tend)   AS pr_median_tenderers,
           percent_rank() OVER (PARTITION BY (top_share IS NULL) ORDER BY top_share) AS pr_top_supplier,
           percent_rank() OVER (PARTITION BY (impl_rate IS NULL) ORDER BY impl_rate) AS pr_implementation,
           percent_rank() OVER (PARTITION BY (reach_rate IS NULL) ORDER BY reach_rate) AS pr_tender_reach,
           rank() OVER (ORDER BY coalesce(award_value_total, 0) DESC)                AS rank_award_value
    FROM base
)
SELECT rank_award_value, buyer_name,
       round(100 * reach_rate, 1)                                                   AS tender_reach_pct,
       CASE WHEN reach_rate IS NOT NULL THEN round((100 * pr_tender_reach)::numeric, 0) END     AS reach_pctile,
       competition_n,
       med_tend                                                                     AS median_tenderers,
       CASE WHEN med_tend IS NOT NULL THEN round((100 * pr_median_tenderers)::numeric, 0) END  AS tenderers_pctile,
       round(100 * sb_rate, 1)                                                      AS single_bidder_pct,
       CASE WHEN sb_rate IS NOT NULL THEN round((100 * pr_single_bidder)::numeric, 0) END      AS single_bidder_pctile,
       award_n,
       round(100 * top_share, 1)                                                    AS top_supplier_share_pct,
       CASE WHEN top_share IS NOT NULL THEN round((100 * pr_top_supplier)::numeric, 0) END     AS top_supplier_pctile,
       contract_n,
       round(100 * impl_rate, 1)                                                    AS implementation_coverage_pct,
       CASE WHEN impl_rate IS NOT NULL THEN round((100 * pr_implementation)::numeric, 0) END   AS implementation_pctile
FROM pos
WHERE rank_award_value <= 15
ORDER BY rank_award_value;

-- [RS5] Spread of each KPI across entities that meet the minimum n (the yardstick for RS4)
WITH params AS (SELECT 30 AS min_competition_n, 10 AS min_award_n, 20 AS min_contract_n, 30 AS min_process_n),
kpi AS (
    SELECT 'tender reach rate'::text AS kpi, 1 AS sort_order, tender_reach_rate::numeric AS value
    FROM analytics.vw_entity_benchmark, params WHERE process_count >= min_process_n
    UNION ALL
    SELECT 'median tenderers', 2, median_tenderers::numeric
    FROM analytics.vw_entity_benchmark, params WHERE competition_n >= min_competition_n
    UNION ALL
    SELECT 'single-bidder rate', 3, single_bidder_rate::numeric
    FROM analytics.vw_entity_benchmark, params WHERE competition_n >= min_competition_n
    UNION ALL
    SELECT 'top-supplier value share', 4, top_supplier_value_share::numeric
    FROM analytics.vw_entity_benchmark, params WHERE award_n >= min_award_n
    UNION ALL
    SELECT 'implementation coverage rate', 5, implementation_coverage_rate::numeric
    FROM analytics.vw_entity_benchmark, params WHERE contract_n >= min_contract_n
)
SELECT kpi,
       count(*)                                                          AS entities_compared,
       round((percentile_cont(0.10) WITHIN GROUP (ORDER BY value))::numeric, 3) AS p10,
       round((percentile_cont(0.25) WITHIN GROUP (ORDER BY value))::numeric, 3) AS p25,
       round((percentile_cont(0.50) WITHIN GROUP (ORDER BY value))::numeric, 3) AS median,
       round((percentile_cont(0.75) WITHIN GROUP (ORDER BY value))::numeric, 3) AS p75,
       round((percentile_cont(0.90) WITHIN GROUP (ORDER BY value))::numeric, 3) AS p90
FROM kpi
GROUP BY kpi, sort_order
ORDER BY sort_order;

-- [RS6] Do larger entities differ? KPI medians by quartile of awarded value (entities with awards)
WITH params AS (SELECT 30 AS min_competition_n, 20 AS min_contract_n),
tiered AS (
    SELECT b.*, ntile(4) OVER (ORDER BY award_value_total DESC) AS value_quartile   -- 1 = largest
    FROM analytics.vw_entity_benchmark b
    WHERE award_value_total IS NOT NULL
)
SELECT value_quartile,
       count(*)                                                           AS entities,
       round(sum(award_value_total) / 1e9, 1)                             AS award_value_ngn_bn,
       round(100.0 * sum(award_value_total) / sum(sum(award_value_total)) OVER (), 1) AS pct_of_award_value,
       count(*) FILTER (WHERE competition_n >= p.min_competition_n)       AS entities_with_competition_n,
       round((100 * percentile_cont(0.5) WITHIN GROUP (ORDER BY single_bidder_rate)
              FILTER (WHERE competition_n >= p.min_competition_n))::numeric, 1) AS median_single_bidder_pct,
       count(*) FILTER (WHERE contract_n >= p.min_contract_n)             AS entities_with_contract_n,
       round((100 * percentile_cont(0.5) WITHIN GROUP (ORDER BY implementation_coverage_rate)
              FILTER (WHERE contract_n >= p.min_contract_n))::numeric, 1)  AS median_implementation_coverage_pct,
       CASE WHEN count(*) FILTER (WHERE competition_n >= p.min_competition_n) < 10
              OR count(*) FILTER (WHERE contract_n >= p.min_contract_n) < 10
            THEN 'fewer than 10 entities in a KPI: read with caution' ELSE '' END AS reliability_note
FROM tiered t, params p
GROUP BY value_quartile
ORDER BY value_quartile;
