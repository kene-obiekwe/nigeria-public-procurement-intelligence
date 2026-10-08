-- ============================================================
-- NOCOPO — Phase 7 analytical view: metric population register
-- ============================================================
-- One row per metric: the candidate population it is drawn from, and how
-- many records satisfy its eligibility rule. Intended to be shown next to
-- every metric (Implementation Plan risk: "presenting a metric without also
-- reporting its eligible population size").
-- DQ-20: candidate populations exclude the portal test entity (NG-BPP-BPP-NOC-90),
-- as do the eligible populations, so the percentages compare like with like.
-- Phase 8.1: reads the materialised core snapshot, so it runs in about 2 s.
-- ============================================================
CREATE OR REPLACE VIEW analytics.vw_metric_population AS
WITH snap AS (
    SELECT s.* FROM core.vw_process_snapshot s
    JOIN core.dim_buyer d ON d.buyer_id = s.buyer_id
    WHERE d.test_entity_flag IS NULL
),
bl AS (
    SELECT b.* FROM core.vw_budget_lines b
    JOIN core.dim_buyer d ON d.buyer_id = b.buyer_id
    WHERE d.test_entity_flag IS NULL
),
p (sort_order, metric_id, metric_name, grain, candidate_population, candidate_count, eligible_count) AS (VALUES
 (1, 'M-P01', 'Total planned budget by entity', 'budget line',
     'Budget lines (latest release per ocid x projectID)',
     (SELECT count(*) FROM bl),
     (SELECT count(*) FROM analytics.vw_budget_eligible)),
 (2, 'M-C01 / M-C02', 'Median tenderers; single-bidder rate (primary)', 'OCID',
     'Snapshot OCIDs with a tender',
     (SELECT count(tender_id) FROM snap),
     (SELECT count(*) FROM analytics.vw_competition_eligible WHERE in_primary_population)),
 (3, 'M-C01 (sensitivity)', 'Median tenderers, NORMAL + ELEVATED', 'OCID',
     'Snapshot OCIDs with a tender',
     (SELECT count(tender_id) FROM snap),
     (SELECT count(*) FROM analytics.vw_competition_eligible)),
 (4, 'M-V01', 'Median award value', 'OCID (one award)',
     'Snapshot OCIDs with an award',
     (SELECT count(award_id) FROM snap),
     (SELECT count(*) FROM analytics.vw_award_value_eligible)),
 (5, 'M-S01', 'Top-supplier award value concentration', 'award x supplier',
     'M-V01 eligible awards',
     (SELECT count(*) FROM analytics.vw_award_value_eligible),
     (SELECT count(DISTINCT award_id) FROM analytics.vw_supplier_award_eligible)),
 (6, 'P4-BvA', 'Budget-to-award comparison', 'OCID',
     'M-V01 eligible awards',
     (SELECT count(*) FROM analytics.vw_award_value_eligible),
     (SELECT count(*) FROM analytics.vw_budget_award_comparison)),
 (7, 'M-E01', 'Median tender duration (days)', 'OCID',
     'Snapshot OCIDs with a tender',
     (SELECT count(tender_id) FROM snap),
     (SELECT count(*) FROM analytics.vw_tender_duration_eligible)),
 (8, 'M-E02', 'Median award lag (days)', 'OCID',
     'Snapshot OCIDs with a tender and an award',
     (SELECT count(*) FROM snap WHERE tender_id IS NOT NULL AND award_id IS NOT NULL),
     (SELECT count(*) FROM analytics.vw_award_lag_eligible)),
 (9, 'P5-SIG', 'Contract signature lag (days)', 'contract',
     'Snapshot contracts',
     (SELECT count(contract_id) FROM snap),
     (SELECT count(*) FROM analytics.vw_signature_lag_eligible)),
 (10, 'M-E03', 'Lifecycle conversion', 'OCID',
     'All OCIDs (no exclusions by spec)',
     (SELECT count(*) FROM snap),
     (SELECT count(*) FROM analytics.vw_lifecycle_stage)),
 (11, 'M-I01', 'Implementation reporting coverage', 'contract',
     'Snapshot contracts (no exclusions by spec)',
     (SELECT count(contract_id) FROM snap),
     (SELECT count(*) FROM analytics.vw_contract_implementation_coverage)),
 (12, 'ENTITY', 'Procuring-entity benchmark', 'buyer',
     'Buyer IDs (core.dim_buyer, DQ-20 test entity excluded)',
     (SELECT count(*) FROM core.dim_buyer WHERE test_entity_flag IS NULL),
     (SELECT count(*) FROM analytics.vw_entity_benchmark))
)
SELECT metric_id, metric_name, grain, candidate_population, candidate_count, eligible_count,
       round(100.0 * eligible_count / nullif(candidate_count, 0), 1) AS eligible_pct
FROM p
ORDER BY sort_order;

COMMENT ON VIEW analytics.vw_metric_population IS
    'Eligible population register: candidate and eligible counts for every Phase 7 metric. '
    'Show alongside any reported metric.';
