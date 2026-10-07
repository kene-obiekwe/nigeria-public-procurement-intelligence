# Phase 4.1 — Process-Snapshot Rule Validation Report

> **Script:** `python/validation/03_snapshot_rule_validation.py`  
> **Run date:** 2026-10-07 16:19:52  
> **Source SHA-256:** `615146696f51d18f72c12c0152888280c12f280981096aae8408843e7d1bc90c`  
> **Raw data is READ-ONLY. This report contains measured observations only.**
> Decisions taken on this evidence are recorded in `docs/phase4_relational_model.md` v1.1.

## 1. Population

| Metric | Value |
|---|---|
| Releases | 108,277 |
| Unique OCIDs | 98,866 |
| Multi-release OCIDs | 6,280 |
| Max awards per release | 1 |

## 2. Tie-break ordering (release_id)

| Check | Result |
|---|---|
| release_id stored as numeric string | True (JSON type: string) |
| Multi-release OCIDs where text-max ≠ integer-max release | **1,508** of 6,280 |

> Ordering `release_id` as text (e.g. '9459' > '114592') selects a different release
> than numeric ordering. Any tie-break must cast to integer.

## 3. Content divergence within multi-release OCIDs

| Check | OCIDs |
|---|---|
| Budget object differs across releases | 836 |
|   of which only because some releases lack a budget | 225 |
|   of which ≥2 distinct non-null budget amounts | 611 |
| Mixed tag sets across releases | 236 |
| ≥2 full-lifecycle releases | 465 |
| Integer-latest release has no budget | 79 |
| Awards in >1 release | 554 |
|   of which award value or supplier differs | 5 |

### 3.1 Budget pattern classification (all multi-release OCIDs)

| Pattern | Definition | OCIDs |
|---|---|---|
| IDENTICAL_BUDGET | One projectID, one budget amount | 5,666 |
| SAME_PROJECT_REVISED | One projectID, amount changes across releases | 422 |
| MULTI_PROJECT | ≥2 distinct budget projectIDs under one OCID | 192 |

- MULTI_PROJECT OCIDs consisting solely of planning-only releases: 189 of 192
- Distinct budget projectIDs: 97,749; projectIDs spanning >1 OCID: 0

> MULTI_PROJECT OCIDs carry unrelated budget lines (different projectID, description and
> amount) under one OCID. One-release-per-OCID selection silently drops all but one.

### 3.2 OCIDs with conflicting award content across releases

- `ocds-gyl66f-521027024-000087`
- `ocds-gyl66f-123031011-000136`
- `ocds-gyl66f-228050001-000010`
- `ocds-gyl66f-228050001-000103`
- `ocds-gyl66f-124004001-000772`

> In these OCIDs the integer-latest award release carries the most recent correction
> (e.g. a ×100 value revision reverted, a placeholder supplier '1' replaced by a named supplier).

## 4. Candidate rules compared on planned budget (M-P01 input)

Totals exclude DQ-06 EXTREME budgets (≥ NGN 1T) and NULLs.

| Rule | Description | OCIDs with budget | Total (NGN bn) |
|---|---|---|---|
| R0 | Phase 4 v1.0 as written (most tags; text tie-break) | 97,514 | 93,768.8 |
| R1 | Most tags; integer tie-break | 97,537 | 93,812.5 |
| R2 | Section-level latest release with a budget (integer) | 97,557 | 93,817.4 |
| R3 | R2 per (OCID, projectID), summed | 97,557 | 93,827.8 |

| Comparison | OCIDs whose budget differs |
|---|---|
| R0 vs R1 | 240 |
| R1 vs R2 | 23 |
| R2 vs R3 | 191 |

- Budget rows under R3 (one per OCID × projectID): 97,749

## 5. Lifecycle-section alignment

| Check | Count |
|---|---|
| Contracts whose awardID is not in the same release | 0 |
| OCIDs where latest award release ≠ latest contract release | 0 |
| OCIDs where latest tender release ≠ latest award release | 1 |

> Awards and contracts always travel together in one release, so selecting the
> award/contract section from a single release preserves the contract → award link.

## 6. Open-issue probes

### 6.1 tender.id uniqueness (Phase 4 §17.4)

| Check | Result |
|---|---|
| Tender objects | 18,408 |
| Null/empty tender.id | 0 |
| Distinct tender.id | 18,408 |
| tender.id values appearing in >1 release | 0 |

### 6.2 Milestone date quality (Phase 4 §17.2)

| Source | Field | Total | NULL | VALID | PLACEHOLDER | FUTURE | IMPOSSIBLE | UNPARSEABLE |
|---|---|---|---|---|---|---|---|---|
| CONTRACT | dueDate | 14,894 | 14,894 | 0 | 0 | 0 | 0 | 0 |
| CONTRACT | dateMet | 14,894 | 14,894 | 0 | 0 | 0 | 0 | 0 |
| IMPLEMENTATION | dueDate | 27,960 | 17,065 | 10,857 | 38 | 0 | 0 | 0 |
| IMPLEMENTATION | dateMet | 27,960 | 17,065 | 10,857 | 38 | 0 | 0 | 0 |

### 6.3 Implementation transaction values (Phase 4 §17.1 / DQ-12)

| Check | Count |
|---|---|
| Contracts with 0 transaction(s) | 3,533 |
| Contracts with 1 transaction(s) | 13,403 |
| Contracts with 2 transaction(s) | 107 |
| Two-transaction contracts: second_eq_first | 55 |
| Two-transaction contracts: second_gt_first | 9 |
| Two-transaction contracts: second_lt_first | 43 |
| Transactions vs contract value: max_equals_contract_value | 63 |
| Transactions vs contract value: sum_below_contract_value | 2,818 |
| Transactions vs contract value: sum_equals_contract_value | 10,145 |
| Transactions vs contract value: sum_exceeds_contract_value | 417 |

> Evidence only. These patterns do not by themselves establish whether transaction
> values are cumulative or incremental; DQ-12 remains UNRESOLVED.

---

*Generated by `python/validation/03_snapshot_rule_validation.py`. Raw dataset not modified.*
