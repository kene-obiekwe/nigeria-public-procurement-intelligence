-- ============================================================
-- NOCOPO — Phase 6 validation: 01 Key uniqueness
-- ============================================================
-- Every primary, unique and candidate key across stg.* and core.*.
-- actual = rows - distinct key values (counts duplicates AND nulls).
-- Output contract (all validation files):
--   check_id, check_group, check_name, severity, expected, actual, passed
--   severity GATE = must equal expected; INFO = measurement only.
-- ============================================================
WITH c (check_id, check_name, severity, expected, actual) AS (VALUES
 ('UQ-01', 'stg.releases.release_id',                   'GATE', '0', (SELECT count(*) - count(DISTINCT release_id) FROM stg.releases)::text),
 ('UQ-02', 'stg.releases.release_seq',                  'GATE', '0', (SELECT count(*) - count(DISTINCT release_seq) FROM stg.releases)::text),
 ('UQ-03', 'stg.planning.release_id',                   'GATE', '0', (SELECT count(*) - count(DISTINCT release_id) FROM stg.planning)::text),
 ('UQ-04', 'stg.tender.release_id',                     'GATE', '0', (SELECT count(*) - count(DISTINCT release_id) FROM stg.tender)::text),
 ('UQ-05', 'stg.tender.tender_id (alternate key)',      'GATE', '0', (SELECT count(*) - count(DISTINCT tender_id) FROM stg.tender)::text),
 ('UQ-06', 'stg.awards.award_id',                       'GATE', '0', (SELECT count(*) - count(DISTINCT award_id) FROM stg.awards)::text),
 ('UQ-07', 'stg.award_suppliers (award_id, supplier_seq)', 'GATE', '0', (SELECT count(*) - count(DISTINCT (award_id, supplier_seq)) FROM stg.award_suppliers)::text),
 ('UQ-08', 'stg.contracts.contract_id',                 'GATE', '0', (SELECT count(*) - count(DISTINCT contract_id) FROM stg.contracts)::text),
 ('UQ-09', 'stg.contracts.award_id (one contract per award)', 'GATE', '0', (SELECT count(*) - count(DISTINCT award_id) FROM stg.contracts)::text),
 ('UQ-10', 'stg.transactions.transaction_pk',           'GATE', '0', (SELECT count(*) - count(DISTINCT transaction_pk) FROM stg.transactions)::text),
 ('UQ-11', 'stg.milestones.milestone_pk',               'GATE', '0', (SELECT count(*) - count(DISTINCT milestone_pk) FROM stg.milestones)::text),
 ('UQ-12', 'stg.parties.party_pk',                      'GATE', '0', (SELECT count(*) - count(DISTINCT party_pk) FROM stg.parties)::text),
 ('UQ-13', 'stg.parties (release_id, party_id)',        'GATE', '0', (SELECT count(*) - count(DISTINCT (release_id, party_id)) FROM stg.parties)::text),
 ('UQ-14', 'core.dim_buyer.buyer_id',                   'GATE', '0', (SELECT count(*) - count(DISTINCT buyer_id) FROM core.dim_buyer)::text),
 ('UQ-15', 'core.dim_supplier.supplier_id',             'GATE', '0', (SELECT count(*) - count(DISTINCT supplier_id) FROM core.dim_supplier)::text),
 ('UQ-16', 'core.vw_process_snapshot.ocid',             'GATE', '0', (SELECT count(*) - count(DISTINCT ocid) FROM core.vw_process_snapshot)::text),
 ('UQ-17', 'core.vw_budget_lines (ocid, budget_project_id)', 'GATE', '0', (SELECT count(*) - count(DISTINCT (ocid, budget_project_id)) FROM core.vw_budget_lines)::text),
 ('UQ-18', 'budget_project_id never spans >1 OCID',     'GATE', '0',
    (SELECT count(*) FROM (SELECT p.budget_project_id FROM stg.planning p JOIN stg.releases r USING (release_id)
                           WHERE p.budget_project_id IS NOT NULL GROUP BY 1 HAVING count(DISTINCT r.ocid) > 1) x)::text)
)
SELECT check_id, 'Key uniqueness' AS check_group, check_name, severity, expected, actual,
       CASE WHEN severity = 'GATE' THEN expected = actual END AS passed
FROM c;
