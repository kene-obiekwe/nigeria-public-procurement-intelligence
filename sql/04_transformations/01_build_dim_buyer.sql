-- ============================================================
-- NOCOPO — Phase 6: Build core.dim_buyer
-- ============================================================
-- Source:  stg.releases (releases[].buyer)
-- Grain:   one row per buyer_id (667)
-- Rule:    buyer_name_raw = most frequent non-null published name for the
--          ID; ties broken by the latest release (release_seq). Release-level
--          names are consistent per ID (0 IDs with >1 name), so the rule is a
--          safeguard rather than a choice between conflicting values.
--          The bare prefix 'NG-BPP-' is retained and flagged INCOMPLETE
--          (generated column), never merged into another buyer.
--          Phase 8.1: test_entity_flag (generated column, DQ-20) marks the portal
--          test entity NG-BPP-BPP-NOC-90. It is loaded like any other buyer and
--          excluded downstream, in the analytics views.
-- Re-runnable: truncates and rebuilds. No other table references dim_buyer.
-- ============================================================

BEGIN;

TRUNCATE core.dim_buyer;

INSERT INTO core.dim_buyer (buyer_id, buyer_name_raw, release_count)
WITH name_freq AS (
    SELECT buyer_id,
           buyer_name,
           count(*)          AS freq,
           max(release_seq)  AS latest_seq
    FROM stg.releases
    WHERE buyer_name IS NOT NULL
    GROUP BY buyer_id, buyer_name
),
chosen_name AS (
    SELECT DISTINCT ON (buyer_id) buyer_id, buyer_name
    FROM name_freq
    ORDER BY buyer_id, freq DESC, latest_seq DESC
)
SELECT r.buyer_id,
       n.buyer_name,
       count(*) AS release_count
FROM stg.releases r
LEFT JOIN chosen_name n USING (buyer_id)
WHERE r.buyer_id IS NOT NULL
GROUP BY r.buyer_id, n.buyer_name;

COMMIT;
