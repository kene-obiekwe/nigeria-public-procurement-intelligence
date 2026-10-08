-- ============================================================
-- NOCOPO — Phase 7 analytical view: Procuring-entity benchmarking
-- ============================================================
-- Spec:   Implementation Plan Phase 7 ("value, volume, competition,
--         concentration, reporting completeness"); Scope business question 5.
-- Grain:  one row per procuring entity (buyer) with a complete buyer ID.
--
-- DQ-19: the bare 'NG-BPP-' buyer (26 releases) is EXCLUDED here; it stays
-- in overall process counts (analytics.vw_lifecycle_stage).
-- DQ-20: the portal test entity NG-BPP-BPP-NOC-90 is excluded everywhere in
-- analytics.*, including the process counts.
-- Every measure is built from the corresponding metric view, so each one
-- inherits that metric's eligibility rule, and its eligible n is shown next
-- to it. A NULL rate or median means the entity has no eligible records for
-- that metric, not a zero.
-- Ranking and percentiles across entities are Phase 8 work.
-- ============================================================
CREATE OR REPLACE VIEW analytics.vw_entity_benchmark AS
WITH proc AS (
    SELECT buyer_id,
           count(*)                                          AS process_count,
           count(*) FILTER (WHERE highest_stage_rank >= 2)   AS processes_reaching_tender,
           count(*) FILTER (WHERE highest_stage_rank >= 3)   AS processes_reaching_award
    FROM analytics.vw_lifecycle_stage
    WHERE buyer_id_flag IS NULL
    GROUP BY buyer_id
),
budget AS (
    SELECT buyer_id,
           count(*)               AS budget_line_n,
           sum(budget_amount)     AS planned_budget_total          -- M-P01
    FROM analytics.vw_budget_eligible
    GROUP BY buyer_id
),
competition AS (
    SELECT buyer_id,
           count(*) FILTER (WHERE in_primary_population)                         AS competition_n,
           percentile_cont(0.5) WITHIN GROUP (ORDER BY number_of_tenderers)
               FILTER (WHERE in_primary_population)                              AS median_tenderers,      -- M-C01
           avg(CASE WHEN is_single_bidder THEN 1.0 ELSE 0.0 END)
               FILTER (WHERE in_primary_population)                              AS single_bidder_rate     -- M-C02
    FROM analytics.vw_competition_eligible
    WHERE buyer_id_flag IS NULL
    GROUP BY buyer_id
),
award AS (
    SELECT buyer_id,
           count(*)                                                              AS award_n,
           sum(award_value_amount)                                               AS award_value_total,
           percentile_cont(0.5) WITHIN GROUP (ORDER BY award_value_amount)       AS median_award_value     -- M-V01
    FROM analytics.vw_award_value_eligible
    WHERE buyer_id_flag IS NULL
    GROUP BY buyer_id
),
supplier_value AS (
    SELECT buyer_id, supplier_id, sum(award_value_amount) AS supplier_value
    FROM analytics.vw_supplier_award_eligible
    WHERE buyer_id_flag IS NULL
    GROUP BY buyer_id, supplier_id
),
concentration AS (
    SELECT buyer_id,
           count(*)                                          AS distinct_supplier_n,
           max(supplier_value) / nullif(sum(supplier_value), 0) AS top_supplier_value_share  -- M-S01 at entity level
    FROM supplier_value
    GROUP BY buyer_id
),
implementation AS (
    SELECT buyer_id,
           count(*)                                                              AS contract_n,
           avg(CASE WHEN has_implementation THEN 1.0 ELSE 0.0 END)               AS implementation_coverage_rate  -- M-I01
    FROM analytics.vw_contract_implementation_coverage
    WHERE buyer_id_flag IS NULL
    GROUP BY buyer_id
)
SELECT d.buyer_id,
       d.buyer_name,
       p.process_count,
       p.processes_reaching_tender,
       round(p.processes_reaching_tender::numeric / p.process_count, 4)   AS tender_reach_rate,
       p.processes_reaching_award,
       b.budget_line_n,
       b.planned_budget_total,
       c.competition_n,
       c.median_tenderers,
       round(c.single_bidder_rate, 4)                                     AS single_bidder_rate,
       a.award_n,
       a.award_value_total,
       round(a.median_award_value::numeric, 2)                            AS median_award_value,
       k.distinct_supplier_n,
       round(k.top_supplier_value_share, 4)                               AS top_supplier_value_share,
       i.contract_n,
       round(i.implementation_coverage_rate, 4)                           AS implementation_coverage_rate
FROM core.dim_buyer d
JOIN proc              p USING (buyer_id)
LEFT JOIN budget         b USING (buyer_id)
LEFT JOIN competition    c USING (buyer_id)
LEFT JOIN award          a USING (buyer_id)
LEFT JOIN concentration  k USING (buyer_id)
LEFT JOIN implementation i USING (buyer_id)
WHERE d.buyer_id_flag IS NULL
  AND d.test_entity_flag IS NULL;                         -- DQ-20

COMMENT ON VIEW analytics.vw_entity_benchmark IS
    'One row per procuring entity (complete buyer ID; DQ-19 excluded). Measures inherit '
    'their metric view eligibility; each has its eligible n alongside. NULL = no eligible '
    'records, not zero. Implementation coverage is a reporting signal, not performance.';
