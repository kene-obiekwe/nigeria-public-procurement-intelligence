-- ============================================================
-- NOCOPO — Schema migration v1.4 (Phase 8.1): DQ-20 test-entity flag
-- ============================================================
-- Applies the v1.4 change in 00_draft_core_schema.sql to a database built
-- with v1.3. Idempotent: safe to run on a database that already has it.
--
-- DQ-20: buyer NG-BPP-BPP-NOC-90 ('TEST MINISTRY - NOCOPO') is a portal test
-- entity (427 releases, 412 OCIDs), not procurement. Treatment: RETAIN in
-- stg/core, FLAG, EXCLUDE_FROM_METRIC in every analytics.* view.
-- The flag is generated from the ID so the rule is explicit and auditable.
-- No staging row is changed.
-- ============================================================
ALTER TABLE core.dim_buyer
    ADD COLUMN IF NOT EXISTS test_entity_flag VARCHAR(16) GENERATED ALWAYS AS (
        CASE WHEN buyer_id = 'NG-BPP-BPP-NOC-90' THEN 'TEST_ENTITY' END
    ) STORED;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_dim_buyer_test_entity_flag') THEN
        ALTER TABLE core.dim_buyer
            ADD CONSTRAINT chk_dim_buyer_test_entity_flag
            CHECK (test_entity_flag IS NULL OR test_entity_flag IN ('TEST_ENTITY'));
    END IF;
END $$;

COMMENT ON TABLE core.dim_buyer IS
    'Distinct procuring entities (buyers). Source: releases[].buyer. '
    '667 buyer IDs: 666 complete NG-BPP-BPP-NOC-<code> IDs plus the bare prefix '
    'NG-BPP- (26 releases, no name, no recoverable buyer party) flagged INCOMPLETE. '
    'Release-level buyer names are consistent per ID (0 IDs with >1 name). '
    'DQ-20 (v1.4): NG-BPP-BPP-NOC-90 ''TEST MINISTRY - NOCOPO'' is a portal test entity, '
    'flagged TEST_ENTITY, retained here and in staging, excluded from all analytics.* metrics.';
