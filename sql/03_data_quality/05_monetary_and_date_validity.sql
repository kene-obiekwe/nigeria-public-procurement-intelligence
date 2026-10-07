-- ============================================================
-- NOCOPO — Phase 6 validation: 05 Monetary and date validity
-- ============================================================
-- Monetary: sign, currency, DQ-06/07/16 flag counts.
-- Dates: flag/value consistency, DQ-08/09 counts, chronology.
-- Flag counts reconcile to the Phase 3 decision log (with C-07).
-- Chronology checks are INFO: they size the populations Phase 7 timing
-- metrics must exclude; nothing is removed here.
-- ============================================================
WITH c (check_id, check_name, severity, expected, actual) AS (VALUES
 -- Monetary sign and currency
 ('MD-01', 'Negative monetary values (all 5 money columns)', 'GATE', '0',
    ((SELECT count(*) FROM stg.planning     WHERE budget_amount < 0)
   + (SELECT count(*) FROM stg.tender       WHERE tender_value_amount < 0)
   + (SELECT count(*) FROM stg.awards       WHERE award_value_amount < 0)
   + (SELECT count(*) FROM stg.contracts    WHERE contract_value_amount < 0)
   + (SELECT count(*) FROM stg.transactions WHERE transaction_value < 0))::text),
 ('MD-02', 'Non-NGN currency codes (all 5 money columns)', 'GATE', '0',
    ((SELECT count(*) FROM stg.planning     WHERE budget_currency <> 'NGN')
   + (SELECT count(*) FROM stg.tender       WHERE tender_value_currency <> 'NGN')
   + (SELECT count(*) FROM stg.awards       WHERE award_value_currency <> 'NGN')
   + (SELECT count(*) FROM stg.contracts    WHERE contract_value_currency <> 'NGN')
   + (SELECT count(*) FROM stg.transactions WHERE transaction_currency <> 'NGN'))::text),
 ('MD-03', 'Amount present but currency missing', 'GATE', '0',
    ((SELECT count(*) FROM stg.planning WHERE budget_amount IS NOT NULL AND budget_currency IS NULL)
   + (SELECT count(*) FROM stg.awards   WHERE award_value_amount IS NOT NULL AND award_value_currency IS NULL))::text),
 ('MD-04', 'DQ-06 budget EXTREME (>= NGN 1T)',          'GATE', '32',   (SELECT count(*) FROM stg.planning WHERE budget_amount_flag = 'EXTREME')::text),
 ('MD-05', 'DQ-07 award EXTREME (>= NGN 1T)',           'GATE', '1',    (SELECT count(*) FROM stg.awards WHERE award_value_flag = 'EXTREME')::text),
 ('MD-06', 'DQ-16 budget ZERO_VALUE',                   'GATE', '561',  (SELECT count(*) FROM stg.planning WHERE budget_monetary_flag = 'ZERO_VALUE')::text),
 ('MD-07', 'DQ-16 tender value ZERO_VALUE',             'GATE', '1259', (SELECT count(*) FROM stg.tender WHERE tender_value_monetary_flag = 'ZERO_VALUE')::text),
 ('MD-08', 'DQ-16 award ZERO_VALUE',                    'GATE', '268',  (SELECT count(*) FROM stg.awards WHERE award_monetary_flag = 'ZERO_VALUE')::text),
 ('MD-09', 'DQ-05 tenderer count ANOMALOUS (> 1,000)',  'GATE', '65',   (SELECT count(*) FROM stg.tender WHERE tenderer_count_flag = 'ANOMALOUS')::text),
 ('MD-10', 'DQ-04 tenderer count ELEVATED (101-1,000), per C-07', 'GATE', '14', (SELECT count(*) FROM stg.tender WHERE tenderer_count_flag = 'ELEVATED')::text),
 -- Date flag consistency: flag is NULL exactly when the date is NULL
 ('MD-11', 'Date flag / date NULL mismatch (10 date columns)', 'GATE', '0',
    ((SELECT count(*) FROM stg.tender     WHERE (tender_start_date IS NULL) <> (tender_start_date_flag IS NULL)
                                              OR (tender_end_date   IS NULL) <> (tender_end_date_flag   IS NULL))
   + (SELECT count(*) FROM stg.awards     WHERE (award_date IS NULL) <> (award_date_flag IS NULL))
   + (SELECT count(*) FROM stg.contracts  WHERE (date_signed IS NULL) <> (date_signed_flag IS NULL)
                                              OR (period_start_date IS NULL) <> (period_start_date_flag IS NULL)
                                              OR (period_end_date   IS NULL) <> (period_end_date_flag   IS NULL))
   + (SELECT count(*) FROM stg.milestones WHERE (due_date IS NULL) <> (due_date_flag IS NULL)
                                              OR (date_met IS NULL) <> (date_met_flag IS NULL)))::text),
 ('MD-12', 'DQ-08 PLACEHOLDER tender start (Phase 2: 24)',    'GATE', '24',  (SELECT count(*) FROM stg.tender WHERE tender_start_date_flag = 'PLACEHOLDER')::text),
 ('MD-13', 'DQ-08 PLACEHOLDER award date (Phase 2: 119)',     'GATE', '119', (SELECT count(*) FROM stg.awards WHERE award_date_flag = 'PLACEHOLDER')::text),
 ('MD-14', 'DQ-08 PLACEHOLDER contract signed (Phase 2: 77)', 'GATE', '77',  (SELECT count(*) FROM stg.contracts WHERE date_signed_flag = 'PLACEHOLDER')::text),
 ('MD-15', 'DQ-09 IMPOSSIBLE award date (year 2922)',         'GATE', '1',   (SELECT count(*) FROM stg.awards WHERE award_date_flag = 'IMPOSSIBLE')::text),
 ('MD-16', 'DQ-08 PLACEHOLDER milestone due date (Phase 4.1: 38)', 'GATE', '38', (SELECT count(*) FROM stg.milestones WHERE due_date_flag = 'PLACEHOLDER')::text),
 -- Chronology (VALID dates only) — sizes Phase 7 timing exclusions
 ('MD-17', 'Tender end before tender start (both VALID)', 'INFO', NULL,
    (SELECT count(*) FROM stg.tender WHERE tender_start_date_flag = 'VALID' AND tender_end_date_flag = 'VALID'
                                       AND tender_end_date < tender_start_date)::text),
 ('MD-18', 'Award date before tender start, same release (both VALID)', 'INFO', NULL,
    (SELECT count(*) FROM stg.awards a JOIN stg.tender t USING (release_id)
      WHERE a.award_date_flag = 'VALID' AND t.tender_start_date_flag = 'VALID' AND a.award_date < t.tender_start_date)::text),
 ('MD-19', 'Contract signed before award date (both VALID)', 'INFO', NULL,
    (SELECT count(*) FROM stg.contracts c JOIN stg.awards a USING (award_id)
      WHERE c.date_signed_flag = 'VALID' AND a.award_date_flag = 'VALID' AND c.date_signed < a.award_date)::text),
 ('MD-20', 'Contract period end before period start (both VALID)', 'INFO', NULL,
    (SELECT count(*) FROM stg.contracts WHERE period_start_date_flag = 'VALID' AND period_end_date_flag = 'VALID'
                                          AND period_end_date < period_start_date)::text)
)
SELECT check_id, 'Monetary & date validity' AS check_group, check_name, severity, expected, actual,
       CASE WHEN severity = 'GATE' THEN expected = actual END AS passed
FROM c;
