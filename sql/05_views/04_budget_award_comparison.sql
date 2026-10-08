-- ============================================================
-- NOCOPO — Phase 7 analytical view: Pillar 4 — Budget-to-award comparison
-- ============================================================
-- Spec:   phase3_metric_eligibility.md, Pillar 4 (valid population for
--         budget-to-award comparison); C-08 (only budget vs. award is valid:
--         tender and contract values equal award value).
-- Grain:  one row per OCID
--
-- Eligible when ALL of:
--   the OCID has an eligible award (analytics.vw_award_value_eligible:
--     active, not EXTREME, not ZERO_VALUE)
--   the OCID has exactly ONE planning budget line                  [see note]
--   that budget is non-null, > 0, not EXTREME (DQ-06), not ZERO (DQ-16)
--
-- Note (single budget line): 3 OCIDs with an award also carry >1 unrelated
-- budget line (MULTI_PROJECT, C-06). No rule says which line the award
-- answers, so, like the single-award restriction on M-E02 (C-03), they are
-- excluded from this comparison rather than paired arbitrarily.
--
-- Derived columns (no further filtering):
--   variance_amount = award - budget;  award_to_budget_ratio = award / budget
-- ============================================================
CREATE OR REPLACE VIEW analytics.vw_budget_award_comparison AS
SELECT v.ocid,
       v.award_id,
       v.buyer_id,
       v.buyer_name,
       v.buyer_id_flag,
       v.procurement_method_details,
       b.budget_project_id,
       b.budget_amount,
       v.award_value_amount,
       v.award_value_amount - b.budget_amount                       AS variance_amount,
       round(v.award_value_amount / b.budget_amount, 4)             AS award_to_budget_ratio
FROM analytics.vw_award_value_eligible v
JOIN core.vw_process_snapshot s ON s.ocid = v.ocid
JOIN core.vw_budget_lines     b ON b.ocid = v.ocid
WHERE s.budget_line_count = 1
  AND b.budget_amount IS NOT NULL
  AND b.budget_amount > 0
  AND b.budget_amount_flag   IS NULL
  AND b.budget_monetary_flag IS NULL;

COMMENT ON VIEW analytics.vw_budget_award_comparison IS
    'Budget-to-award comparison (business question 3): OCIDs with an eligible award and '
    'exactly one valid planning budget line. Budget vs. award is the only valid financial '
    'comparison (C-08). Budget is a plan, not a contract estimate; ratios are descriptive.';
