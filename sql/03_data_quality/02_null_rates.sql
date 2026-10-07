-- ============================================================
-- NOCOPO — Phase 6 validation: 02 Null rates
-- ============================================================
-- Critical identifiers must never be NULL.
-- Analytical-field NULL counts must reconcile to Phase 2 profiling
-- evidence (docs/phase2_profiling/), so missingness is neither
-- introduced nor hidden by staging.
-- ============================================================
WITH c (check_id, check_name, severity, expected, actual) AS (VALUES
 -- Critical identifiers
 ('NL-01', 'stg.releases.ocid NULL',                 'GATE', '0', (SELECT count(*) FROM stg.releases WHERE ocid IS NULL)::text),
 ('NL-02', 'stg.releases.buyer_id NULL',             'GATE', '0', (SELECT count(*) FROM stg.releases WHERE buyer_id IS NULL)::text),
 ('NL-03', 'stg.tender.tender_id NULL',              'GATE', '0', (SELECT count(*) FROM stg.tender WHERE tender_id IS NULL)::text),
 ('NL-04', 'stg.contracts.award_id NULL',            'GATE', '0', (SELECT count(*) FROM stg.contracts WHERE award_id IS NULL)::text),
 ('NL-05', 'stg.award_suppliers.supplier_id NULL',   'GATE', '0', (SELECT count(*) FROM stg.award_suppliers WHERE supplier_id IS NULL)::text),
 ('NL-06', 'stg.parties.party_id NULL',              'GATE', '0', (SELECT count(*) FROM stg.parties WHERE party_id IS NULL)::text),
 ('NL-07', 'stg.tender.number_of_tenderers NULL',    'GATE', '0', (SELECT count(*) FROM stg.tender WHERE number_of_tenderers IS NULL)::text),
 ('NL-08', 'stg.awards.award_value_amount NULL',     'GATE', '0', (SELECT count(*) FROM stg.awards WHERE award_value_amount IS NULL)::text),
 -- Analytical fields: reconcile to Phase 2 evidence
 ('NL-09', 'stg.planning.budget_amount NULL (1,649 releases without a budget; Phase 2: 106,628 present)',
                                                     'GATE', '1649', (SELECT count(*) FROM stg.planning WHERE budget_amount IS NULL)::text),
 ('NL-10', 'stg.tender.tender_start_date NULL (Phase 2: 8,786)', 'GATE', '8786', (SELECT count(*) FROM stg.tender WHERE tender_start_date IS NULL)::text),
 ('NL-11', 'stg.tender.tender_end_date NULL (Phase 2: 8,786)',   'GATE', '8786', (SELECT count(*) FROM stg.tender WHERE tender_end_date IS NULL)::text),
 ('NL-12', 'stg.awards.award_date NULL (Phase 2: 2,630)',        'GATE', '2630', (SELECT count(*) FROM stg.awards WHERE award_date IS NULL)::text),
 ('NL-13', 'stg.contracts.date_signed NULL (17,043 - 14,386 present)', 'GATE', '2657', (SELECT count(*) FROM stg.contracts WHERE date_signed IS NULL)::text),
 ('NL-14', 'stg.releases.buyer_name NULL',           'GATE', '26',   (SELECT count(*) FROM stg.releases WHERE buyer_name IS NULL)::text),
 ('NL-15', 'stg.releases party_flag = NO_PARTIES (DQ-18)', 'GATE', '20', (SELECT count(*) FROM stg.releases WHERE party_flag = 'NO_PARTIES')::text),
 ('NL-16', 'stg.awards.status NULL',                 'INFO', NULL,   (SELECT count(*) FROM stg.awards WHERE status IS NULL)::text),
 ('NL-17', 'core.dim_buyer.buyer_name NULL (bare NG-BPP- buyer has no name)', 'GATE', '1', (SELECT count(*) FROM core.dim_buyer WHERE buyer_name IS NULL)::text),
 ('NL-18', 'core.dim_supplier.supplier_name NULL',   'INFO', NULL,   (SELECT count(*) FROM core.dim_supplier WHERE supplier_name IS NULL)::text)
)
SELECT check_id, 'Null rates' AS check_group, check_name, severity, expected, actual,
       CASE WHEN severity = 'GATE' THEN expected = actual END AS passed
FROM c;
