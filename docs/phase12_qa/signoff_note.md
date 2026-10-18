# Project Sign-off Note
# Nigeria Public Procurement Intelligence

> **Date:** 2026-10-18 · **Phase:** 12 — Final QA · **QA result:** pass ([`qa_checklist.md`](qa_checklist.md))
> **Sign-off:** approved by the project owner on 2026-10-18, including the release tag (§5).

## 1. What was delivered

- An audited, reproducible PostgreSQL build of the NOCOPO OCDS export (`stg` → `core` → `analytics`), from a raw
  file pinned by SHA-256 and never modified.
- A data-quality decision log (DQ-01 to DQ-21) with metric-specific eligibility, and correction logs (C-01 to C-13).
- Seven read-only SQL analysis scripts answering the seven business questions.
- A Power BI report over validated views only, through a read-only role, distributed as a `.pbit` template with
  page screenshots.
- Executive findings and recommendations in which every figure traces to a SQL output, with raw-source checks of
  the most influential records.
- Four portfolio documents, a README entry point and a one-command rebuild (`python/run_pipeline.py`).

## 2. Gate results (clean rebuild, 2026-10-18)

| Gate / check | Result |
|---|---|
| A — audit complete before schema | Met (Phase 3 decision log and eligibility rules) |
| Raw → staging reconciliation | 64 / 64 |
| B — core validated | 107 / 107 |
| Analytical views | 27 / 27 |
| C — analysis reconciled; Power BI on validated views only | 31 / 31; 16 / 16 |
| DQ-21 scale flag | 14 / 14 |
| Dashboard reconciliation | 177 / 177, re-confirmed on the rebuilt database |
| D — findings traced to SQL | 236 / 236 claim-trace rows |
| Clean rebuild | all 14 steps in 274 s; outputs identical to the committed ones apart from run metadata |

## 3. Known limitations

The authoritative list is [`../assumptions_and_limitations.md`](../assumptions_and_limitations.md) (L-01 to L-23). The
most important for any reader: results describe one pinned export of published records only; supplier
concentration is a lower bound because supplier IDs are incomplete and never merged by name; timing covers only
processes with valid dates; implementation coverage is a reporting signal; some awards are flagged as possible scale
errors and shown with and without them; and nothing in the project establishes cause or conduct.

## 4. Open items

Sixteen items are registered in [`qa_checklist.md`](qa_checklist.md) §8. None blocks sign-off. Resolved on 2026-10-18: the `.pbit` was confirmed on a
second machine (OI-09), the unused `pandas` / `SQLAlchemy` dependencies were removed (OI-10), and the release tag was approved
(OI-15). Record-level confirmation of the flagged and unresolved awards
(OI-01 to OI-03) needs the published award notices.

Possible technical extensions, outside this project: automated runs of the pipeline and checks in CI against a
containerised PostgreSQL; scheduled ingestion of newer portal exports with versioned snapshots; an auditable
canonical supplier mapping; and DQ-21 sensitivity in the data-quality impact view and the dashboard.

## 5. Release tag

Annotated tag `v1.0`, approved by the owner on 2026-10-18 and created on the release commit with this message:

```text
v1.0 — Nigeria Public Procurement Intelligence

First complete release. Audited PostgreSQL build of the NOCOPO OCDS export
(pinned SHA-256 6151466…bc90c): staging, core and analytical layers;
seven business-question analyses; a Power BI template over validated views;
executive findings with every figure traced to SQL.

Validation on a clean rebuild (2026-10-18): staging 64/64, Gate B 107/107,
views 27/27, analysis 31/31, BI layer 16/16, DQ-21 flag 14/14, dashboard
reconciliation 177/177, findings trace 236/236.

Reproduce: python python/run_pipeline.py --db nocopo_db --create-db
Limitations: docs/assumptions_and_limitations.md
```

Commands, for the owner to run after approval (save the message above as `tag_message.txt` in the folder above the repository first):

```bash
git tag -a v1.0 -F ../tag_message.txt
```

```bash
git push origin v1.0
```

---

*Sign-off note version 1.0 — 2026-10-18.*
