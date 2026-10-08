-- ============================================================
-- NOCOPO — Phase 7 analytical view: Pillar 1 — Planned budget (M-P01)
-- ============================================================
-- Spec:   docs/phase3_data_quality/phase3_metric_eligibility.md, Pillar 1 and M-P01
--         (aggregation grain amended by C-06)
-- Grain:  one row per eligible budget line (ocid, budget_project_id)
-- Source: core.vw_budget_lines (latest release per budget line)
--
-- Eligible when ALL of:
--   budget_amount IS NOT NULL AND budget_amount >= 0      (M-P01 required fields)
--   budget_amount_flag IS NULL                            (DQ-06: exclude EXTREME >= NGN 1T)
--   budget_monetary_flag IS NULL                          (DQ-16: exclude ZERO_VALUE)
--   release party_flag IS NULL                            (DQ-18: exclude NO_PARTIES from buyer analysis)
--   buyer_id_flag IS NULL                                 (DQ-19: exclude bare 'NG-BPP-' buyer)
--   test_entity_flag IS NULL                              (DQ-20: exclude portal test entity)
--
-- Population (2026-10-07): see analytics.vw_metric_population and
-- docs/phase7_analytics/phase7_analytical_views.md
-- M-P01 = SUM(budget_amount) GROUP BY buyer_id.
-- ============================================================
CREATE OR REPLACE VIEW analytics.vw_budget_eligible AS
SELECT b.ocid,
       b.budget_project_id,
       b.release_id,
       b.buyer_id,
       d.buyer_name,
       b.budget_amount,
       b.budget_currency,
       b.budget_description,
       b.budget_project,
       s.multi_project_flag
FROM core.vw_budget_lines      b
JOIN stg.releases             r ON r.release_id = b.release_id
JOIN core.dim_buyer           d ON d.buyer_id   = b.buyer_id
JOIN core.vw_process_snapshot s ON s.ocid       = b.ocid
WHERE b.budget_amount IS NOT NULL
  AND b.budget_amount >= 0
  AND b.budget_amount_flag   IS NULL
  AND b.budget_monetary_flag IS NULL
  AND r.party_flag           IS NULL
  AND d.buyer_id_flag        IS NULL
  AND d.test_entity_flag     IS NULL;

COMMENT ON VIEW analytics.vw_budget_eligible IS
    'M-P01 eligible population: one row per planning budget line (C-06), latest release per line. '
    'Excludes EXTREME (DQ-06), ZERO_VALUE (DQ-16), NO_PARTIES releases (DQ-18) and the bare '
    'NG-BPP- buyer (DQ-19) and the portal test entity (DQ-20). Planned budget, not spend.';
