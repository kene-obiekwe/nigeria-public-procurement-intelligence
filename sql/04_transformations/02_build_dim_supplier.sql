-- ============================================================
-- NOCOPO — Phase 6: Build core.dim_supplier
-- ============================================================
-- Sources: stg.parties (supplier-role parties)
--          stg.award_suppliers (awards[].suppliers[])
-- Grain:   one row per source supplier_id (10,325)
--
-- Why both sources: 1,137 awards have no supplier-role party in their own
-- release. 29 of the supplier IDs on those awards never appear as a supplier
-- party anywhere. A parties-only dimension would orphan them.
--
-- Rules:
--   * Identity = source supplier_id. No name-based merging (DQ-13/14/15).
--   * supplier_name_raw = most frequent published name for the ID across both
--     sources (compared after trimming whitespace); ties broken by latest
--     release_seq. The chosen value is stored exactly as published.
--   * name_variant_count = distinct trimmed names observed (DQ-13 evidence).
--   * 'NG-BPP-' (bare prefix) is retained and flagged INCOMPLETE (generated).
-- Re-runnable: truncates and rebuilds. No other table references dim_supplier.
-- ============================================================

BEGIN;

TRUNCATE core.dim_supplier;

INSERT INTO core.dim_supplier
    (supplier_id, supplier_name_raw, name_variant_count, in_supplier_parties, in_award_suppliers)
WITH observations AS (
    SELECT p.party_id          AS supplier_id,
           p.party_name_raw    AS name_raw,
           r.release_seq,
           'PARTY'             AS source
    FROM stg.parties p
    JOIN stg.releases r USING (release_id)
    WHERE 'supplier' = ANY (p.roles)
    UNION ALL
    SELECT s.supplier_id,
           s.supplier_name_raw,
           r.release_seq,
           'AWARD'
    FROM stg.award_suppliers s
    JOIN stg.awards   a USING (award_id)
    JOIN stg.releases r ON r.release_id = a.release_id
),
trimmed AS (
    -- Same whitespace set as Python str.strip(), so DQ-13/14 figures reproduce.
    SELECT *,
           nullif(btrim(name_raw, ' ' || chr(9) || chr(10) || chr(11) || chr(12)
                                      || chr(13) || chr(160)), '') AS name_trim
    FROM observations
),
name_freq AS (
    SELECT supplier_id, name_trim,
           count(*)          AS freq,
           max(release_seq)  AS latest_seq,
           (array_agg(name_raw ORDER BY release_seq DESC))[1] AS latest_raw
    FROM trimmed
    WHERE name_trim IS NOT NULL
    GROUP BY supplier_id, name_trim
),
chosen_name AS (
    SELECT DISTINCT ON (supplier_id) supplier_id, latest_raw AS name_raw
    FROM name_freq
    ORDER BY supplier_id, freq DESC, latest_seq DESC
)
SELECT t.supplier_id,
       c.name_raw,
       count(DISTINCT t.name_trim)       AS name_variant_count,
       bool_or(t.source = 'PARTY')       AS in_supplier_parties,
       bool_or(t.source = 'AWARD')       AS in_award_suppliers
FROM trimmed t
LEFT JOIN chosen_name c USING (supplier_id)
WHERE t.supplier_id IS NOT NULL
GROUP BY t.supplier_id, c.name_raw;

COMMIT;
