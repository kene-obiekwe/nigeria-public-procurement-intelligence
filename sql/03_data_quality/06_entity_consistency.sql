-- ============================================================
-- NOCOPO — Phase 6 validation: 06 Entity identifier consistency
-- ============================================================
-- Buyer and supplier identity: dimension completeness, incomplete IDs,
-- and reproduction of the DQ-13 / DQ-14 entity-resolution evidence.
-- DQ-13/14 use the Phase 2 definition: supplier-role parties, names
-- trimmed with Python str.strip() whitespace, empty names ignored.
-- ============================================================
WITH sp AS (
    SELECT party_id,
           nullif(btrim(party_name_raw, ' ' || chr(9) || chr(10) || chr(11) || chr(12)
                                         || chr(13) || chr(160)), '') AS n
    FROM stg.parties WHERE 'supplier' = ANY (roles)
),
c (check_id, check_name, severity, expected, actual) AS (VALUES
 ('EN-01', 'core.dim_buyer rows = distinct staging buyer_id (666 complete + bare NG-BPP-)', 'GATE', '667',
    (SELECT count(*) FROM core.dim_buyer)::text),
 ('EN-02', 'Complete buyer IDs = distinct buyer-role party IDs (Phase 2: 666)', 'GATE', '666',
    (SELECT count(*) FROM core.dim_buyer WHERE buyer_id_flag IS NULL)::text),
 ('EN-03', 'Releases with bare NG-BPP- buyer ID (flagged INCOMPLETE)', 'GATE', '26',
    (SELECT release_count FROM core.dim_buyer WHERE buyer_id_flag = 'INCOMPLETE')::text),
 ('EN-04', 'Buyer IDs with >1 release-level name', 'GATE', '0',
    (SELECT count(*) FROM (SELECT buyer_id FROM stg.releases WHERE buyer_name IS NOT NULL
                           GROUP BY 1 HAVING count(DISTINCT buyer_name) > 1) x)::text),
 ('EN-05', 'core.dim_supplier rows = distinct supplier IDs (parties UNION awards)', 'GATE',
    (SELECT count(*) FROM (SELECT party_id FROM stg.parties WHERE 'supplier' = ANY (roles)
                           UNION SELECT supplier_id FROM stg.award_suppliers) u)::text,
    (SELECT count(*) FROM core.dim_supplier)::text),
 ('EN-06', 'Supplier-role party IDs (Phase 2: 10,296)', 'GATE', '10296',
    (SELECT count(*) FROM core.dim_supplier WHERE in_supplier_parties)::text),
 ('EN-07', 'Supplier IDs seen only in awards[].suppliers[]', 'INFO', NULL,
    (SELECT count(*) FROM core.dim_supplier WHERE NOT in_supplier_parties)::text),
 ('EN-08', 'Awards with no supplier-role party in their release', 'INFO', NULL,
    (SELECT count(*) FROM stg.awards a WHERE NOT EXISTS (SELECT 1 FROM stg.parties p
                                                         WHERE p.release_id = a.release_id AND 'supplier' = ANY (p.roles)))::text),
 ('EN-09', 'DQ-13: supplier IDs with >1 name (Phase 2: 1,483)', 'GATE', '1483',
    (SELECT count(*) FROM (SELECT party_id FROM sp WHERE n IS NOT NULL GROUP BY 1 HAVING count(DISTINCT n) > 1) x)::text),
 ('EN-10', 'DQ-14: supplier names with >1 ID (Phase 2: 571)', 'GATE', '571',
    (SELECT count(*) FROM (SELECT n FROM sp WHERE n IS NOT NULL GROUP BY 1 HAVING count(DISTINCT party_id) > 1) x)::text),
 ('EN-11', 'DQ-14: supplier-role parties with bare NG-BPP- ID', 'GATE', '1390',
    (SELECT count(*) FROM stg.parties WHERE supplier_id_flag = 'INCOMPLETE')::text),
 ('EN-12', 'Award-supplier rows carrying bare NG-BPP- ID (excluded from M-S01)', 'INFO', NULL,
    (SELECT count(*) FROM stg.award_suppliers WHERE supplier_id = 'NG-BPP-')::text),
 ('EN-13', 'Max distinct suppliers on one award', 'GATE', '1',
    (SELECT max(k) FROM (SELECT count(DISTINCT supplier_id) AS k FROM stg.award_suppliers GROUP BY award_id) x)::text),
 ('EN-14', 'Award supplier ID = supplier party ID in the same release (where both exist): mismatches', 'GATE', '0',
    (SELECT count(*) FROM stg.award_suppliers s JOIN stg.awards a USING (award_id)
       JOIN stg.parties p ON p.release_id = a.release_id AND 'supplier' = ANY (p.roles)
      WHERE p.party_id <> s.supplier_id)::text)
)
SELECT check_id, 'Entity consistency' AS check_group, check_name, severity, expected, actual,
       CASE WHEN severity = 'GATE' THEN expected = actual END AS passed
FROM c;
