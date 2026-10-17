# Assumptions and Limitations
# Nigeria Public Procurement Intelligence

> **Status:** Final (Phase 11). The single authoritative list. It consolidates `phase10_findings/findings.md` §12,
> the Phase 3 decision log and corrections, and the Phase 9 dashboard decisions.
> **Figures** carry the claim tags of [`phase10_findings/claim_trace.md`](phase10_findings/claim_trace.md) (for example
> `[S1]`), where each is traced to its SQL output and checked automatically.

---

## 1. Source and coverage

| # | Assumption or limitation | Effect | Reference |
|---|---|---|---|
| L-01 | **Pinned source file.** The analysis uses one NOCOPO OCDS export, identified by SHA-256 `6151466…bc90c`, acquired 2026-08-14. A fresh download from the portal will not match the checksum and will not reproduce these figures. | Results describe this file only. | [`../data/README.md`](../data/README.md) |
| L-02 | **Package date is metadata.** The package `publishedDate` is 2021-05-03, but releases are dated up to 2026-07-29. Release dates are publication metadata, never procurement event dates. | No metric uses the release date. | DQ-10, correction C-12 |
| L-03 | **Published activity only.** NOCOPO reflects what entities chose or were able to publish; it is not a complete record of Nigerian public procurement. The absence of a record is not evidence that an event did not occur. | Totals and rates are lower-bound descriptions of published activity. | Scope §12 |
| L-04 | **Planning-only processes.** 82.3% of the 98,454 processes were published at planning stage only, and 17.7% reach the tender stage. [Q1] [I5] | Later-stage metrics describe a minority of processes. | DQ-02 |
| L-05 | **Date completeness.** Timing metrics cover 51.9% (tender duration), 45.2% (award lag) and 74.0% (signature lag) of their candidates. [T2] Placeholder, future and impossible dates and chronology conflicts are excluded, never corrected. | Timing results describe only processes that published valid dates. | DQ-08, DQ-09; findings §6 |
| L-06 | **No shared date dimension.** Time analysis is possible only where valid event dates exist (tender start, award date, contract signature). Competition, budget, lifecycle, implementation and entity views carry no date. | No period slicing beyond awards and the three timing measures. | Phase 9 decision P-10 |

## 2. Entity identity

| # | Assumption or limitation | Effect | Reference |
|---|---|---|---|
| L-07 | **Source IDs only.** Suppliers and buyers are identified by their published IDs; nothing is merged on name similarity. 34.1% of eligible supplier value sits with supplier IDs that carry several names. [Q4] | Supplier concentration is a lower bound. | DQ-13, DQ-15 |
| L-08 | **Incomplete supplier IDs.** 2,226 awards (₦670.4bn, 20.4% of eligible award value) carry only the bare `NG-BPP-` supplier ID and are excluded from supplier analysis. [S1] | Every concentration figure must carry this disclosure. | DQ-14 |
| L-09 | **Incomplete buyer ID.** Records with the bare `NG-BPP-` buyer ID are excluded from entity comparisons but kept in overall counts. | Entity totals are slightly below overall totals. | DQ-19 |
| L-10 | **Portal test entity.** `TEST MINISTRY - NOCOPO` (`NG-BPP-BPP-NOC-90`) is retained in staging and core but removed from every analytical metric. | No ranking or total includes it. | DQ-20, correction C-11 |

## 3. Release modelling and values

| # | Assumption or limitation | Effect | Reference |
|---|---|---|---|
| L-11 | **Section-level snapshot.** Each process takes each lifecycle section from its latest release (integer release order); award and contract come from the same release. | Processes and values are counted once; earlier versions are not analysed. | Phase 4 §6 |
| L-12 | **Budget-line grain.** Planned budget is counted once per `(OCID, budget projectID)` at its latest value. Budget-to-award uses processes with exactly one budget line. | Multi-project OCIDs are left out of budget-to-award. | Correction C-06; decision I-2 |
| L-13 | **One published value per process.** Tender, award and contract values are identical in every published record, so the only valid financial comparison is budget against award. | No tender-to-award or contract-to-award variance is reported. | Correction C-08 |
| L-14 | **A budget is a plan.** An award below budget is not a saving and one above it is not an overrun; ratios are descriptive. | Budget-to-award findings are patterns, not performance judgements. | Findings §5 |
| L-15 | **Extreme values excluded by documented rule only.** Budgets of ₦1 trillion or more (DQ-06; 32 lines holding 50.8% of candidate budget value) and one award of ₦1,004.2bn (DQ-07) are excluded from value metrics; no statistical outlier rule is applied. [Q7] | Value totals are stated without these records. | DQ-06, DQ-07 |
| L-16 | **Possible scale errors flagged, not excluded.** 45 awards (₦509.5bn, 15.5% of eligible award value) are out of scale with their own process record (dropped-decimal or sibling-lot test). They stay in every metric; headline figures are also shown without them. Awards without a comparator cannot be tested. [X1] | Value totals, concentration and the above-ten-times budget group depend on these records; medians do not. | DQ-21, correction C-13; findings §10 |
| L-17 | **Placeholder-like budgets kept.** A few budgets recorded as tiny amounts produce extreme ratios; no approved rule removes them. | Visible in their own ratio band. | Phase 8 decision D-5 |

## 4. Implementation and competition data

| # | Assumption or limitation | Effect | Reference |
|---|---|---|---|
| L-18 | **Implementation is a reporting signal.** Coverage shows whether implementation data was published, not whether a contract was delivered or paid. Transactions have no dates and unclear value semantics, so they are never summed. [Q5] | No payment-timing or spend analysis. | DQ-11, DQ-12 |
| L-19 | **Tenderer counts as recorded.** The source does not define whether `numberOfTenderers` counts bids received or bids found responsive. Missing counts are never treated as zero; counts above 1,000 are excluded (DQ-05) and 101–1,000 kept only in the sensitivity population (DQ-04). | Single-bidder rates describe the published count. | DQ-04, DQ-05 |
| L-20 | **Procurement category is not in the source.** Procurement method is the closest available segmentation. | "By category" analyses use method. | Scope question 1 |

## 5. Interpretation

| # | Assumption or limitation | Effect | Reference |
|---|---|---|---|
| L-21 | **Observational data, no causation.** All findings are descriptive. Differences between methods, years or entities are not attributed to any cause. | Recommendations test patterns; they do not presume causes. | Scope §12; findings §2 |
| L-22 | **No claims about conduct.** Named entities and suppliers appear only as observed patterns with their populations. The project does not allege misconduct by anyone. | Patterns are prompts for review, not conclusions. | Findings §2 |
| L-23 | **Materiality and minimum-n are analyst parameters.** Minimum populations (10 awards, 30 tenders, 20 contracts) [S5] [C4] [I4] and the materiality reading rule (high at ten per cent, moderate at one per cent) are analytic choices, not project rules. | Entity comparisons below the minimum are not shown. | Phase 8 decision D-3 |

---

*Assumptions and limitations version 1.0 — 2026-10-17.*
