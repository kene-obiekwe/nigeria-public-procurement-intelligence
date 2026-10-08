-- ============================================================
-- NOCOPO — Phase 7 analytical views: lifecycle conversion (M-E03) and
--                                     implementation reporting coverage (M-I01)
-- ============================================================

-- ------------------------------------------------------------
-- M-E03: one row per OCID (all OCIDs except the 412 of the DQ-20 portal test entity)
-- Highest lifecycle stage present across ALL releases of the OCID.
-- Stage order: planning(1) < tender(2) < award(3) < contract(4) < implementation(5)
-- Conversion rate stage k = COUNT(highest_stage_rank >= k) / COUNT(highest_stage_rank >= k-1)
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW analytics.vw_lifecycle_stage AS
SELECT s.ocid,
       s.buyer_id,
       d.buyer_name,
       d.buyer_id_flag,
       s.release_count,
       s.tags_observed,
       CASE
           WHEN 'implementation' = ANY (s.tags_observed) THEN 5
           WHEN 'contract'       = ANY (s.tags_observed) THEN 4
           WHEN 'award'          = ANY (s.tags_observed) THEN 3
           WHEN 'tender'         = ANY (s.tags_observed) THEN 2
           WHEN 'planning'       = ANY (s.tags_observed) THEN 1
       END                                                   AS highest_stage_rank,
       CASE
           WHEN 'implementation' = ANY (s.tags_observed) THEN 'implementation'
           WHEN 'contract'       = ANY (s.tags_observed) THEN 'contract'
           WHEN 'award'          = ANY (s.tags_observed) THEN 'award'
           WHEN 'tender'         = ANY (s.tags_observed) THEN 'tender'
           WHEN 'planning'       = ANY (s.tags_observed) THEN 'planning'
       END                                                   AS highest_stage
FROM core.vw_process_snapshot s
JOIN core.dim_buyer d ON d.buyer_id = s.buyer_id
WHERE d.test_entity_flag IS NULL;                  -- DQ-20

COMMENT ON VIEW analytics.vw_lifecycle_stage IS
    'M-E03: every OCID with its highest reported lifecycle stage across all releases. '
    'Conversion reflects what was published to NOCOPO, not what occurred.';


-- ------------------------------------------------------------
-- M-I01: one row per snapshot contract (contract deduplicated per OCID)
-- has_implementation = contract carries implementation transactions or milestones
-- M-I01 = COUNT(*) FILTER (WHERE has_implementation) / COUNT(*)
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW analytics.vw_contract_implementation_coverage AS
SELECT s.ocid,
       c.contract_id,
       c.release_id                AS contract_release_id,
       s.buyer_id,
       d.buyer_name,
       d.buyer_id_flag,
       c.status                    AS contract_status,
       c.has_implementation,
       coalesce(x.transaction_count, 0)              AS transaction_count,
       coalesce(m.implementation_milestone_count, 0) AS implementation_milestone_count
FROM core.vw_process_snapshot s
JOIN stg.contracts  c ON c.contract_id = s.contract_id
JOIN core.dim_buyer d ON d.buyer_id    = s.buyer_id
LEFT JOIN (SELECT contract_id, count(*) AS transaction_count
           FROM stg.transactions GROUP BY contract_id) x ON x.contract_id = c.contract_id
LEFT JOIN (SELECT contract_id, count(*) AS implementation_milestone_count
           FROM stg.milestones WHERE milestone_source = 'IMPLEMENTATION'
           GROUP BY contract_id) m ON m.contract_id = c.contract_id
WHERE d.test_entity_flag IS NULL;                  -- DQ-20

COMMENT ON VIEW analytics.vw_contract_implementation_coverage IS
    'M-I01: one row per contract (snapshot). has_implementation indicates that implementation '
    'data was published, not that the contract was performed. Transaction values are not '
    'summed (DQ-12 unresolved); transaction dates do not exist (DQ-11).';
