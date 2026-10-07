-- ============================================================
-- NOCOPO — Phase 6 validation: 03 Referential integrity (orphans)
-- ============================================================
-- Declared FKs inside stg.* are enforced by PostgreSQL; they are still
-- counted here so the result is evidenced, not assumed. Links from staging
-- to core dimensions are NOT declared as FKs (rebuilding a dimension would
-- otherwise require truncating staging), so these checks are the control.
-- ============================================================
WITH c (check_id, check_name, severity, expected, actual) AS (VALUES
 ('RI-01', 'stg.planning -> stg.releases',           'GATE', '0', (SELECT count(*) FROM stg.planning x WHERE NOT EXISTS (SELECT 1 FROM stg.releases r WHERE r.release_id = x.release_id))::text),
 ('RI-02', 'stg.tender -> stg.releases',             'GATE', '0', (SELECT count(*) FROM stg.tender x WHERE NOT EXISTS (SELECT 1 FROM stg.releases r WHERE r.release_id = x.release_id))::text),
 ('RI-03', 'stg.awards -> stg.releases',             'GATE', '0', (SELECT count(*) FROM stg.awards x WHERE NOT EXISTS (SELECT 1 FROM stg.releases r WHERE r.release_id = x.release_id))::text),
 ('RI-04', 'stg.award_suppliers -> stg.awards',      'GATE', '0', (SELECT count(*) FROM stg.award_suppliers x WHERE NOT EXISTS (SELECT 1 FROM stg.awards a WHERE a.award_id = x.award_id))::text),
 ('RI-05', 'stg.contracts -> stg.releases',          'GATE', '0', (SELECT count(*) FROM stg.contracts x WHERE NOT EXISTS (SELECT 1 FROM stg.releases r WHERE r.release_id = x.release_id))::text),
 ('RI-06', 'stg.contracts -> stg.awards',            'GATE', '0', (SELECT count(*) FROM stg.contracts x WHERE NOT EXISTS (SELECT 1 FROM stg.awards a WHERE a.award_id = x.award_id))::text),
 ('RI-07', 'contract and its award in the same release', 'GATE', '0', (SELECT count(*) FROM stg.contracts c JOIN stg.awards a USING (award_id) WHERE a.release_id <> c.release_id)::text),
 ('RI-08', 'stg.transactions -> stg.contracts',      'GATE', '0', (SELECT count(*) FROM stg.transactions x WHERE NOT EXISTS (SELECT 1 FROM stg.contracts c WHERE c.contract_id = x.contract_id))::text),
 ('RI-09', 'stg.milestones -> stg.contracts',        'GATE', '0', (SELECT count(*) FROM stg.milestones x WHERE NOT EXISTS (SELECT 1 FROM stg.contracts c WHERE c.contract_id = x.contract_id))::text),
 ('RI-10', 'stg.parties -> stg.releases',            'GATE', '0', (SELECT count(*) FROM stg.parties x WHERE NOT EXISTS (SELECT 1 FROM stg.releases r WHERE r.release_id = x.release_id))::text),
 ('RI-11', 'stg.releases.buyer_id -> core.dim_buyer', 'GATE', '0', (SELECT count(*) FROM stg.releases x WHERE NOT EXISTS (SELECT 1 FROM core.dim_buyer b WHERE b.buyer_id = x.buyer_id))::text),
 ('RI-12', 'stg.award_suppliers.supplier_id -> core.dim_supplier', 'GATE', '0', (SELECT count(*) FROM stg.award_suppliers x WHERE NOT EXISTS (SELECT 1 FROM core.dim_supplier s WHERE s.supplier_id = x.supplier_id))::text),
 ('RI-13', 'supplier-role stg.parties -> core.dim_supplier', 'GATE', '0', (SELECT count(*) FROM stg.parties x WHERE 'supplier' = ANY (x.roles) AND NOT EXISTS (SELECT 1 FROM core.dim_supplier s WHERE s.supplier_id = x.party_id))::text),
 ('RI-14', 'snapshot.buyer_id -> core.dim_buyer',    'GATE', '0', (SELECT count(*) FROM core.vw_process_snapshot x WHERE NOT EXISTS (SELECT 1 FROM core.dim_buyer b WHERE b.buyer_id = x.buyer_id))::text),
 ('RI-15', 'budget_lines.buyer_id -> core.dim_buyer', 'GATE', '0', (SELECT count(*) FROM core.vw_budget_lines x WHERE NOT EXISTS (SELECT 1 FROM core.dim_buyer b WHERE b.buyer_id = x.buyer_id))::text),
 ('RI-16', 'snapshot award has its contract when one exists in the award release', 'GATE', '0',
    (SELECT count(*) FROM core.vw_process_snapshot s
      WHERE s.contract_id IS NULL AND s.award_id IS NOT NULL
        AND EXISTS (SELECT 1 FROM stg.contracts c WHERE c.award_id = s.award_id))::text),
 ('RI-17', 'snapshot tender_release_id / award_release_id belong to the OCID', 'GATE', '0',
    (SELECT count(*) FROM core.vw_process_snapshot s
      WHERE (s.tender_release_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM stg.releases r WHERE r.release_id = s.tender_release_id AND r.ocid = s.ocid))
         OR (s.award_release_id  IS NOT NULL AND NOT EXISTS (SELECT 1 FROM stg.releases r WHERE r.release_id = s.award_release_id  AND r.ocid = s.ocid)))::text)
)
SELECT check_id, 'Referential integrity' AS check_group, check_name, severity, expected, actual,
       CASE WHEN severity = 'GATE' THEN expected = actual END AS passed
FROM c;
