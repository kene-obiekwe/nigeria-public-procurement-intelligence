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
-- These are VIEWS: staging keeps every release; nothing is deleted.
-- Re-runnable (CREATE OR REPLACE).
-- ============================================================

-- ------------------------------------------------------------
-- core.vw_budget_lines — one row per (ocid, budget_project_id)
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW core.vw_budget_lines AS
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

COMMENT ON VIEW core.vw_budget_lines IS
    'One row per planning budget line (ocid, budget_project_id): the latest release '
    'carrying that line. Input to M-P01 (Phase 3 correction C-06). '
    'Expected 97,749 rows.';


-- ------------------------------------------------------------
-- core.vw_process_snapshot — one row per OCID
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW core.vw_process_snapshot AS
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

COMMENT ON VIEW core.vw_process_snapshot IS
    'One row per procurement process (OCID, 98,866). Section-level snapshot: tender '
    'and award each from the latest release (release_seq) containing them; contract '
    'from the award''s own release. multi_project_flag marks OCIDs with >1 budget line '
    '(192). Join to stg.* by tender_release_id / award_id / contract_id for detail.';
