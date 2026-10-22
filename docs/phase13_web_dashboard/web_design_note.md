# Phase 13 Design Note: Interactive Web Dashboard
# Nigeria Public Procurement Intelligence

> **Phase:** 13 · **Date:** 2026-10-21, revised 2026-10-22 · **Status:** approved by the owner on 2026-10-22, with the
> amendments recorded in §7. Sizes are those of the built export (`web/data/manifest.json`).
> **Decisions already made:** W-01 (static site in `web/`, Vercel root `web/`), W-02 (plain HTML/CSS/JS plus pinned ECharts),
> W-03 (`python/web/export_web_data.py` writes committed JSON to `web/data/`), W-04 (`python/web/check_web_data.py` reconciles
> against `dashboard/reconciliation_expected_values.sql`).
> **Spec:** the eight Power BI pages (`dashboard/screenshots/`), `dashboard/README.md` §4–§8 and `dashboard/USAGE.md`.

---

## 1. Summary of the proposal

The Power BI report is an Import model: it holds row-level facts (about 300,000 rows) and computes every measure live under
the slicers. The web version should do the same, on a much smaller footprint: ship **slim, dictionary-encoded, row-level
facts** only where a measure cannot be pre-summed (medians, percentiles, Top N, distinct counts, per-supplier ranks), and
**pre-aggregated counts and sums** where it can (lifecycle, budget lines, contracts). Every figure is then computed in the
browser by a small set of pure functions that mirror the DAX measures one for one.

Measured on the built export: **2.17 MB of JSON raw, 0.47 MB gzipped**, which Vercel serves compressed. All 177 reconciliation figures can be reproduced from this data. No server, no database and
no build step are needed.

---

## 2. Data shape per page

### 2.1 Shared encoding

- **Dimensions** (`dims.json`): the 665 buyers (`buyer_id`, `buyer_label`, `buyer_name`), the 11 methods and the tender
  and contract statuses, each referred to by its array
  index in the fact files. Buyer index `-1` is the bare `NG-BPP-` ID (DQ-19): it counts in totals and has no dropdown entry,
  exactly as the Power BI "(Blank)" behaviour (README §4.3). A NULL method becomes `(method not stated)`, as in Power Query.
- **Columnar files**: each fact file is `{column: [values...]}` rather than an array of objects (about three times smaller).
- **Money in kobo, as integers.** Every eligible amount is a whole number of kobo (measured: 0 sub-kobo values in budgets,
  awards and budget-to-award) and every single value is below 2^53, so it is exact in JSON. Totals are summed with
  JavaScript `BigInt`, because the planned-budget total (9.33 × 10^15 kobo) is larger than 2^53. This is what makes
  "agrees to the whole naira" achievable; summing floating-point naira would not be.
- **Ratios** are shipped as the view's four-decimal value, so medians match the SQL `percentile_cont` over the same values.
- **Generation metadata** (`manifest.json`): source SHA-256, generation time, database and every file's row count and
  SHA-256, so the check script and the site can show and verify what they are reading.

### 2.2 Files, grain and size

| File | Source view(s) | Grain | Columns | Rows | Raw KB | gzip KB |
|---|---|---|---|---|---|---|
| `dims.json` | `vw_dim_buyer`, `vw_dim_procurement_method` | buyer; method | ID, label, name; method; statuses | 665 + 11 | 79 | 14 |
| `lifecycle.json` | `vw_lifecycle_stage` | **aggregated** (buyer × highest stage) | buyer, stage, count | 98,454 summarised | 10 | 3 |
| `budget.json` | `vw_budget_eligible` | **aggregated** (buyer) | buyer, lines, sum (kobo) | 96,802 summarised | 13 | 6 |
| `competition.json` | `vw_competition_eligible` | row (OCID) | buyer, method, status, tenderers, primary flag, single-bidder flag | 17,266 | 234 | 15 |
| `awards.json` | `vw_award_value_eligible` + `vw_supplier_award_eligible` + `vw_award_scale_flag` | row (award) | buyer, method, value, supplier index (−1 when no usable ID), DQ-21 flag (bit 1 dropped-decimal test, bit 2 sibling-lot test) | 15,763 | 360 | 108 |
| `suppliers.json` | `vw_supplier_award_eligible` | supplier | supplier ID, name, name-variant count | 9,800 | 503 | 127 |
| `budget_award.json` | `vw_budget_award_comparison` + DQ-21 flag | row (OCID) | buyer, method, budget, award, ratio, DQ-21 flag | 15,574 | 557 | 136 |
| `tender_duration.json` | `vw_tender_duration_eligible` | row | buyer, method, start year, days | 9,040 | 121 | 8 |
| `award_lag.json` | `vw_award_lag_eligible` | row | buyer, method, award year, days | 7,462 | 104 | 9 |
| `signature_lag.json` | `vw_signature_lag_eligible` | row | buyer, days | 12,006 | 73 | 13 |
| `contracts.json` | `vw_contract_implementation_coverage` | **aggregated** (buyer × status × data type) | buyer, status, type, has data, count | 16,221 summarised | 6 | 1 |
| `entities.json` | `vw_entity_benchmark` | entity (precomputed KPIs) | all KPI columns | 665 | 56 | 17 |
| `registers.json` | `vw_metric_population`, `vw_dq_impact` | metric; metric × issue | all columns | 12 + 47 | 14 | 3 |
| `expected.json` | reconciliation pack; Phase 10.1 result sets | figure; result-set row | the values the self-check compares against | 177 + 7 result sets | 40 | 7 |
| `manifest.json` | — | — | source, role, row counts, per-file size and SHA-256 | — | 3 | 1 |
| **Total** | | | | | **2,170** | **468** |

**Nothing approaches the 5 MB target.** The vendored
ECharts library adds about 1 MB raw (about 0.35 MB gzipped).

**Why each grain.** A file is aggregated only when every measure on it is a count or a sum and every filter that touches it
is a column of the aggregate:
- *Lifecycle* (M-E03): counts by stage; filtered by buyer only (no method). Buyer × stage is exact.
- *Budget* (M-P01): sum and count; filtered by buyer only. Buyer is exact.
- *Contracts* (M-I01): counts; filtered by buyer and contract status. Buyer × status × data type is exact.

Everything with a median, percentile, Top N, distinct count or rank stays at row level, because those cannot be
recombined from partial aggregates (§3).

### 2.3 Which filter touches which visual

As in `USAGE.md`: a slicer affects only the visuals whose data carries the field. "—" means the visual ignores the control.

| Page | Visual data | Entity | Method | Other controls |
|---|---|---|---|---|
| 1 Executive overview | all cards, eligibility bar, M-S01 disclosure | — (no slicers, as in Power BI) | — | — |
| 2a Supplier concentration | awards / suppliers | yes | yes | Top N (1–100, default 10) |
| 2b Competition | competition rows | yes | yes | — |
| 2b Competition | highest/lowest entity tables | yes (entity table) | — (precomputed per entity) | minimum 30 tenders (fixed, as in Power BI) |
| 3 Budget versus award | budget-to-award rows | yes | yes | — |
| 4 Timing | tender duration, award lag | yes | yes | tender start year, award year |
| 4 Timing | signature lag | yes | — (no method in the view) | — |
| 4 Timing | coverage cards | — (register values) | — | — |
| 5 Entity benchmark | entity table, cards, top-15 bar | yes | — | Top N; minimum tenders / awards / contracts / processes |
| 6 Implementation and lifecycle | contracts | yes | — | contract status |
| 6 Implementation and lifecycle | funnel (lifecycle) | yes | — | — (no status in lifecycle) |
| 6 Implementation and lifecycle | lowest-coverage table | yes (entity table) | — | minimum 20 contracts |
| 7 Data quality | registers | — | — | metric, impact type |

The method dropdown is shown only on pages 2a, 2b, 3 and 4; the entity dropdown on every page except 1 and 7.

---

## 3. Measures that cannot be pre-summed

| Measure type | Examples | How it stays correct under every filter |
|---|---|---|
| Median, percentile | median award value, median tenderers, median ratio, median days, 90th percentile days | Computed in the browser over the filtered rows with linear interpolation, the same definition as SQL `percentile_cont` and DAX `PERCENTILE.INC` / `MEDIAN` |
| Top N share, HHI, suppliers with one award | 2a cards, top-20 table, by-method bar | Group the filtered award rows by supplier index, sum value (BigInt), sort descending; ties at the cut-off are all included, as DAX `TOPN` does (no ties at the reconciled cut-offs 1, 5, 10, 20, 100) |
| Cumulative share, rank | 2a top-20 table | Same grouping; rank and share are relative to all suppliers in the current filter (the P-12 definition) |
| Distinct counts | suppliers (n), M-S01 eligible awards | Distinct supplier indices / award rows in the filtered set (one award per row) |
| Entity KPIs and their medians | page 5 table, yardstick cards, 2b and 6 ranked tables | Precomputed per entity in SQL (never recombined); the yardstick medians are medians over entities meeting the minimum n, as `MEDIANX` |
| Top N entity share | page 5 card | Sum of entity award totals for the N largest entities in the filtered entity set |
| DQ-21 sensitivity | "without flagged awards" figures | The same functions over rows with the DQ-21 flag removed |

**Options considered.**

| Option | For | Against |
|---|---|---|
| **A. Row-level slim facts, compute in the browser (recommended)** | Exact for every measure and every filter combination; one implementation per DAX measure; about 0.5 MB gzipped | Needs careful JS (interpolation, BigInt, ties); mitigated by the in-browser self-check (§5) |
| B. Precompute every filter combination in Python | No computation in the browser | 666 entities × 12 methods × Top N 1–100 × years × statuses is hundreds of thousands of result sets, many megabytes, and a second implementation of every measure in Python |
| C. Hybrid: precompute "All" figures, row-level only for filtered views | Slightly simpler first paint | Two code paths for the same figure, which is exactly how reconciliations drift |

Filtering 17,000 rows and recomputing a page takes milliseconds even on a phone, so option A has no performance cost.

---

## 4. Reconciliation (W-04)

`python/web/check_web_data.py` will:

1. Run `dashboard/reconciliation_expected_values.sql` read-only against the database (the 177 expected values).
2. Recompute each figure **from the exported JSON** with the same slice (method, buyer, tender status, contract status, tender
   start year, stage, population, minimum n), using a Python implementation of the functions in §3.
3. Compare under the log's tolerances (counts, days and bands exact; NGN to the whole naira; ratios and shares to four
   decimals) and write `docs/phase13_web_dashboard/web_reconciliation_results.md`.

**Applicability: all 177 figures apply.** Every slice the pack uses (129 unsliced; 10 method, 7 buyer, 9 stage, 8 population,
7 metric, 2 tender start year, 1 tender status, 1 contract status, 3 minimum n) is a field of the exported data. One note:
IMP-T3 ("transactions only" contracts) is 0 in SQL and blank in Power BI; the web shows 0, which matches the SQL value.

**The JS must be checked too, not only the JSON.** A Python re-implementation proves the data is complete and exact, but the
site computes with JavaScript. So the build also includes `web/check.html`: a page, not linked from the navigation, that runs
the site's own metric functions over the JSON against an `expected.json` written by the export script from the same SQL pack,
and lists PASS/FAIL for each figure. The build runs it in a browser and records the result in the reconciliation
document. Both checks must show 177 / 177.

**DQ-21 sensitivity figures** are not in the 177-figure pack (the Power BI report never showed them, OI-11). They will be
checked against the Phase 10.1 result sets (script 01 RS6/RS6b, script 03 RS11/RS11a/RS11b, script 05 RS7/RS7b) in the
same results document, as a separate section.

---

## 5. Page layout and file structure

### 5.1 Layout

One page, `index.html`, with hash routing (`#overview`, `#suppliers`, `#competition`, `#budget`, `#timing`, `#entities`,
`#implementation`, `#data-quality`), so each page has a shareable link and the back button works.

- **Desktop (≥ 1024 px):** left sidebar with the eight page tabs and the "About this data" note, as in Power BI; main area:
  title and question, control bar, a card grid (four per row), then two-column chart and table panels; caveat text and
  footer below.
- **Tablet (600–1023 px):** the sidebar becomes a top bar; cards two per row; panels stack.
- **Phone (375 px):** a page menu (native `<select>`, so it is accessible and needs no script to open); cards one or two per
  row; every panel full width; long tables scroll inside their own box (`overflow-x: auto`) so the page itself never scrolls
  sideways; charts redraw on resize.
- **Cards** show the compact value (98K, 93T) and the eligible n, as in Power BI; the exact value is in the card's tooltip and
  `title`, and in a `data-value` attribute that the self-check reads.
- **Entity dropdown:** 665 entries is too long for a plain list on a phone, so it is a searchable input (`<input list>` with a
  `<datalist>`, keyed on `buyer_label`, which carries the buyer ID); method, Top N, minimum-n, year and status controls are
  plain `<select>` elements.
- **Light and dark:** CSS custom properties with `prefers-color-scheme`, a manual toggle, and matching ECharts themes. Colours
  stay neutral: no red/green good/bad colouring (README §7.3).
- **Text:** every caveat from README §8 verbatim, including the C-12 source line; the M-S01 disclosure computed from the
  data, not typed in; the DQ-20 and DQ-19 notes on page 7; the DQ-21 note wherever a figure moves without flagged awards.
  The words in README §7.3 are banned; the check script greps the site for them.
- **Footer on every page:** data source (NOCOPO OCDS export, Bureau of Public Procurement, ODC-PDDL), code licence (MIT),
  ECharts licence (Apache-2.0), link to the GitHub repository. No tracking, cookies, analytics or external requests.

### 5.2 Files

```
web/
├── index.html                 single page: sidebar/menu, page containers, footer
├── check.html                 in-browser reconciliation self-check (not linked from the navigation)
├── vercel.json                headers only: cache rules for data/vendor, basic security headers; no build
├── favicon.svg
├── css/site.css               layout, responsive breakpoints, light/dark tokens
├── js/
│   ├── data.js                load and decode JSON, BigInt helpers
│   ├── metrics.js             pure functions mirroring the DAX measures (median, percentile, Top N, HHI, ...)
│   ├── format.js              compact and exact number formats, exact rounding
│   ├── check.js               figure-by-figure comparison used by check.html
│   ├── charts.js              ECharts setup, themes, resize handling
│   ├── state.js               filters per page, URL hash
│   └── pages/                 overview.js, suppliers.js, competition.js, budget.js, timing.js, entities.js,
│                              implementation.js, data_quality.js
├── vendor/
│   ├── echarts-<version>.min.js   pinned, vendored (no runtime CDN)
│   └── ECHARTS-LICENSE.txt
└── data/                      generated by python/web/export_web_data.py; committed
    ├── manifest.json, expected.json, dims.json, ...   (the files in §2.2)

python/web/export_web_data.py     reads analytics.* only, read-only transaction; writes web/data/
python/web/check_web_data.py      177-figure reconciliation + DQ-21 checks + banned-word scan; writes the results doc
docs/phase13_web_dashboard/
├── web_design_note.md          this note
├── web_reconciliation_results.md   generated
└── web_dashboard.md            how to rebuild, check and redeploy
```

No build step is needed: ES modules load directly in every current browser, and ECharts is a single file.

---

## 6. Risks and open questions

| # | Question or risk | Recommendation |
|---|---|---|
| Q-1 | Data shape: row-level facts in the browser (option A), precompute every combination (B) or hybrid (C)? | **A** (§3). |
| Q-2 | ECharts: vendored file or CDN? | **Vendored**, pinned to an exact 5.x release with its licence. No third-party request at runtime, works offline, and the version cannot change under the site. The repository grows by about 1 MB. |
| Q-3 | How to show DQ-21 (new on the web; not in Power BI)? | **A toggle**, "Include awards flagged as possible scale errors", on pages 1, 2a, 3 and 5, **on by default** (the published figures, which reconcile to the 177), with a fixed note giving the flagged count and value. Switching it off shows the Phase 10.1 sensitivity figures. Alternative: static callouts only. |
| Q-4 | Reconciliation of the JavaScript, not only the JSON | **Both checks** (§4): Python from the JSON (W-04) and `check.html` running the site's own functions. |
| Q-5 | Extra Power BI controls not named in the task: tender start year and award year (page 4), contract status (page 6), metric and impact type (page 7) | **Keep them**, for parity with the report; each is cheap in the browser. |
| Q-6 | Card values: compact (98K) as in Power BI, or exact? | **Compact on the card, exact on hover/tap**, as in Power BI; reconciliation reads exact values. |
| Q-7 | Who connects for the export: `postgres` or the read-only BI role `nocopo_bi`? | **Read `analytics.*` only, in a read-only transaction, with a static check like the analysis runner's**; the user comes from `PGUSER` (works as `nocopo_bi`, which keeps Gate C literally true). |
| Q-8 | JSON is committed and must never drift from the pinned database | The export writes `manifest.json` (source SHA-256, row counts, per-file SHA-256); the check script verifies the manifest before comparing figures. |
| Q-9 | Floating-point totals | Avoided by integer kobo and BigInt sums (§2.1). |
| Q-10 | Entity names with encoding artefacts (`HADEJIA-JAMAÄ»ARE RBDA`) | **Show as published**, as in Power BI and the findings. |
| Q-11 | Entity search on phones | `<input list>` + `<datalist>` (native, accessible, no library). Some mobile browsers render datalists sparsely; fallback is typing part of the name or code. |
| Q-12 | Release | **Tag `v1.1`** after the owner approves the built site and its reconciliation. The Vercel project, the tag and any push are made only with the owner's go-ahead. |
| Q-13 | Public wording | Same neutral titles and caveats as Power BI; no portfolio or career text; no tracking. |
| R-1 | Ties in Top N or ranked tables at non-default N | Same semantics as DAX (ties included); documented in a caption, as in `USAGE.md`. |
| R-2 | Repository size | About +3.3 MB (JSON plus ECharts); acceptable, and the JSON changes only if the pinned data changes. |

---

## 7. Decisions (2026-10-22)

The owner approved Q-1 to Q-13 as recommended in §6, with these amendments:

| # | Amendment |
|---|---|
| F-2 | **DQ-21 on page 5.** Switching off flagged awards may change only figures derived by summing award rows (entity award totals, the top-N entity share, the award-value rank), checked against script 05 RS7/RS7b. Precomputed per-entity medians and KPIs from `vw_entity_benchmark` stay as published, and a caption says so. On pages 1, 2a and 3, no figure may be shown without flagged awards unless a Phase 10.1 result set checks it. |
| F-3 | **Roles.** `export_web_data.py` must run as `nocopo_bi`: a read-only transaction, `analytics.*` only, and a static check that its SQL names no other schema. `check_web_data.py` also reads only `analytics.*` (the reconciliation pack and the Phase 10.1 result sets do), so it needs no more than `nocopo_bi` either. |
| F-4 | **Stage 2 is split.** Stage 2a builds the data and the calculation engine (export, Python check, `data.js`, `metrics.js`, `format.js`, `check.html`); stage 2b builds the pages. |
| D-1 | **DQ-21 on pages 1, 2a and 3** (owner's choice, option A). The Phase 10.1 result sets check only unfiltered headline figures, so each of these pages has a fixed panel, "Sensitivity: without awards flagged as possible scale errors (DQ-21)", showing only checked figures: on page 1 the top-10 supplier share and the median award-to-budget ratio (01 RS6, 03 RS11); on page 2a the M-S01 award count and value, the top 1/5/10/100 shares, the HHI, the largest supplier, and the top-1 share and HHI by method (01 RS6, RS6b); on page 3 the comparable count, the budget and award totals, the aggregate and median ratios and the above-10x band (03 RS11). The panel does not respond to the page filters, and its caption says so. Page 5 keeps the toggle, limited as in F-2. Options not taken: new sensitivity result sets in `sql/06_analysis` (would change existing SQL and outputs); DQ-21 on page 5 only. |
