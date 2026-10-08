-- ============================================================
-- NOCOPO — Performance indexes (Phase 8.1)
-- ============================================================
-- Added after measuring query plans on the analytics views (see
-- docs/phase8_analysis/phase8_1_dq20_and_performance.md for before/after
-- timings). Idempotent. These indexes change no data and no result.
--
-- ix_releases_ocid_seq: every "latest release per OCID" step sorted all 108,277
--   releases by (ocid, release_seq DESC), spilling to disk at the default
--   work_mem. The index supplies that order, so the sorts disappear.
-- ============================================================
CREATE INDEX IF NOT EXISTS ix_releases_ocid_seq
    ON stg.releases (ocid, release_seq DESC) INCLUDE (release_id, buyer_id);

ANALYZE stg.releases;
