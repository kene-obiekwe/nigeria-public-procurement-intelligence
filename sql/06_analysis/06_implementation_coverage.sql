-- ============================================================
-- NOCOPO — Phase 8, business question 6: implementation reporting coverage
-- ============================================================
-- Question: What proportion of contracts has usable implementation/payment
--           information, and what does reporting completeness reveal about the
--           availability of downstream procurement data?  (Scope s.6, Pillar 5)
-- Metrics:  M-I01 implementation reporting coverage (contract level)
--           M-E03 lifecycle conversion (OCID level)
-- Sources:  analytics.vw_contract_implementation_coverage (one row per contract),
--           analytics.vw_lifecycle_stage (one row per OCID)
-- Run:      psql -h localhost -p 5433 -U postgres -d nocopo_db -f sql/06_analysis/06_implementation_coverage.sql
--
-- ELIGIBLE POPULATION
--   M-I01: every snapshot contract (no exclusions by specification): 16,392.
--   M-E03: every OCID (no exclusions by specification): 98,866.
--   has_implementation is true when the contract carries implementation
--   milestones or transactions.
--
-- THIS IS COVERAGE, NOT PERFORMANCE
--   A contract with no implementation data may not have started, may be
--   complete but unreported, or may be poorly reported. The data cannot tell
--   these apart. Missing implementation data is a reporting gap, never evidence
--   of non-performance (Data-Quality and Cleaning Plan, missing-value rules). Results describe what was published to
--   NOCOPO, not what happened on the ground.
--
-- LIMITATIONS TO STATE WITH EVERY RESULT
--   1. Transaction dates are absent in every record (DQ-11) and transaction
--      value semantics are unresolved (DQ-12). Transactions are used only to
--      show that a payment record exists; no payment value is summed.
--   2. The lifecycle funnel (RS6) counts the highest stage each OCID ever
--      reached across all releases. Most OCIDs (about 82%) were published at
--      planning stage only (DQ-02), so low conversion partly reflects what
--      NOCOPO holds, not the true attrition of procurement.
--   3. Entity comparisons use entities with at least min_contracts contracts
--      (parameter in RS5).
-- ============================================================

-- [RS1] M-I01 headline: eligible population and coverage rate
SELECT count(*)                                                          AS eligible_contracts,
       count(*) FILTER (WHERE has_implementation)                        AS contracts_with_implementation_data,
       round(100.0 * count(*) FILTER (WHERE has_implementation) / count(*), 2) AS coverage_rate_pct_m_i01,
       count(*) FILTER (WHERE NOT has_implementation)                    AS contracts_without_implementation_data
FROM analytics.vw_contract_implementation_coverage;

-- [RS1b] Register entries (analytics.vw_metric_population; about 40 s because the register evaluates every view)
SELECT metric_id, candidate_population, candidate_count, eligible_count, eligible_pct
FROM analytics.vw_metric_population
WHERE metric_id IN ('M-I01', 'M-E03')
ORDER BY metric_id;

-- [RS2] What kind of implementation data exists (CASE classification)
SELECT CASE
           WHEN transaction_count > 0 AND implementation_milestone_count > 0 THEN '1  transactions and milestones'
           WHEN implementation_milestone_count > 0                           THEN '2  milestones only'
           WHEN transaction_count > 0                                        THEN '3  transactions only'
           ELSE                                                                   '4  no implementation data'
       END                                                               AS implementation_data_type,
       count(*)                                                          AS contracts,
       round(100.0 * count(*) / sum(count(*)) OVER (), 2)                AS pct_of_contracts,
       sum(transaction_count)                                            AS transactions,
       sum(implementation_milestone_count)                               AS implementation_milestones
FROM analytics.vw_contract_implementation_coverage
GROUP BY 1
ORDER BY 1;

-- [RS3] Coverage by contract status
SELECT coalesce(contract_status, '(status not stated)')                  AS contract_status,
       count(*)                                                          AS contracts,
       count(*) FILTER (WHERE has_implementation)                        AS with_implementation_data,
       round(100.0 * count(*) FILTER (WHERE has_implementation) / count(*), 2) AS coverage_rate_pct,
       CASE WHEN count(*) < 30 THEN 'small n: read with caution' ELSE '' END AS reliability_note
FROM analytics.vw_contract_implementation_coverage
GROUP BY 1
ORDER BY contracts DESC;

-- [RS4] Distribution of coverage across entities (entities with at least min_contracts contracts)
WITH params AS (SELECT 20 AS min_contracts),
entity AS (
    SELECT buyer_id,
           count(*)                                              AS contracts,
           avg(CASE WHEN has_implementation THEN 1.0 ELSE 0.0 END) AS coverage_rate
    FROM analytics.vw_contract_implementation_coverage
    WHERE buyer_id_flag IS NULL                                  -- DQ-19: bare buyer ID is not an entity
    GROUP BY buyer_id
),
compared AS (
    SELECT e.* FROM entity e, params p WHERE e.contracts >= p.min_contracts
)
SELECT CASE
           WHEN coverage_rate = 1     THEN '1  full coverage (100%)'
           WHEN coverage_rate >= 0.9  THEN '2  90% to under 100%'
           WHEN coverage_rate >= 0.5  THEN '3  50% to under 90%'
           WHEN coverage_rate > 0     THEN '4  under 50%'
           ELSE                            '5  none reported (0%)'
       END                                                           AS entity_coverage_band,
       count(*)                                                      AS entities,
       round(100.0 * count(*) / sum(count(*)) OVER (), 1)            AS pct_of_entities,
       sum(contracts)                                                AS contracts_held,
       round(100.0 * sum(contracts) / sum(sum(contracts)) OVER (), 1) AS pct_of_contracts,
       (SELECT min_contracts FROM params)                            AS min_contracts_threshold
FROM compared
GROUP BY 1
ORDER BY 1;

-- [RS5] Entities with the lowest coverage (reporting gaps; not a performance ranking)
WITH params AS (SELECT 20 AS min_contracts),
entity AS (
    SELECT buyer_id, max(buyer_name) AS buyer_name,
           count(*)                                              AS contracts,
           count(*) FILTER (WHERE has_implementation)            AS with_implementation_data,
           avg(CASE WHEN has_implementation THEN 1.0 ELSE 0.0 END) AS coverage_rate
    FROM analytics.vw_contract_implementation_coverage
    WHERE buyer_id_flag IS NULL
    GROUP BY buyer_id
),
scored AS (
    SELECT e.*,
           count(*)       OVER ()                                AS entities_in_comparison,
           rank()         OVER (ORDER BY coverage_rate ASC, contracts DESC) AS rank_lowest_coverage,
           percent_rank() OVER (ORDER BY coverage_rate)          AS percentile_position
    FROM entity e, params p
    WHERE e.contracts >= p.min_contracts
)
SELECT rank_lowest_coverage, buyer_id, buyer_name, contracts, with_implementation_data,
       round(100 * coverage_rate, 1)                             AS coverage_rate_pct,
       round((100 * percentile_position)::numeric, 0)            AS percentile_among_entities,
       entities_in_comparison
FROM scored
WHERE rank_lowest_coverage <= 15
ORDER BY rank_lowest_coverage;

-- [RS6] Lifecycle funnel (M-E03): how far did processes get in what was published?
-- The implementation row counts OCIDs with an implementation-tagged release (14,313); RS1 counts
-- contracts carrying implementation data (14,304). Both are reporting measures; do not mix them.
WITH stage_counts AS (
    SELECT highest_stage_rank, highest_stage, count(*) AS ocids_ending_here
    FROM analytics.vw_lifecycle_stage
    GROUP BY highest_stage_rank, highest_stage
),
reached AS (
    SELECT highest_stage_rank, highest_stage, ocids_ending_here,
           sum(ocids_ending_here) OVER (ORDER BY highest_stage_rank DESC) AS ocids_reaching_stage
    FROM stage_counts
)
SELECT highest_stage_rank                                          AS stage_order,
       highest_stage                                               AS stage,
       ocids_ending_here                                           AS ocids_whose_last_published_stage_is_this,
       ocids_reaching_stage                                        AS ocids_reaching_stage_or_beyond,
       round(100.0 * ocids_reaching_stage / max(ocids_reaching_stage) OVER (), 2)  AS pct_of_all_ocids,
       round(100.0 * ocids_reaching_stage
             / lag(ocids_reaching_stage) OVER (ORDER BY highest_stage_rank), 2)    AS conversion_from_previous_stage_pct
FROM reached
ORDER BY highest_stage_rank;
