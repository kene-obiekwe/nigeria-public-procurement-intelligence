# Executive Findings and Recommendations
# Nigeria Public Procurement Intelligence

> **Phase:** 10 — Business Interpretation, Findings & Recommendations
> **Date:** 2026-10-17
> **Evidence:** the seven business-question scripts in `sql/06_analysis/` (results:
> `docs/phase8_analysis/phase8_analysis_results.md`, post-Phase 8.1 populations) and the dashboard reconciliation pack
> (`dashboard/reconciliation_expected_values.sql`, values in `dashboard/reconciliation_log.md`).
> **Gate D evidence:** every figure carries a claim tag such as `[S1]`. The tag resolves to a row in
> [`claim_trace.md`](claim_trace.md) that names the script, result set, row, column and value. The check
> `python/validation/07_check_findings_trace.py` confirms that each figure matches its source
> ([`claim_trace_check_results.md`](claim_trace_check_results.md)).
> **Source checks:** [`source_verification.md`](source_verification.md) (raw JSON, read-only).

---

## 1. Executive summary

Each finding gives the population it rests on and its main caveat. The figures describe the published records;
they are not conclusions about how any entity or supplier behaved (see §2).

1. **Supplier value is not highly concentrated overall, but it is in emergency procurement.** The top ten suppliers
   hold 29.0% of attributable award value, and the Herfindahl index is 139.4, low on its scale. In Emergency
   procurement the largest supplier holds 61.4% of value across 363 awards. *Population:* 13,537 awards with a
   usable supplier ID. *Caveat:* 2,226 awards (₦670.4bn, 20.4% of eligible award value) have no usable supplier ID
   and are left out, so concentration is a lower bound. [S1] [S2] [S4]
2. **Almost half of tenders record a single bidder.** 44.0% of tenders record one tenderer (median 2 tenderers).
   Even in National Competitive Bidding the rate is 39.6% across 10,129 tenders. *Population:* 17,253 tenders with
   a plausible recorded count (one to a hundred tenderers). *Caveat:* the count is what was published; the source
   does not define whether it counts bids received or bids found responsive. [C1] [C3]
3. **Most processes are awarded close to budget, but a small group is far above it.** The median award is 0.93 of
   its budget line and 42.2% of processes are awarded within a tenth of their budget. Yet 227 processes (1.5%) are
   awarded more than ten times their budget and hold 49.8% of the compared award value. *Population:* 15,574 processes with one usable
   budget line. *Caveat:* a budget is a plan, not spend; the source checks (§10) find a possible data-entry pattern
   inside this group. [B1] [B2] [B3]
4. **Activity sits with a few entities.** The largest entity holds 40.6% of eligible award value and the ten largest
   hold 76.0%. *Population:* 665 procuring entities. *Caveat:* value shares are sensitive to a handful of very large
   awards, some of which are under source review (§10). [E1] [E2]
5. **Timing can be measured for only about half of processes.** Median award lag is 97 days (from tender start to
   award), but only 45.2% of candidate processes publish the two valid dates it needs. *Population:* 7,462
   processes. *Caveat:* results describe processes that published valid dates, not the rest. [T1] [T2]
6. **Implementation reporting is broad but uneven.** 87.2% of contracts carry some implementation record; one large
   ministry reports for 21.6% of its 1,677 contracts. *Population:* 16,221 contracts. *Caveat:* this is reporting
   coverage, not contract performance. [I1] [I4]
7. **Data-quality effects are concentrated in a few issues.** 82.3% of processes were published only at planning
   stage, and missing supplier IDs remove 20.4% of award value from supplier analysis. *Population:* 98,454
   processes. *Caveat:* most other issues each touch only a small share of the records in the metrics they
   affect. [Q1] [S1]

**What we recommend first (§11).** Validate the three records in §10 before quoting any figure that depends on them.
Review single-bidder and emergency processes in a sample. Ask publishers to fix three reporting gaps: supplier IDs,
event dates and implementation records.

The dashboard illustrates these results (screenshots in
[`dashboard/screenshots/`](../../dashboard/screenshots/README.md)); the figures above come from SQL output, not
from the dashboard.

---

## 2. About this report

- **Observational data.** These are descriptive patterns in published open-contracting records. They do not establish
  why a pattern exists. Nothing here alleges fraud, corruption, collusion, kickbacks or misconduct by any entity,
  official or supplier, and no finding should be read that way.
- **Named entities and suppliers** appear only as observed patterns, always with the population behind the figure.
  A high or low value means a record is worth a closer look; it is not a judgement.
- **Observation and interpretation are separated.** Each question has *Observed* (what the SQL returns), *Reading*
  (what it may mean, and what it cannot show), *Implications* (by stakeholder group) and *Recommendation*
  (proportional to the evidence).
- **Populations.** Each metric uses its own eligible population (`docs/phase7_analytics/phase7_analytical_views.md`).
  A process is an OCID; release counts are never used as process counts.

---

## 3. Supplier concentration (business question 1, metric M-S01)

**Observed**

- 13,537 of 15,763 eligible awards (85.9%) name a usable supplier ID: 9,800 suppliers and ₦2,620.2bn. [S1]
- The largest supplier holds 8.0% of that value, the top five 21.5%, the top ten 29.0% and the top hundred 59.5%.
  The Herfindahl index is 139.4. Half the value sits with 45 suppliers and four-fifths with 872 suppliers;
  7,631 suppliers have a single award. [S2]
- The largest supplier's ₦210.29bn comes from 2 awards with one entity. [S3]
- By procurement method, the top supplier holds 6.9% in National Competitive Bidding (7,761 awards), but 61.4% in
  Emergency (363 awards, ₦342.3bn, Herfindahl index 4,238) and 57.5% where no method is stated (105 awards). [S4]
- Across 166 entities with at least 10 eligible awards, the median entity's largest supplier holds 21.0% of its award
  value; in 13 entities one supplier holds half or more. [S5]

**Reading.** Overall, supplier value is spread widely, with a long tail of one-off suppliers. Concentration rises
where the method itself limits competition (emergency) or the method is unrecorded. The overall top-supplier share
rests on one record that the source check classifies as a possible data-entry issue (§10), so it should not be quoted
without that caveat. Concentration is a lower bound for two reasons: 2,226 awards (₦670.4bn, 20.4% of eligible award
value) have only the bare `NG-BPP-` supplier ID and are excluded (DQ-14) [S1], and IDs are never merged by name, while
34.1% of the eligible value sits with supplier IDs that carry several name variants (DQ-13). [Q4]

| Stakeholder | Implication |
|---|---|
| Procurement management | Emergency procurement is where supplier value is most concentrated; it is the natural first area for review. |
| Procuring entities | An entity can compare its own top-supplier share with the peer median of 21.0% (166 entities). [S5] |
| Analysts | Report every concentration figure with the 20.4% exclusion and the lower-bound caveat. [S1] |
| Risk / advisory | The 13 entities where one supplier holds half the value are candidates for a documented review, not conclusions. [S5] |

**Recommendation.** Review a sample of emergency awards for the use of the method and the spread of suppliers.
Confirm the top supplier's two awards against the published award notices before using the 8.0% figure. [S2]
Ask the publisher to supply full supplier IDs for awards that carry the bare prefix.

---

## 4. Competition (business question 2, metrics M-C01 and M-C02)

**Observed**

- 17,253 tenders record a plausible count (one to a hundred tenderers). The median is 2 tenderers and 44.0%
  record a single bidder. [C1]
- 88.7% record five or fewer tenderers; the 90th percentile is 6 tenderers. [C2]
- Adding the 13 tenders with elevated counts (over a hundred, up to a thousand) leaves the rate at 44.0%
  (17,266 tenders). [C1]
- The single-bidder rate follows the method: Direct Procurement 89.5% (1,095 tenders), Sole Source 87.2% (47
  tenders) and Repeat Procurement 87.1% (280 tenders) are close to single-supplier by design; National Competitive
  Bidding is 39.6% (10,129 tenders), Emergency 51.6% (395 tenders) and National Shopping 23.7% (594 tenders). [C3]
- Across 103 entities with at least 30 tenders, rates run from 0% to 100%. At the high end, the Federal Ministry of
  Education headquarters records 96.4% across 442 tenders and the National Board for Technology Incubation 100%
  across 245 tenders; at the low end, the University of Abuja records 0% across 212 tenders. [C4]

**Reading.** Single-bidder tenders are common even in open competitive methods. That may reflect market depth,
lot design, the publication of only responsive bids, or reporting practice; the data cannot tell these apart. Entity
comparisons must hold the method constant, because methods differ so much.

| Stakeholder | Implication |
|---|---|
| Procurement management | About two in five National Competitive Bidding tenders draw one recorded bid; this is a material share of open competition. [C3] |
| Procuring entities | An entity's rate should be compared with peers using the same methods, not with the overall 44.0%. [C1] |
| Analysts | Confirm what `numberOfTenderers` counts before using it as a competition measure. |
| Risk / advisory | Entities at both extremes, with their tender counts, are a starting list for review. [C4] |

**Recommendation.** Review a sample of single-bidder National Competitive Bidding tenders to find out whether one
bid was received or one was found responsive. Then publish that distinction.

---

## 5. Budget versus award (business question 3, Pillar 4)

**Observed**

- 15,574 processes (98.8% of eligible awards) have exactly one usable budget line. Budgets total ₦12.4tn and awards
  ₦3,091.5bn: an aggregate ratio of 0.25, against a median ratio of 0.93. [B1]
- 6,564 processes (42.2%) are within a tenth of their budget and 5,300 (34.0%) are awarded at under half of budget. [B2]
- 227 processes (1.5%) are awarded more than ten times their budget. They hold ₦1,540.1bn, 49.8% of the compared award
  value. [B3]
- That group is concentrated. The Federal Ministry of Works & Housing headquarters has 98 of these processes, worth
  ₦929.8bn (60.4% of the group's value, median ratio 23.3). The Federal Capital Territory Administration has 13 worth
  ₦221.8bn, and HADEJIA-JAMAÄ»ARE RBDA (the name as published) has 9 worth ₦81.9bn. [B4]
- The Federal Ministry of Works & Housing headquarters also accounts for 56.5% of the summed absolute
  budget-to-award difference across 171 entities (net difference −₦5,559.9bn on 1,678 processes). [B5]
- A "budget recorded in thousands" pattern was tested and not found: only 9 processes are near a thousand times their
  budget. [B6]
- No budget line is compared with more than one process, so the totals are not inflated by sharing. [B6]

**Reading.** The typical process is awarded close to its budget [B1]. The aggregate ratio of 0.25 is pulled down by very
large planned budgets with smaller awards, so it should not be read as a saving. The group above ten times budget
holds half the compared value in only 1.5% of processes, which makes it the main risk to any value total [B3]. The source
check (§10) finds that several of HADEJIA-JAMAÄ»ARE RBDA's largest awards match a dropped-decimal pattern, and that
the FCTA group includes the ₦210bn record under review [S3]. A budget is a plan; an award below budget is not a saving,
and an award above it is not an overrun.

| Stakeholder | Implication |
|---|---|
| Procurement management | Value totals and budget execution figures depend on a small set of records; validate them before reporting. [B3] |
| Procuring entities | Entities with many processes above ten times budget should check how budget lines and award amounts were entered. [B4] |
| Analysts | Report the median ratio with the aggregate; flag processes above ten times budget rather than removing them. [B1] |
| Risk / advisory | The above-ten-times group is the highest-value area for record-level review in this dataset. [B3] |

**Recommendation.** Treat the above-ten-times group as a validation queue: confirm units and decimal entry for each
record, starting with the largest. Consider the proposed data-quality flag in §13.

---

## 6. Procurement-cycle timing (business question 4, metrics M-E01, M-E02 and signature lag)

**Observed**

| Measure | Eligible records | Share of candidates | Median | 90th percentile | Over one year |
|---|---|---|---|---|---|
| Tender open duration | 9,040 | 51.9% | 28 days | 64 days | 0.7% [T1] [T2] [T3] |
| Award lag (tender start to award) | 7,462 | 45.2% | 97 days | 267 days | 3.9% [T1] [T2] [T3] |
| Signature lag (award to signing) | 12,006 | 74.0% | 5 days | 62 days | 1.3% [T1] [T2] [T3] |

- Missing dates, not numbered data-quality issues, remove most records: 8,339 of the 8,365 tender-duration exclusions
  have no valid pair of dates. [Q2]
- 3,826 signature lags are same-day. [T3]
- Award lag varies by method: 9 days for Emergency (278 processes), 43 days for Selective Tendering (1,339), 112 days
  for Direct Procurement (241) and 120 days for National Competitive Bidding (4,856). [T4]
- Medians move between years: tender duration was 18 days for tenders starting in 2020 (1,459) and 42 days in 2021
  (1,578); award lag was 41 days for awards in 2020 (1,430) against 137 days in 2019 (1,263). [T5]
- Chronology conflicts are excluded, not corrected: 135 awards dated before their tender start and 734 contracts
  signed before their award. [Q3]

**Reading.** Where dates are valid, a typical open tender runs about four weeks and an award follows about three
months after the tender starts. The year-to-year swings may reflect changes in practice or in what was published; the
data cannot separate the two. The main finding is coverage: fewer than half of processes support an award-lag
measure.

| Stakeholder | Implication |
|---|---|
| Procurement management | Cycle-time reporting is possible only for the processes that publish dates; coverage should be a tracked indicator. [T2] |
| Procuring entities | Publishing tender start and award dates would bring an entity's processes into the timing measures. |
| Analysts | Compare timing within method, and always state coverage next to a median. [T4] |
| Risk / advisory | Very short emergency award lags are expected by design; the chronology conflicts are a reporting-quality signal. [Q3] |

**Recommendation.** Require valid tender-period and award dates for every published process, and report timing
coverage alongside cycle-time medians.

---

## 7. Procuring-entity benchmarking (business question 5)

**Observed**

- 665 entities hold 98,428 processes. [E1]
- The largest entity holds 40.6% of eligible award value but 5.2% of processes; the ten largest hold 76.0% of value
  and 26.9% of processes; the hundred largest hold 97.6% of value. [E2]
- The largest entity by value is the Federal Ministry of Works & Housing headquarters (₦1,335.1bn, 1,682 awards).
  Third is the Federal Medical Centre, Taraba State: ₦175.8bn from 10 awards and 28 processes, a value that rests
  on one record under source review (§10). [E3]
- KPI spread across entities that meet each minimum: median single-bidder rate 41.7% (103 entities), median
  top-supplier share 22.2% (173 entities), median implementation coverage 99.1% (123 entities) and median tender reach
  6.4% (373 entities). [E4]
- The 65 entities in the top quartile by value hold 94.8% of award value. [E5]
- The same entity can sit at opposite ends of different measures. The Federal Ministry of Works & Housing
  headquarters is at the competitive end on single bidders (3.7% of 1,635 tenders) and the dispersed end on
  supplier share (11.1%), but near the bottom on implementation coverage (21.6% of 1,677 contracts). [E6]

**Reading.** A few entities dominate value, so entity totals and portfolio-level shares are driven by them. Rankings
on one measure say little about another. The top-supplier median here (22.2%, 173 entities) differs slightly from
§3 (21.0%, 166 entities) because the benchmark counts every eligible award towards the minimum, including awards
without a usable supplier ID. [E4] [S5]

| Stakeholder | Implication |
|---|---|
| Procurement management | Oversight effort can be focused: the ten largest entities cover three quarters of value. [E2] |
| Procuring entities | Benchmark on each KPI with its own minimum population, and against peers using the same methods. [E4] |
| Analysts | Never rank entities on a KPI below its minimum n; show n beside every entity figure. |
| Risk / advisory | High value from very few awards (as at FMC Taraba) is a record to validate before any comparison. [E3] |

**Recommendation.** Use a multi-KPI profile per entity (value, competition, concentration, coverage, each with its n)
instead of a single league table, and validate outlying single records first.

---

## 8. Implementation reporting coverage (business question 6, metrics M-I01 and M-E03)

**Observed**

- 14,140 of 16,221 contracts (87.2%) carry implementation data; 2,081 carry none. [I1]
- 78.9% have transactions and milestones and 8.3% milestones only; 12.8% have neither. [I2]
- Coverage is similar across statuses (active 86.9% of 15,653 contracts) except pending contracts (74.4% of 121). [I3]
- Of 123 entities with at least 20 contracts, 52 report for every contract and 47 more for at least nine
  contracts in ten; 5 report for under half and 1 for none. The Federal Ministry of Works & Housing headquarters reports for 21.6% of 1,677
  contracts, and the National Inland Waterways Authority for 4.8% of 83. [I4]
- In the lifecycle, 17.7% of processes reach the tender stage (17,405 processes); of those, 95.0% reach award, 98.2%
  of awarded processes reach contract and 87.2% of contracts reach implementation. [I5]
- Transactions cannot support payment analysis: 78.9% of contracts have transactions without dates and with unclear
  value semantics. [Q5]

**Reading.** Most contracts publish something about implementation, so the gap is concentrated in a few large
entities. Coverage measures what was reported. A contract without implementation data may still have been delivered,
and one with data is not shown to be complete.

| Stakeholder | Implication |
|---|---|
| Procurement management | Coverage is a good reporting-compliance indicator, and the shortfall sits mainly with a few large entities. [I4] |
| Procuring entities | Low-coverage entities can close most of the gap by publishing milestones for existing contracts. |
| Analysts | Do not sum transaction values or measure payment timing from this source. [Q5] |
| Risk / advisory | Reporting gaps limit what downstream monitoring can see; they are not evidence about delivery. |

**Recommendation.** Track implementation coverage per entity as a publication indicator, starting with the
largest-volume entities that report for fewer than half of their contracts.

---

## 9. Data-quality impact (business question 7)

**Observed**

- Most metrics keep almost all candidates: budget 99.4%, competition 99.1%, award value 95.4% and budget-to-award
  98.8%. Supplier concentration keeps 85.9%; the timing measures keep 51.9%, 45.2% and 74.0%. [Q6]
- Issues that dominate a metric's value: 32 extreme budget lines hold 50.8% of candidate budget value (₦96.4tn,
  DQ-06), and one extreme award holds 23.3% of candidate award value (₦1,004.2bn, DQ-07). Both are excluded. [Q7]
- Issues that limit interpretation without removing records: planning-only processes (82.3%, DQ-02), supplier IDs
  with several names (34.1% of eligible supplier value, DQ-13), and transactions without dates or clear values (78.9%
  of contracts, DQ-11 and DQ-12). [Q1] [Q4] [Q5]
- The portal test entity (DQ-20) is removed before every population; it would have added 188 awards, 1.7% of
  candidate award value. [Q8]

**Reading.** The analysis is robust to most individual issues because each excluded group is small. The exceptions
are the extreme values, which would dominate any total if included, and the missing supplier IDs, which cut a fifth
of value out of supplier analysis. The source checks add one more: suspected magnitude-entry errors that the current
rules do not flag (§10).

| Stakeholder | Implication |
|---|---|
| Procurement management | Headline totals are reliable only with the extreme-value exclusions stated beside them. [Q7] |
| Procuring entities | Complete supplier IDs and dates are the two fixes that would most improve the entity's own figures. [S1] [Q6] |
| Analysts | Use `analytics.vw_dq_impact` to state the exclusion behind every figure. |
| Risk / advisory | Publication quality is itself a finding: it determines which questions the open data can answer. |

**Recommendation.** Publish the eligible population with every metric (as the dashboard does), and route the
proposed DQ-21 rule (§13) through a correction pass before external use of value totals.

---

## 10. Source verification of the open items

Phase 8 left three observed anomalies open. Each was checked in the raw JSON (read-only; evidence in
[`source_verification.md`](source_verification.md)). Nothing was excluded or changed. The classification is the
analyst's reading of the published record, not a finding about the parties.

| Item | What the source shows | Classification |
|---|---|---|
| A. The top supplier's ₦210.29bn (2 awards, FCTA) [S3] | One award, an emergency drainage lot, is roughly a thousand times the same supplier's award for a similar lot from the same buyer. Its budget line was first published at a fraction of the award and later replaced by a larger "service wide contingency" line shared with the other lot. Titles disagree across sections (Abaji, Bwari/Kubwa, Gwagwalada); one tenderer; no implementation data. | **Possible data-entry issue** (magnitude). It cannot be confirmed from the source alone. |
| B. Federal Medical Centre, Taraba State, ₦175.8bn from 10 awards [E3] | Nearly all of the value is one award for upgrading medical facilities. It has no budget line, no contract and only the bare supplier ID, so it is already outside supplier analysis, but inside award-value totals and the entity benchmark. The entity's other nine awards are of a far smaller order. | **Unresolved.** The magnitude is out of line with the entity's other records, but no internal comparator tests a specific error pattern. |
| C. HADEJIA-JAMAÄ»ARE RBDA, awards at 21.4 times budget in aggregate (58 processes) [B7] | 9 processes are above ten times budget (₦81.9bn) [B4]. Several are whole-naira amounts that become close to their budget when divided by a hundred; in one, the award equals the budget times a hundred exactly. That is the signature of a two-decimal amount entered without its decimal point. The name is double-encoded UTF-8 in the source and is kept as published. | **Possible data-entry issue** (dropped decimal) for the awards that pass the test; **unresolved** for the rest. |

**Effect on the findings.** Every figure stays as validated; the caveats above are stated where the figures appear
(§3, §5, §7). Item A drives the overall top-supplier share, and items A and C contribute to the group above ten times
budget. Item B drives one entity's value rank and part of the ₦670.4bn excluded from supplier analysis. [S1] A wider
read-only scan (`source_verification.md` §E) shows that ratios near a hundred are more frequent than ratios near a
thousand, which the Phase 8 unit test did not cover. That is the basis for the DQ-21 proposal in §13.

---

## 11. Recommendations

Each recommendation is proportional to its evidence. "Validate" means confirm a record against source documents;
"review" means examine a sample of processes; "improve reporting" means a publication change.

| # | Recommendation | Type | Main stakeholder | Basis |
|---|---|---|---|---|
| R1 | Confirm the three records in §10 against the published award notices before quoting any figure that depends on them. | Validate | Analysts, risk / advisory | §10 |
| R2 | Review a sample of emergency awards: concentration (top supplier 61.4%) and short award lags (9 days). [S4] [T4] | Review | Procurement management | §3, §6 |
| R3 | Review a sample of single-bidder National Competitive Bidding tenders (39.6% of 10,129) and define what the tenderer count records. [C3] | Review | Procurement management, analysts | §4 |
| R4 | Treat processes above ten times budget (227, holding 49.8% of compared value) as a validation queue for unit and decimal entry. [B3] | Validate | Procuring entities, analysts | §5 |
| R5 | Ask the publisher to complete supplier IDs: the bare prefix removes 20.4% of award value from supplier analysis. [S1] | Improve reporting | Risk / advisory | §3, §9 |
| R6 | Require valid tender and award dates; award lag can be measured for only 45.2% of candidates. [T2] | Improve reporting | Procuring entities | §6 |
| R7 | Track implementation coverage per entity as a publication indicator, not as performance. [I4] | Improve reporting | Procurement management | §8 |
| R8 | Benchmark entities on a multi-KPI profile with each KPI's n, within method. | Review | Procuring entities, analysts | §7 |

None of these recommendations presumes a cause. Each one tests a pattern before anyone draws a conclusion from it.

---

## 12. Assumptions and limitations

- **Coverage.** 82.3% of the 98,454 processes were published at planning stage only, so later-stage metrics describe a
  minority of processes (17.7% reach tender). [Q1] [I5] Timing metrics cover 51.9%, 45.2% and 74.0% of their
  candidates. [T2]
- **Entity resolution.** Supplier and buyer identities come from source IDs only; nothing is merged on name
  similarity. 2,226 awards with the bare supplier prefix are excluded from supplier analysis (₦670.4bn, 20.4%) [S1],
  and 34.1% of eligible supplier value sits with IDs that carry several names (DQ-13) [Q4]. Concentration is
  therefore a lower bound.
- **Release modelling.** Each process uses the latest release per lifecycle section (integer release order), so a
  process is counted once. The budget metric works at the budget-line grain (correction C-06), with 97,353 candidate
  lines; budget-to-award uses processes with exactly one budget line. [Q6]
- **Value semantics.** Tender value, award value and contract value are identical in every published record
  (correction C-08), so only budget against award is comparable. A budget is a plan, not spend.
- **Implementation.** Coverage is a reporting signal, not a measure of delivery or payment. Transaction values and
  dates are not used. [Q5]
- **Time.** There is no shared date dimension (decision P-10). Time analysis is possible only where valid event dates
  exist: tender start, award date and contract signature.
- **Exclusions by design.** The bare buyer prefix (DQ-19) is excluded from entity comparisons, and the portal test
  entity (DQ-20) from every metric. [Q8] Extreme budgets and awards (DQ-06, DQ-07) are excluded from value metrics. [Q7]
- **Magnitude entry.** Current rules do not flag suspected decimal or unit entry errors below the extreme-value
  threshold (§10, proposed DQ-21).
- **Snapshot.** The analysis is pinned to the source file identified by SHA-256 `6151466…bc90c`. Its package metadata
  is dated 2021-05-03, but its releases carry dates up to July 2026 (`source_verification.md` §D). The live portal now
  serves a newer export, so a fresh download will not reproduce these figures.
- **No causation.** All findings are descriptive. Differences between methods, years or entities are not attributed
  to any cause.

---

## 13. Proposals for the project owner (not applied)

| # | Proposal | Why | Effect if approved |
|---|---|---|---|
| DQ-21 | A new data-quality issue, "award magnitude inconsistent with its own process record". FLAG awards that pass the dropped-decimal test (a whole-naira award whose value divided by a hundred is within a factor of two of its budget line), and list sibling-lot anomalies of the item A kind for manual review. Recommended treatment: FLAG plus a sensitivity result set, not exclusion (outliers are not removed by rule). | §10 items A and C; ratio clustering near a hundred (`source_verification.md` §E). | Phase 10.1 correction pass: Phase 3 log entry, flag column, sensitivity result sets in scripts 01, 03 and 05, re-run of the Phase 7–9 suites and re-signing of the affected reconciliation rows. |
| C-12 | Correct the statement that every release carries the date 2021-05-03 (DQ-10 observed problem, Phase 2 profiling finding 10 and targeted validation, README audit table, `data/README.md` snapshot wording). Only the package metadata carries that date. | `source_verification.md` §D. No metric uses the release date, and integer release order agrees with release date in every multi-release process. | Documentation only; no figure changes. |

---

*Findings version 1.0 — 2026-10-17. Raw dataset not modified; no stg.*, core.* or analytics.* object changed.*
