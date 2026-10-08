-- ============================================================
-- NOCOPO — Phase 6: Process snapshot (release collapse) views
-- ============================================================
-- Implements the section-level process-snapshot rule approved in
-- docs/phase4_data_model/phase4_relational_model.md v1.1 §6.2 and
-- Phase 3 correction C-06.
--
--   * "Latest" = highest release_seq (integer). Never text order, never
--     release_date (identical on every release, DQ-10).
--   * Each lifecycle section is taken from the latest release containing it.
--   * Award, contract, implementation and suppliers come from the SAME release
--     (contracts never reference an award in another release).
--   * Planning budget is taken per budget line (ocid, budget_project_id).
--
-- These are MATERIALIZED VIEWS (Phase 8.1, performance): staging keeps every
-- release; nothing is deleted. Before 8.1 they were plain views that every
-- analytics view re-evaluated (sort of 108k releases per use), which made the
-- population register take ~40 s. The names are unchanged.
--
--   Fresh build:   run this file, then sql/05_views/*.sql
--   Existing DB:   run sql/02_schema/03_migration_v1_4_materialise_snapshot.sql
--                  first (drops the old plain views and their dependants), then
--                  this file, then sql/05_views/*.sql
--   After any change to stg.* or core.dim_buyer:
--                  sql/04_transformations/04_refresh_snapshot.sql
--
-- Re-runnable: CREATE ... IF NOT EXISTS leaves existing data untouched.
-- ============================================================

-- ------------------------------------------------------------
-- core.vw_budget_lines — one row per (ocid, budget_project_id)
-- ------------------------------------------------------------
CREATE MATERIALIZED VIEW IF NOT EXISTS core.vw_budget_lines AS
SELECT DISTINCT ON (r.ocid, p.budget_project_id)
       r.ocid,
       p.budget_project_id,
       p.release_id,
       r.release_seq,
       r.buyer_id,
       p.budget_amount,
       p.budget_currency,
       p.budget_description,
       p.budget_project,
       p.budget_amount_flag,
       p.budget_monetary_flag
FROM stg.planning p
JOIN stg.releases r USING (release_id)
WHERE p.budget_project_id IS NOT NULL
ORDER BY r.ocid, p.budget_project_id, r.release_seq DESC;

CREATE UNIQUE INDEX IF NOT EXISTS ux_budget_lines_ocid_project ON core.vw_budget_lines (ocid, budget_project_id);
CREATE INDEX IF NOT EXISTS ix_budget_lines_buyer ON core.vw_budget_lines (buyer_id);

COMMENT ON MATERIALIZED VIEW core.vw_budget_lines IS
    'One row per planning budget line (ocid, budget_project_id): the latest release '
    'carrying that line. Input to M-P01 (Phase 3 correction C-06). '
    'Expected 97,749 rows.';


-- ------------------------------------------------------------
-- core.vw_process_snapshot — one row per OCID
-- ------------------------------------------------------------
CREATE MATERIALIZED VIEW IF NOT EXISTS core.vw_process_snapshot AS
WITH releases_per_ocid AS (
    SELECT r.ocid,
           count(*)                                              AS release_count,
           (array_agg(r.release_id ORDER BY r.release_seq DESC))[1] AS latest_release_id,
           (array_agg(r.buyer_id   ORDER BY r.release_seq DESC))[1] AS buyer_id
    FROM stg.releases r
    GROUP BY r.ocid
),
tags_per_ocid AS (
    SELECT r.ocid, array_agg(DISTINCT t ORDER BY t) AS tags_observed
    FROM stg.releases r
    CROSS JOIN LATERAL unnest(r.tag) AS t
    GROUP BY r.ocid
),
tender_pick AS (
    SELECT DISTINCT ON (r.ocid) r.ocid, t.release_id AS tender_release_id, t.tender_id
    FROM stg.tender t
    JOIN stg.releases r USING (release_id)
    ORDER BY r.ocid, r.release_seq DESC
),
award_pick AS (
    SELECT DISTINCT ON (r.ocid) r.ocid, a.release_id AS award_release_id, a.award_id
    FROM stg.awards a
    JOIN stg.releases r USING (release_id)
    ORDER BY r.ocid, r.release_seq DESC
),
budget_lines AS (
    SELECT ocid, count(*) AS budget_line_count
    FROM core.vw_budget_lines
    GROUP BY ocid
)
SELECT o.ocid,
       o.release_count,
       o.latest_release_id,
       o.buyer_id,
       g.tags_observed,
       tp.tender_release_id,
       tp.tender_id,
       ap.award_release_id,
       ap.award_id,
       c.contract_id,
       coalesce(b.budget_line_count, 0)                     AS budget_line_count,
       CASE WHEN b.budget_line_count > 1 THEN 'MULTI_PROJECT' END AS multi_project_flag
FROM releases_per_ocid o
JOIN tags_per_ocid g        USING (ocid)
LEFT JOIN tender_pick tp    USING (ocid)
LEFT JOIN award_pick ap     USING (ocid)
LEFT JOIN stg.contracts c   ON c.release_id = ap.award_release_id
                           AND c.award_id   = ap.award_id
LEFT JOIN budget_lines b    USING (ocid);

CREATE UNIQUE INDEX IF NOT EXISTS ux_process_snapshot_ocid ON core.vw_process_snapshot (ocid);
CREATE INDEX IF NOT EXISTS ix_process_snapshot_buyer    ON core.vw_process_snapshot (buyer_id);
CREATE INDEX IF NOT EXISTS ix_process_snapshot_tender   ON core.vw_process_snapshot (tender_release_id);
CREATE INDEX IF NOT EXISTS ix_process_snapshot_award    ON core.vw_process_snapshot (award_id);
CREATE INDEX IF NOT EXISTS ix_process_snapshot_contract ON core.vw_process_snapshot (contract_id);

COMMENT ON MATERIALIZED VIEW core.vw_process_snapshot IS
    'One row per procurement process (OCID, 98,866). Section-level snapshot: tender '
    'and award each from the latest release (release_seq) containing them; contract '
    'from the award''s own release. multi_project_flag marks OCIDs with >1 budget line '
    '(192). Join to stg.* by tender_release_id / award_id / contract_id for detail.';

-- Fresh planner statistics: without them the planner picks nested loops over the
-- materialised data and the analytics views run several times slower.
ANALYZE core.vw_budget_lines;
ANALYZE core.vw_process_snapshot;
