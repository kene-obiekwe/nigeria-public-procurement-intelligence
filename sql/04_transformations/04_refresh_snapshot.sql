-- ============================================================
-- NOCOPO — Phase 8.1: refresh the materialised process snapshot
-- ============================================================
-- core.vw_budget_lines and core.vw_process_snapshot are materialised. Refresh
-- them, in this order (the snapshot reads the budget lines), whenever stg.* or
-- core.dim_buyer changes. The analytics.* views read the materialised data, so
-- a stale snapshot gives stale analytics. Takes about 5 s.
-- ============================================================
REFRESH MATERIALIZED VIEW core.vw_budget_lines;
REFRESH MATERIALIZED VIEW core.vw_process_snapshot;
ANALYZE core.vw_budget_lines;
ANALYZE core.vw_process_snapshot;
