# Phase 3.1 Correction Log
# Nigeria Public Procurement Intelligence

> **Phase:** 3.1 — Specification Correction Pass
> **Correction date:** 2026-08-18
> **Applied by:** Project owner (specification correction pass)
> **Reviewed against:** Phase 3 specification documents v1.0 (2026-08-16)
> **Raw dataset:** NOT modified. No schema implemented. No SQL written.

---

## Purpose

This document records every substantive correction applied during the Phase 3.1
specification review. Each entry identifies the issue, the previous wording,
the corrected wording, the reason for the correction, and the downstream impact.

All corrections preserve the approved Phase 3 decisions. No approved decision
was reversed or redesigned. The Phase 3 decisions are final; Phase 3.1 corrects
specification errors and internal inconsistencies only.

---

## Correction C-01 — Planning Population Count

| Attribute | Detail |
|-----------|--------|
| **Correction ID** | C-01 |
| **Document** | `docs/phase3_data_quality/phase3_metric_eligibility.md` — Pillar 1 (Procurement Planning and Market Intelligence), Valid population section |
| **Issue** | The valid-population line stated: "All releases with planning tag (108,277 releases / 108,277 OCIDs at planning stage)." This incorrectly implied 108,277 unique OCIDs, conflating total release count with unique procurement-process count. |
| **Previous wording** | `All releases with planning tag (108,277 releases / 108,277 OCIDs at planning stage).` |
| **Corrected wording** | All releases carrying the `planning` tag: 108,277 releases in total. The number of *distinct procurement processes* at the planning stage cannot be inferred as equal to the release count; it must be calculated during implementation by counting distinct OCIDs across all releases with the planning tag. For process-level (OCID-level) budget aggregation, the process-snapshot rule applies: take ONE budget value per OCID before summing across OCIDs. |
| **Reason** | The dataset has 108,277 releases but only 98,866 unique OCIDs. 6,280 OCIDs appear in multiple releases. Treating 108,277 releases as 108,277 procurement processes is incorrect and would overcount planning-stage processes in any OCID-level analysis. |
| **Did the underlying Phase 3 decision change?** | No. The approved decision (retain all releases; apply process-snapshot rule for OCID-level aggregation) is unchanged. |
| **Impact on schema design** | The staging layer must support counting distinct OCIDs at the planning stage — not simply summing releases with the planning tag. |
| **Impact on analytical metrics** | M-P01 (total planned budget) already uses the process-snapshot rule correctly. The corrected wording makes this explicit in the Pillar 1 valid-population description. |
| **Status** | Applied ✓ |

---

## Correction C-02 — Supplier Eligibility Contradiction

| Attribute | Detail |
|-----------|--------|
| **Correction ID** | C-02 |
| **Document** | `docs/phase3_data_quality/phase3_metric_eligibility.md` — Pillar 3 (Supplier and Market Concentration), Valid population and Exclusions sections |
| **Issue** | A direct contradiction existed between the Valid population section (which permitted records where `supplier_id_flag IS NULL or INCOMPLETE`) and the Exclusions section (which excluded `supplier_id_flag = INCOMPLETE`). These rules were mutually contradictory: a record cannot simultaneously be in the eligible population and excluded. |
| **Previous wording** | Valid population: `supplier_id_flag IS NULL or INCOMPLETE (with appropriate caveats for incomplete IDs).` |
| **Corrected wording** | Valid population: `supplier_id_flag IS NULL` (complete, non-flagged supplier identifiers only). Records where `supplier_id_flag = INCOMPLETE` are NOT eligible for the primary supplier concentration population. They are retained in the underlying data and may be included in separate data-quality or coverage analysis. This exclusion is a metric-grain requirement, not a data-deletion rule. |
| **Reason** | The approved Phase 3 supplier decision (DQ-13 through DQ-15) is clear: incomplete `NG-BPP-` identifiers are flagged and excluded from primary concentration metrics. The valid-population section had not been updated to reflect this exclusion consistently. |
| **Did the underlying Phase 3 decision change?** | No. DQ-14 (flag incomplete IDs) and DQ-15 (future canonical mapping) are unchanged. The correction aligns the valid-population description with the already-approved exclusion rule. |
| **Impact on schema design** | The `supplier_id_flag` column specification (already in the DQ log Flag Column Specification table) is sufficient. No new columns required. |
| **Impact on analytical metrics** | M-S01 (top supplier concentration) already had the correct exclusion rule in its eligibility table. This correction makes Pillar 3's overall valid-population description consistent with M-S01. |
| **Status** | Applied ✓ |

---

## Correction C-03 — M-E02 Multi-Award Handling

| Attribute | Detail |
|-----------|--------|
| **Correction ID** | C-03 |
| **Document** | `docs/phase3_data_quality/phase3_metric_eligibility.md` — Metric M-E02 (Median Award Lag) |
| **Issue** | M-E02's eligibility condition stated: "OCID has exactly one definitive award record." The document separately acknowledged (in Section 1.2 Award level) that one OCID may have multiple awards (e.g. multi-lot procurements). The M-E02 entry did not explain why multi-award OCIDs are excluded, did not distinguish single-award processes from multi-award processes, and gave no guidance for how multi-award records should be handled. |
| **Previous wording** | Eligibility: `Both dates non-null and VALID; award date >= tender start date; OCID has exactly one definitive award record` |
| **Corrected wording** | Eligibility: Restrict to single-award OCIDs (OCIDs with exactly one award record at OCID level). Multi-award OCIDs (e.g. multi-lot procurements) are excluded from this primary metric. Aggregation rule: for single-award OCIDs, take one tender start date and one award date per OCID (process-snapshot rule); compute lag in days; MEDIAN. Interpretation: **Single-award processes only.** Exclusion of multi-award OCIDs is a metric-grain limitation, NOT evidence of bad data. Multi-award processes remain available for separate multi-award cycle-time analysis. |
| **Reason** | Including multi-award OCIDs in M-E02 would require selecting one award from potentially many, which would be an arbitrary and undocumented decision. Excluding them explicitly and treating them as a separate analytical category is the only defensible approach without further evidence about how multi-award processes should be represented. |
| **Did the underlying Phase 3 decision change?** | No. The Phase 3 date eligibility rules (VALID dates only; no placeholder or impossible dates) are unchanged. The correction adds precision about which procurement processes are eligible — not what dates are eligible. |
| **Impact on schema design** | The analytical view for M-E02 will need a derived flag or sub-query to identify single-award vs. multi-award OCIDs. This is a Phase 5 view implementation concern. |
| **Impact on analytical metrics** | M-E02 primary population is narrower (single-award OCIDs only). A companion metric for multi-award cycle-time analysis is recommended but not specified here — it would require separate Phase 5 definition. |
| **Status** | Applied ✓ |

---

## Correction C-04 — OCDS / OCID / Release Terminology Consistency

| Attribute | Detail |
|-----------|--------|
| **Correction ID** | C-04 |
| **Document** | `docs/phase3_data_quality/phase3_metric_eligibility.md` — multiple sections |
| **Issue** | Several passages used "releases" and "OCIDs" (procurement processes) interchangeably when the distinction matters. Specific instances: (1) Pillar 2 Known Limitations: "Only 18,408 of 108,277 releases (17%) have tender data" did not distinguish between releases and processes. (2) M-E01 Interpretation caveat: "The eligible population (~9,593 OCIDs)" used "OCIDs" when the figure 9,593 was derived from releases with valid dates, not from distinct OCIDs. |
| **Previous wording (Pillar 2)** | `Only 18,408 of 108,277 releases (17%) have tender data; competition analysis covers a minority of the full procurement universe.` |
| **Corrected wording (Pillar 2)** | Only 18,408 of 108,277 releases (17%) contain tender-stage data. Because 98,866 unique OCIDs (procurement processes) exist, the number of distinct processes with tender data must be calculated during implementation. Competition analysis covers a minority of the full planning universe. |
| **Previous wording (M-E01)** | `The eligible population (~9,593 OCIDs) may not be representative of all procurement.` |
| **Corrected wording (M-E01)** | The figure ~9,593 refers to the number of tender *releases* with a valid start date; the number of distinct procurement *processes* (OCIDs) in this eligible population will be confirmed during implementation. |
| **Reason** | The dataset's fundamental structure (108,277 releases, 98,866 unique OCIDs) must be consistently represented. Calling 9,593 "OCIDs" when it is actually a release count perpetuates the same error as C-01. |
| **Did the underlying Phase 3 decision change?** | No. |
| **Impact on schema design** | None. |
| **Impact on analytical metrics** | Coverage reporting for M-E01 and Pillar 2 should use distinct OCID counts, not release counts, when reporting the number of processes analysed. |
| **Status** | Applied ✓ |

---

## Correction C-05 — Escape Character Repair (All Three Documents)

| Attribute | Detail |
|-----------|--------|
| **Correction ID** | C-05 |
| **Document** | `docs/phase3_data_quality/phase3_metric_eligibility.md` (25 instances); `docs/phase3_data_quality/phase3_data_quality_decision_log.md` (4 instances); `docs/phase3_data_quality/phase3_data_dictionary.md` (0 instances — no repair needed) |
| **Issue** | All three Phase 3 documents were generated using Python string literals passed to `python -c`. Python's string literal processing converted the following sequences to control characters: `\a` → BEL (0x07) replacing the letter 'a'; `\b` → BS (0x08) replacing the letter 'b'; `\t` → TAB replacing the letter sequence 't...'. This caused field names to be rendered as: `\x07ward_value_flag` instead of `award_value_flag`; `\x08udget_amount_flag` instead of `budget_amount_flag`; `\tender` instead of `tender`; `eleases[]` instead of `releases[]` (from a carriage-return artefact). |
| **Affected terms** | `award`, `awards`, `active`, `award_value_flag`, `budget`, `budget_amount_flag`, `buyer`, `tender`, `tenderer_count_flag`, `numberOfTenderers`, `releases[]`, `tag` |
| **Previous wording (example)** | `\x07ward_value_flag IS NULL` (rendered as a BEL character followed by "ward_value_flag") |
| **Corrected wording (example)** | `award_value_flag IS NULL` |
| **Reason** | Control characters in documentation files are invisible in most editors and render incorrectly in Markdown viewers. They also break programmatic searches and cross-references. This was a generation artefact, not an intentional encoding decision. |
| **Did the underlying Phase 3 decision change?** | No. These were rendering artefacts only. The content meaning is unchanged. |
| **Impact on schema design** | None — field names are now correctly represented throughout. |
| **Impact on analytical metrics** | None — flag column names now render correctly in all documents. |
| **Status** | Applied ✓ — 0 stray escape characters remaining in all three documents |

---

## Phase 3.1 Validation Results

The following validation checks were performed after applying all corrections:

| Check | Status | Notes |
|-------|--------|-------|
| No document treats 108,277 releases as 108,277 unique OCIDs | ✓ Pass | C-01 corrected Pillar 1 valid population; C-04 corrected Pillar 2 and M-E01 |
| Supplier concentration metrics consistently exclude INCOMPLETE IDs from primary population | ✓ Pass | C-02 aligned Pillar 3 valid-population with M-S01 eligibility |
| M-E02 explicitly handles multi-award procurements | ✓ Pass | C-03 added eligibility restriction, aggregation rule, and note |
| OCDS / OCID / Release terminology is consistent | ✓ Pass | C-04 and C-05 corrected all identified instances |
| Approved Phase 3 decisions remain intact | ✓ Pass | No approved decision was changed |
| No raw data has been modified | ✓ Pass | Raw dataset not touched |
| No database schema has been implemented | ✓ Pass | No DDL created |
| No SQL analysis has been started | ✓ Pass | No SQL written |
| No Phase 5 work has been started | ✓ Pass | Phase 5 not initiated |
| All escape characters removed | ✓ Pass | 0 stray escapes in all three documents |

---

## Remaining Unresolved Items

None introduced by Phase 3.1. Two items carried forward from Phase 3 remain open
(both are deferred to Phase 4 as planned):

1. **DQ-12 (transaction value semantics)** — whether transaction values represent
   cumulative or incremental payments. Deferred to Phase 4 profiling.

2. **Milestone date quality** — `dueDate` / `dateMet` quality across 27,960 milestone
   objects not yet assessed. Deferred to Phase 4.

Neither issue affects the corrections made in Phase 3.1 or blocks Phase 4.

---

## Phase 3 Freeze Status

> **Phase 3 documentation is now FROZEN as of 2026-08-18.**
> No further specification changes should be made to the three Phase 3 documents
> except by a new explicitly approved correction pass.
> The project is ready to proceed to Phase 4 upon human review and approval.

---

*Correction log version: 1.0 — 2026-08-18*
*Recorded after the Phase 3.1 correction pass.*
*No raw data modified. No schema implemented. No SQL written.*
