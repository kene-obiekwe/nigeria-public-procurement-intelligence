-- ============================================================
-- NOCOPO — Phase 7 analytical views: Pillars 3 & 4 — Award value (M-V01)
--                                      and supplier concentration (M-S01)
-- ============================================================
-- Spec:   phase3_metric_eligibility.md, Pillar 3, Pillar 4, M-S01, M-V01
--
-- Award deduplication ("deduplicate by award ID across releases per OCID"):
--   satisfied by the process snapshot, which takes ONE award per OCID from
--   the latest award release (Phase 4 v1.1 §6.4, §17 issue 17.3).
--
-- vw_award_value_eligible  (M-V01)    grain: one award per OCID
--   award status = 'active'
--   award_value_flag IS NULL           (DQ-07: exclude EXTREME, FCTA NGN 1.004T)
--   award_monetary_flag IS NULL        (DQ-16: exclude ZERO_VALUE -> value > 0)
--   M-V01 = MEDIAN(award_value_amount)
--
-- vw_supplier_award_eligible (M-S01)  grain: one row per (award, distinct supplier)
--   all M-V01 conditions, plus
--   supplier_id_flag IS NULL           (DQ-14: exclude bare 'NG-BPP-' supplier)
--   O-3: the 24 repeated suppliers[] entries (6 awards) are collapsed with
--        DISTINCT (award_id, supplier_id). Staging keeps them as published.
--   Value attribution: every award has exactly one distinct supplier
--   (Gate B check EN-13), so the full award value is attributed to it.
--   Phase 3 defines no split rule for multi-supplier awards; check AV-07
--   fails if one ever appears, and the rule must then be decided.
--   M-S01 = top-N SUM(award_value_amount) by supplier_id / SUM over all rows
-- ============================================================
CREATE OR REPLACE VIEW analytics.vw_award_value_eligible AS
SELECT s.ocid,
       a.award_id,
       a.release_id                AS award_release_id,
       s.buyer_id,
       d.buyer_name,
       d.buyer_id_flag,
       t.procurement_method_details,
       a.award_value_amount,
       a.award_value_currency,
       a.award_date,
       a.award_date_flag
FROM core.vw_process_snapshot s
JOIN stg.awards     a ON a.award_id   = s.award_id
JOIN core.dim_buyer d ON d.buyer_id   = s.buyer_id
LEFT JOIN stg.tender t ON t.release_id = s.tender_release_id
WHERE a.status = 'active'
  AND a.award_value_flag    IS NULL
  AND a.award_monetary_flag IS NULL;

COMMENT ON VIEW analytics.vw_award_value_eligible IS
    'M-V01 eligible population: one active award per OCID (snapshot), excluding EXTREME '
    '(DQ-07) and ZERO_VALUE (DQ-16). Award value is the single published value per '
    'process: tender and contract values equal it (C-08).';


CREATE OR REPLACE VIEW analytics.vw_supplier_award_eligible AS
WITH award_supplier AS (
    SELECT DISTINCT award_id, supplier_id        -- O-3: collapse repeated suppliers[] entries
    FROM stg.award_suppliers
),
supplier_count AS (
    SELECT award_id, count(*) AS distinct_supplier_count
    FROM award_supplier
    GROUP BY award_id
)
SELECT v.ocid,
       v.award_id,
       v.buyer_id,
       v.buyer_name,
       v.buyer_id_flag,
       v.procurement_method_details,
       x.supplier_id,
       sup.supplier_name,
       sup.name_variant_count,
       c.distinct_supplier_count,
       v.award_value_amount
FROM analytics.vw_award_value_eligible v
JOIN award_supplier    x   ON x.award_id    = v.award_id
JOIN supplier_count    c   ON c.award_id    = v.award_id
JOIN core.dim_supplier sup ON sup.supplier_id = x.supplier_id
WHERE sup.supplier_id_flag IS NULL;

COMMENT ON VIEW analytics.vw_supplier_award_eligible IS
    'M-S01 eligible population: one row per (eligible award, distinct supplier). Excludes '
    'bare NG-BPP- supplier IDs (DQ-14). Repeated suppliers[] entries collapsed (O-3). '
    'Lower-bound concentration: 1,483 supplier IDs have >1 name variant (DQ-13), no merging.';
