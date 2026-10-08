-- ============================================================
-- NOCOPO — Phase 7 analytical views: Pillar 5 — Procurement timing
-- ============================================================
-- Spec:   phase3_metric_eligibility.md, Pillar 5, M-E01, M-E02 (+ C-03)
-- Rules common to all three views (Pillar 5 minimum requirements):
--   both interval dates non-null and flagged VALID (DQ-08 PLACEHOLDER,
--   DQ-09 FUTURE/IMPOSSIBLE excluded); end >= start (no negative
--   durations); release_date is never used (DQ-10).
-- Dates come from the snapshot section that carries them (tender from the
-- snapshot tender release, award/contract from the snapshot award release).
-- ============================================================

-- M-E01: tender open duration — one row per OCID
CREATE OR REPLACE VIEW analytics.vw_tender_duration_eligible AS
SELECT s.ocid,
       t.release_id                                 AS tender_release_id,
       s.buyer_id,
       d.buyer_name,
       d.buyer_id_flag,
       t.procurement_method_details,
       t.tender_start_date,
       t.tender_end_date,
       (t.tender_end_date - t.tender_start_date)    AS tender_duration_days
FROM core.vw_process_snapshot s
JOIN stg.tender     t ON t.release_id = s.tender_release_id
JOIN core.dim_buyer d ON d.buyer_id   = s.buyer_id
WHERE t.tender_start_date_flag = 'VALID'
  AND t.tender_end_date_flag   = 'VALID'
  AND t.tender_end_date >= t.tender_start_date;

COMMENT ON VIEW analytics.vw_tender_duration_eligible IS
    'M-E01: one row per OCID with VALID tender start and end dates and end >= start. '
    'M-E01 = MEDIAN(tender_duration_days). Covers a minority of tenders (start date 47.7% null).';


-- M-E02: award lag (tender start -> award date) — single-award OCIDs only (C-03)
CREATE OR REPLACE VIEW analytics.vw_award_lag_eligible AS
SELECT s.ocid,
       a.award_id,
       s.buyer_id,
       d.buyer_name,
       d.buyer_id_flag,
       t.procurement_method_details,
       a.status                                     AS award_status,
       t.tender_start_date,
       a.award_date,
       (a.award_date - t.tender_start_date)         AS award_lag_days
FROM core.vw_process_snapshot s
JOIN stg.tender     t ON t.release_id = s.tender_release_id
JOIN stg.awards     a ON a.award_id   = s.award_id
JOIN core.dim_buyer d ON d.buyer_id   = s.buyer_id
-- C-03 single-award guard: after the snapshot every OCID carries at most one
-- award (max 1 award per release, one award release per OCID), so this is
-- always true today; kept so the rule stays explicit.
JOIN (SELECT release_id, count(*) AS awards_in_release
      FROM stg.awards GROUP BY release_id) ac ON ac.release_id = s.award_release_id
WHERE t.tender_start_date_flag = 'VALID'
  AND a.award_date_flag        = 'VALID'
  AND a.award_date >= t.tender_start_date        -- excludes the award-before-tender conflicts
  AND ac.awards_in_release = 1;

COMMENT ON VIEW analytics.vw_award_lag_eligible IS
    'M-E02: single-award OCIDs with VALID tender start and award dates and award >= tender '
    'start. M-E02 = MEDIAN(award_lag_days). Award status is carried, not filtered (M-E02 '
    'specifies none).';


-- Pillar 5 contract signature lag (award date -> dateSigned). Defined in the
-- Pillar 5 valid population; Phase 3 assigns it no metric ID.
CREATE OR REPLACE VIEW analytics.vw_signature_lag_eligible AS
SELECT s.ocid,
       c.contract_id,
       s.buyer_id,
       d.buyer_name,
       d.buyer_id_flag,
       a.award_date,
       c.date_signed,
       (c.date_signed - a.award_date)               AS signature_lag_days
FROM core.vw_process_snapshot s
JOIN stg.awards     a ON a.award_id    = s.award_id
JOIN stg.contracts  c ON c.contract_id = s.contract_id
JOIN core.dim_buyer d ON d.buyer_id    = s.buyer_id
WHERE a.award_date_flag  = 'VALID'
  AND c.date_signed_flag = 'VALID'
  AND c.date_signed >= a.award_date;             -- excludes the signed-before-award conflicts

COMMENT ON VIEW analytics.vw_signature_lag_eligible IS
    'Pillar 5 contract signature lag: snapshot contracts with VALID award and signature '
    'dates and dateSigned >= award date. No Phase 3 metric ID; reported as a secondary '
    'timing measure.';
