-- ============================================================
-- NOCOPO — Phase 7 analytical view: Pillar 2 — Competition (M-C01, M-C02)
-- ============================================================
-- Spec:   phase3_metric_eligibility.md, Pillar 2, M-C01, M-C02
-- Grain:  one row per OCID (one tender per process: snapshot tender)
--
-- Row population = SENSITIVITY population (Pillar 2):
--   tender present in the process snapshot
--   tender status IS NOT NULL                      (Pillar 2 minimum requirement)
--   tenderer_count_flag IN ('NORMAL','ELEVATED')   (DQ-05: ANOMALOUS > 1,000 excluded)
-- PRIMARY population (M-C01 median, M-C02 denominator):
--   in_primary_population = (tenderer_count_flag = 'NORMAL', 1-100 tenderers)
--
-- M-C01 = MEDIAN(number_of_tenderers) WHERE in_primary_population
-- M-C02 = COUNT(*) FILTER (WHERE is_single_bidder) / COUNT(*), both WHERE in_primary_population
-- Missing participation is never treated as zero: number_of_tenderers is 0% null and >= 1.
-- buyer_id_flag is carried, not filtered: these are process-level metrics. Entity-level
-- use must filter buyer_id_flag IS NULL (DQ-19); analytics.vw_entity_benchmark does.
-- ============================================================
CREATE OR REPLACE VIEW analytics.vw_competition_eligible AS
SELECT s.ocid,
       t.release_id                          AS tender_release_id,
       t.tender_id,
       s.buyer_id,
       d.buyer_name,
       d.buyer_id_flag,
       t.procurement_method_details,
       t.status                              AS tender_status,
       t.number_of_tenderers,
       t.tenderer_count_flag,
       (t.tenderer_count_flag = 'NORMAL')    AS in_primary_population,
       (t.number_of_tenderers = 1)           AS is_single_bidder
FROM core.vw_process_snapshot s
JOIN stg.tender     t ON t.release_id = s.tender_release_id
JOIN core.dim_buyer d ON d.buyer_id   = s.buyer_id
WHERE t.status IS NOT NULL
  AND t.tenderer_count_flag IN ('NORMAL', 'ELEVATED');

COMMENT ON VIEW analytics.vw_competition_eligible IS
    'M-C01/M-C02: one tender per OCID (snapshot). Rows = sensitivity population (NORMAL + '
    'ELEVATED, status not null); primary population = in_primary_population (NORMAL, 1-100). '
    'ANOMALOUS (>1,000, DQ-05) excluded. numberOfTenderers meaning (bids vs. EOIs) unconfirmed.';
