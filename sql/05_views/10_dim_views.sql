-- ============================================================
-- NOCOPO — Phase 9 presentation dimensions for Power BI
-- ============================================================
-- Two small dimension views so that one buyer slicer and one procurement-method
-- slicer can filter every fact view. They hold no metric and no eligibility
-- logic; they only list the members that the fact views use.
--
-- analytics.vw_dim_buyer
--   Grain: one row per complete procuring-entity ID (665).
--   Excludes the bare 'NG-BPP-' buyer (DQ-19) and the portal test entity
--   NG-BPP-BPP-NOC-90 (DQ-20), exactly like analytics.vw_entity_benchmark.
--   Process-level fact rows that carry the bare buyer ID have no dimension
--   row; Power BI shows them under "(Blank)" when a visual is split by buyer.
--   buyer_name is NOT unique (four names are shared by two IDs, which are
--   deliberately not merged), so the model must key on buyer_id and show
--   buyer_label in slicers.
--
-- analytics.vw_dim_procurement_method
--   Grain: one row per procurement method used by any fact view, plus the
--   label '(method not stated)' for facts whose tender names no method.
--   Procurement method is the only category-like field in the source.
--   The fact views carry NULL for "not stated"; Power Query replaces NULL with
--   the same label so the relationship can match (see dashboard/README.md).
-- ============================================================
CREATE OR REPLACE VIEW analytics.vw_dim_buyer AS
SELECT d.buyer_id,
       d.buyer_name,
       regexp_replace(d.buyer_id, '^NG-BPP-BPP-NOC-', '')                 AS buyer_code,
       d.buyer_name || ' (' || regexp_replace(d.buyer_id, '^NG-BPP-BPP-NOC-', '') || ')' AS buyer_label
FROM core.dim_buyer d
WHERE d.buyer_id_flag    IS NULL        -- DQ-19: bare NG-BPP- is not an entity
  AND d.test_entity_flag IS NULL;       -- DQ-20: portal test entity

COMMENT ON VIEW analytics.vw_dim_buyer IS
    'Buyer dimension for Power BI: 665 complete procuring-entity IDs (DQ-19 bare ID and DQ-20 test '
    'entity excluded). buyer_label disambiguates the four names shared by two IDs. Key: buyer_id.';


CREATE OR REPLACE VIEW analytics.vw_dim_procurement_method AS
SELECT m.procurement_method,
       (m.procurement_method = '(method not stated)') AS is_not_stated
FROM (SELECT DISTINCT coalesce(procurement_method_details, '(method not stated)') AS procurement_method
      FROM (SELECT procurement_method_details FROM analytics.vw_competition_eligible
            UNION ALL SELECT procurement_method_details FROM analytics.vw_award_value_eligible
            UNION ALL SELECT procurement_method_details FROM analytics.vw_supplier_award_eligible
            UNION ALL SELECT procurement_method_details FROM analytics.vw_budget_award_comparison
            UNION ALL SELECT procurement_method_details FROM analytics.vw_tender_duration_eligible
            UNION ALL SELECT procurement_method_details FROM analytics.vw_award_lag_eligible) f) m;

COMMENT ON VIEW analytics.vw_dim_procurement_method IS
    'Procurement-method dimension for Power BI: every method used by a fact view, plus '
    '''(method not stated)''. Key: procurement_method. The only category-like field in the source.';
