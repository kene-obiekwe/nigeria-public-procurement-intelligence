-- ============================================================
-- NOCOPO — Phase 10.1 analytical view: DQ-21 possible award scale errors
-- ============================================================
-- Spec:   phase3_data_quality_decision_log.md DQ-21 (correction C-13);
--         evidence docs/phase10_findings/source_verification.md §A, §C, §E.
-- Grain:  one row per FLAGGED award (awards that pass neither test are absent)
-- Treatment: FLAG + sensitivity result sets. Nothing is excluded: no existing
--         view, metric population or dashboard measure reads this view.
--
-- Candidate population: M-V01 eligible awards (analytics.vw_award_value_eligible:
--   active, not EXTREME (DQ-07), not ZERO_VALUE (DQ-16), DQ-20 test entity
--   removed). DQ-07 EXTREME awards are therefore never flagged here.
--
-- An award is flagged POSSIBLE_SCALE_ERROR when it passes either test:
--   DROPPED_DECIMAL  the award is in the budget-to-award comparison
--                    (analytics.vw_budget_award_comparison), its value is a
--                    whole number of naira, and award / budget lies between
--                    50 and 200 (that is, award / 100 is within a factor of two
--                    of the budget line): the signature of a two-decimal amount
--                    entered without its decimal point.
--   SIBLING_LOT      the award has a usable supplier ID (M-S01 population),
--                    a complete buyer ID (DQ-19 bare buyer not matched), and
--                    is at least 500 times the largest OTHER eligible award of
--                    the same supplier from the same buyer.
--
-- A flag says the published amount is inconsistent with the award's own
-- process record. It does not say the amount is wrong, and it says nothing
-- about the parties. Confirm against source documents before acting on it.
-- ============================================================
CREATE OR REPLACE VIEW analytics.vw_award_scale_flag AS
WITH
aw AS MATERIALIZED (
    SELECT ocid, award_id, buyer_id, buyer_name, buyer_id_flag, procurement_method_details, award_value_amount
    FROM analytics.vw_award_value_eligible),
bva AS MATERIALIZED (
    SELECT award_id, budget_project_id, budget_amount, award_value_amount / budget_amount AS ratio
    FROM analytics.vw_budget_award_comparison),
sup AS MATERIALIZED (
    SELECT award_id, buyer_id, supplier_id, award_value_amount
    FROM analytics.vw_supplier_award_eligible
    WHERE buyer_id_flag IS NULL),
-- the largest other award of the same supplier from the same buyer
sibling AS (
    SELECT DISTINCT ON (a.award_id)
           a.award_id, a.supplier_id, b.award_id AS sibling_award_id, b.award_value_amount AS sibling_award_value
    FROM sup a
    JOIN sup b ON b.supplier_id = a.supplier_id AND b.buyer_id = a.buyer_id AND b.award_id <> a.award_id
    ORDER BY a.award_id, b.award_value_amount DESC, b.award_id),
tested AS (
    SELECT aw.*,
           bva.budget_project_id,
           bva.budget_amount,
           bva.ratio                                                     AS award_to_budget_ratio,
           s.supplier_id,
           s.sibling_award_id,
           s.sibling_award_value,
           aw.award_value_amount / nullif(s.sibling_award_value, 0)      AS ratio_to_sibling,
           coalesce(aw.award_value_amount = trunc(aw.award_value_amount)
                    AND bva.ratio BETWEEN 50 AND 200, false)             AS dropped_decimal_test,
           coalesce(aw.award_value_amount >= 500 * s.sibling_award_value, false) AS sibling_lot_test
    FROM aw
    LEFT JOIN bva USING (award_id)
    LEFT JOIN sibling s USING (award_id))
SELECT ocid,
       award_id,
       buyer_id,
       buyer_name,
       procurement_method_details,
       supplier_id,
       award_value_amount,
       'POSSIBLE_SCALE_ERROR'::varchar(32)                                AS scale_flag,           -- DQ-21
       CASE WHEN dropped_decimal_test AND sibling_lot_test THEN 'DROPPED_DECIMAL+SIBLING_LOT'
            WHEN dropped_decimal_test THEN 'DROPPED_DECIMAL'
            ELSE 'SIBLING_LOT' END::varchar(32)                           AS flag_reason,
       dropped_decimal_test,
       sibling_lot_test,
       budget_project_id,
       budget_amount,
       round(award_to_budget_ratio, 4)                                    AS award_to_budget_ratio,
       sibling_award_id,
       sibling_award_value,
       round(ratio_to_sibling, 1)                                         AS ratio_to_sibling
FROM tested
WHERE dropped_decimal_test OR sibling_lot_test;

COMMENT ON VIEW analytics.vw_award_scale_flag IS
    'DQ-21 (C-13): M-V01 awards whose amount is inconsistent with their own process record '
    '(DROPPED_DECIMAL: whole-naira award at 50-200x its budget line; SIBLING_LOT: >= 500x the same '
    'supplier''s largest other award from the same buyer). FLAG only; used by sensitivity result sets.';
