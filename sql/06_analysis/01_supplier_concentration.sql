-- ============================================================
-- NOCOPO — Phase 8, business question 1: supplier concentration
-- ============================================================
-- Question: How concentrated is awarded procurement value among suppliers, and
--           how does concentration vary by procuring entity or procurement
--           category?  (Scope s.6, Pillar 3)
-- Metric:   M-S01 (phase3_metric_eligibility.md v1.2)
-- Source:   analytics.vw_supplier_award_eligible (one row per award x distinct
--           supplier). Window functions rank suppliers and build cumulative share.
-- Run:      psql -h localhost -p 5433 -U postgres -d nocopo_db -f sql/06_analysis/01_supplier_concentration.sql
-- DQ-20 (Phase 8.1): the portal test entity NG-BPP-BPP-NOC-90 is excluded by every
--           analytics view used here, so it appears in no population or ranking.
--
-- ELIGIBLE POPULATION (M-S01): active awards, not EXTREME (DQ-07) and not zero
-- (DQ-16), with a supplier ID that is not the bare 'NG-BPP-' (DQ-14). RS1 shows
-- the size of that population next to the awards it is drawn from.
--
-- LIMITATIONS TO STATE WITH EVERY RESULT
--   1. Excluded value. Awards whose only supplier ID is the bare 'NG-BPP-' cannot
--      be attributed to any supplier and are left out (RS1 gives the count and
--      value). Concentration is measured on the remaining awards only.
--   2. Lower bound. Suppliers are identified by source ID and never merged on
--      name similarity (DQ-13: 1,483 IDs carry several name variants; DQ-14:
--      571 names carry several IDs; DQ-15 mapping is specification only). If one
--      real supplier uses several IDs, true concentration is higher than shown.
--   3. Full award value is attributed to the single supplier on each award
--      (every eligible award has exactly one distinct supplier; check AV-07).
--   4. "Procurement category" is not a field in the source. Procurement method
--      (procurement_method_details) is the closest segmentation available.
--   5. Concentration is a descriptive pattern. It does not by itself indicate
--      misconduct; high shares may reflect a small market or a framework buyer.
--   6. Entity-level shares are shown only for entities with at least
--      min_awards eligible awards (parameter in RS5), because a buyer with two
--      awards has a top-supplier share of 50-100% by construction.
-- ============================================================

-- [RS1] Eligible population and the disclosed exclusion (every M-S01 figure must carry this)
WITH candidate AS (
    SELECT count(*) AS candidate_awards, sum(award_value_amount) AS candidate_value
    FROM analytics.vw_award_value_eligible                      -- M-V01 eligible awards
),
eligible AS (
    SELECT count(DISTINCT award_id)  AS eligible_awards,
           count(DISTINCT supplier_id) AS distinct_suppliers,
           sum(award_value_amount)   AS eligible_value
    FROM analytics.vw_supplier_award_eligible
)
SELECT 'M-S01'                                                   AS metric,
       c.candidate_awards,
       e.eligible_awards,
       round(100.0 * e.eligible_awards / c.candidate_awards, 1)  AS eligible_pct_of_candidate,
       e.distinct_suppliers,
       round(e.eligible_value / 1e9, 1)                          AS eligible_value_ngn_bn,
       c.candidate_awards - e.eligible_awards                    AS excluded_awards_bare_supplier_id,
       round((c.candidate_value - e.eligible_value) / 1e9, 1)    AS excluded_value_ngn_bn,
       round(100.0 * (c.candidate_value - e.eligible_value) / c.candidate_value, 1)
                                                                 AS excluded_pct_of_candidate_value
FROM candidate c CROSS JOIN eligible e;

-- [RS1b] Register entry for M-S01 (analytics.vw_metric_population; a few seconds)
SELECT metric_id, candidate_population, candidate_count, eligible_count, eligible_pct
FROM analytics.vw_metric_population
WHERE metric_id = 'M-S01';

-- [RS2] Overall concentration: share held by the largest suppliers, Herfindahl index, depth to 50% / 80%
WITH supplier_total AS (
    SELECT supplier_id, count(*) AS awards, sum(award_value_amount) AS value
    FROM analytics.vw_supplier_award_eligible
    GROUP BY supplier_id
),
ranked AS (
    SELECT supplier_id, awards, value,
           row_number() OVER (ORDER BY value DESC, supplier_id)           AS supplier_rank,
           value / sum(value) OVER ()                                     AS value_share,
           sum(value) OVER (ORDER BY value DESC, supplier_id)
               / sum(value) OVER ()                                       AS cumulative_share
    FROM supplier_total
)
SELECT count(*)                                                           AS suppliers,
       sum(awards)                                                        AS awards_in_scope,
       round(sum(value) / 1e9, 1)                                         AS value_in_scope_ngn_bn,
       round(100 * sum(value_share) FILTER (WHERE supplier_rank <= 1), 2)   AS top_1_share_pct,
       round(100 * sum(value_share) FILTER (WHERE supplier_rank <= 5), 2)   AS top_5_share_pct,
       round(100 * sum(value_share) FILTER (WHERE supplier_rank <= 10), 2)  AS top_10_share_pct,
       round(100 * sum(value_share) FILTER (WHERE supplier_rank <= 20), 2)  AS top_20_share_pct,
       round(100 * sum(value_share) FILTER (WHERE supplier_rank <= 100), 2) AS top_100_share_pct,
       round((sum(value_share * value_share) * 10000)::numeric, 1)          AS herfindahl_index_0_to_10000,
       min(supplier_rank) FILTER (WHERE cumulative_share >= 0.5)            AS suppliers_to_reach_50_pct,
       min(supplier_rank) FILTER (WHERE cumulative_share >= 0.8)            AS suppliers_to_reach_80_pct,
       count(*) FILTER (WHERE awards = 1)                                   AS suppliers_with_one_award
FROM ranked;

-- [RS3] Top 20 suppliers by awarded value (rank, share, cumulative share)
WITH supplier_total AS (
    SELECT supplier_id,
           max(supplier_name)       AS supplier_name,
           max(name_variant_count)  AS name_variant_count,
           count(*)                 AS awards,
           count(DISTINCT buyer_id) AS procuring_entities,
           sum(award_value_amount)  AS value
    FROM analytics.vw_supplier_award_eligible
    GROUP BY supplier_id
),
ranked AS (
    SELECT t.*,
           rank() OVER (ORDER BY value DESC)                                   AS value_rank,
           100 * value / sum(value) OVER ()                                    AS share_pct,
           100 * sum(value) OVER (ORDER BY value DESC, supplier_id) / sum(value) OVER () AS cumulative_share_pct
    FROM supplier_total t
)
SELECT value_rank, supplier_id, supplier_name,
       awards, procuring_entities,
       round(value / 1e9, 2)           AS value_ngn_bn,
       round(share_pct, 2)             AS share_pct,
       round(cumulative_share_pct, 2)  AS cumulative_share_pct,
       CASE WHEN name_variant_count > 1 THEN 'several name variants (DQ-13): share may be understated'
            ELSE 'single name' END     AS identity_note
FROM ranked
WHERE value_rank <= 20
ORDER BY value_rank;

-- [RS4] Concentration by procurement method (the only category-like field available)
WITH method_supplier AS (
    SELECT coalesce(procurement_method_details, '(method not stated)') AS procurement_method,
           supplier_id,
           count(*)                AS awards,
           sum(award_value_amount) AS value
    FROM analytics.vw_supplier_award_eligible
    GROUP BY 1, 2
),
ranked AS (
    SELECT procurement_method, supplier_id, awards, value,
           sum(value) OVER (PARTITION BY procurement_method)                        AS method_value,
           row_number() OVER (PARTITION BY procurement_method ORDER BY value DESC, supplier_id) AS rank_in_method
    FROM method_supplier
)
SELECT procurement_method,
       sum(awards)                                                       AS eligible_awards,
       count(*)                                                          AS suppliers,
       round(max(method_value) / 1e9, 2)                                 AS value_ngn_bn,
       round(100 * sum(value) FILTER (WHERE rank_in_method <= 1) / max(method_value), 1) AS top_1_share_pct,
       round(100 * sum(value) FILTER (WHERE rank_in_method <= 5) / max(method_value), 1) AS top_5_share_pct,
       round((sum(power(value / method_value, 2)) * 10000)::numeric, 0)  AS herfindahl_index,
       CASE WHEN sum(awards) < 30 THEN 'small n: read with caution' ELSE '' END AS reliability_note
FROM ranked
GROUP BY procurement_method
ORDER BY max(method_value) DESC;

-- [RS5] Concentration by procuring entity (entities with at least min_awards eligible awards)
WITH params AS (SELECT 10 AS min_awards),
entity_supplier AS (
    SELECT buyer_id, max(buyer_name) AS buyer_name, supplier_id,
           count(*) AS awards, sum(award_value_amount) AS value
    FROM analytics.vw_supplier_award_eligible
    WHERE buyer_id_flag IS NULL                                  -- DQ-19: bare buyer ID is not an entity
    GROUP BY buyer_id, supplier_id
),
ranked AS (
    SELECT es.*,
           sum(value)  OVER (PARTITION BY buyer_id)                                   AS entity_value,
           sum(awards) OVER (PARTITION BY buyer_id)                                   AS entity_awards,
           row_number() OVER (PARTITION BY buyer_id ORDER BY value DESC, supplier_id) AS rank_in_entity
    FROM entity_supplier es
),
entity AS (
    SELECT buyer_id, max(buyer_name) AS buyer_name,
           max(entity_awards)                                                        AS eligible_awards,
           count(*)                                                                  AS suppliers,
           max(entity_value)                                                         AS value,
           sum(value) FILTER (WHERE rank_in_entity <= 1) / max(entity_value)         AS top_1_share,
           sum(value) FILTER (WHERE rank_in_entity <= 3) / max(entity_value)         AS top_3_share,
           sum(power(value / entity_value, 2)) * 10000                               AS herfindahl_index
    FROM ranked
    GROUP BY buyer_id
),
scored AS (
    SELECT e.*,
           rank()         OVER (ORDER BY top_1_share DESC, value DESC) AS concentration_rank,
           percent_rank() OVER (ORDER BY top_1_share)                  AS percentile_position,
           count(*)       OVER ()                                      AS entities_in_comparison
    FROM entity e, params p
    WHERE e.eligible_awards >= p.min_awards
)
SELECT concentration_rank, buyer_id, buyer_name, eligible_awards, suppliers,
       round(value / 1e9, 2)                  AS value_ngn_bn,
       round(100 * top_1_share, 1)            AS top_1_supplier_share_pct,
       round(100 * top_3_share, 1)            AS top_3_suppliers_share_pct,
       round(herfindahl_index::numeric, 0)    AS herfindahl_index,
       round((100 * percentile_position)::numeric, 0) AS percentile_among_entities,
       entities_in_comparison
FROM scored
WHERE concentration_rank <= 15
ORDER BY concentration_rank;

-- [RS5b] Distribution of entity-level concentration (same entities as RS5)
WITH params AS (SELECT 10 AS min_awards),
entity_supplier AS (
    SELECT buyer_id, supplier_id, count(*) AS awards, sum(award_value_amount) AS value
    FROM analytics.vw_supplier_award_eligible
    WHERE buyer_id_flag IS NULL
    GROUP BY buyer_id, supplier_id
),
entity AS (
    SELECT buyer_id,
           sum(awards)                                  AS eligible_awards,
           max(value) / sum(value)                      AS top_1_share
    FROM entity_supplier
    GROUP BY buyer_id
)
SELECT count(*)                                                                    AS entities_in_comparison,
       (SELECT min_awards FROM params)                                             AS min_awards_threshold,
       round(100 * percentile_cont(0.25) WITHIN GROUP (ORDER BY top_1_share)::numeric, 1) AS p25_top_1_share_pct,
       round(100 * percentile_cont(0.50) WITHIN GROUP (ORDER BY top_1_share)::numeric, 1) AS median_top_1_share_pct,
       round(100 * percentile_cont(0.75) WITHIN GROUP (ORDER BY top_1_share)::numeric, 1) AS p75_top_1_share_pct,
       count(*) FILTER (WHERE top_1_share >= 0.5)                                  AS entities_where_one_supplier_holds_half
FROM entity, params
WHERE eligible_awards >= params.min_awards;
