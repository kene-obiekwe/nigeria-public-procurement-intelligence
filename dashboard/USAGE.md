# Dashboard Usage Note
# Nigeria Public Procurement Intelligence

> **Phase 9.** What the Power BI report shows, how to open it and how to read it. The build steps, every DAX measure and the
> reconciliation procedure are in [`README.md`](README.md). Screenshots of every page are in [`screenshots/`](screenshots/).

---

## 1. What this is

An 8-page report over the validated `analytics.*` views of the NOCOPO database. It follows the seven business questions in the project
scope. Every figure is calculated in PostgreSQL views or in a DAX measure that only aggregates (sum, count, median, rate); no
eligibility or data-quality exclusion is re-decided in Power BI. Every figure is shown with the number of records it is based on.

The report describes what was published to the Nigeria Open Contracting Portal (source file published 2021-05-03). It shows patterns
in reported data, not findings about conduct.

| Page | Question it answers |
|---|---|
| 1 Executive overview | What does the published record show, and how complete is it? |
| 2a Supplier concentration | How concentrated is awarded value among suppliers with a usable supplier ID? |
| 2b Competition | How many tenderers do processes record, and where is the single-bidder share higher or lower? |
| 3 Budget versus award | How does awarded value compare with recorded budgets? |
| 4 Procurement-cycle timing | What do valid dates say about how long stages take? |
| 5 Entity benchmark | Which entities account for the most activity, and how do they compare? |
| 6 Implementation and lifecycle | What share of contracts has implementation data published, and how far do processes progress? |
| 7 Data quality and coverage | Which data-quality issues could affect how the figures are read? |

## 2. Opening the report

Files in this folder:

| File | What it is |
|---|---|
| `NOCOPO_Dashboard.pbit` | Power BI template: the data model, the measures and the 8 pages, with no data and no credentials |
| `power_query_m.md` | The Power Query script for each of the 15 tables |
| `README.md` | Build guide, DAX measures, reconciliation procedure |
| `reconciliation_log.md`, `reconciliation_expected_values.sql` | The figure-by-figure check against SQL |

The `.pbix` (which holds imported data) is not kept in the repository.

To open the template:

1. Have the database built and validated (`nocopo_db` on `localhost:5433`, the `analytics` views, and the read-only role `nocopo_bi`;
   see `README.md` §2 and `database/seed_and_setup/`). Set the role's password yourself; no password is stored anywhere in this repository.
2. In Power BI Desktop choose **File → Open** and select `NOCOPO_Dashboard.pbit`.
3. When asked for credentials, choose the **Database** tab and sign in as `nocopo_bi`. If Power BI reports that the server does not
   support SSL, untick *Encrypt connections* (local server).
4. Power BI imports the data. The row counts should match `README.md` §4.1. Then save the result as a `.pbix`.

The template was exported from the finished report. Opening it on a second computer has not been tested.

## 3. Reading the report

- **Eligible n.** Each card shows its result and, beside it, the number of records the result is calculated on. Records that do not
  meet a metric's eligibility rules are excluded from that metric only, and stay in the database. Cards show rounded values (98K, 93T);
  tables show exact values.
- **Slicers.** *Procuring entity* and *Procurement method* filter the page they are on. Only the visuals whose data has the field
  respond to them: budgets, lifecycle, contracts and the entity table carry no procurement method, so the method slicer does not change
  them. Slice on the entity label, which carries the buyer ID, not on the name alone (four names are shared by two IDs and are
  deliberately not merged).
- **Top N and minimum n.** The *Top N* slicer sets the N in "the N largest suppliers/entities" (default 10). The minimum-n slicers on
  page 5 (defaults 30 tenders, 10 awards, 20 contracts, 30 processes) blank a KPI for an entity with fewer records than that.
- **Ranked tables.** The highest/lowest tables on pages 2b, 3 and 6 list entities that meet a minimum number of records. Entities that
  tie on the value at the cut-off are all listed, so a table can show more rows than its heading suggests.
- **Scrolling.** Long reference lists scroll inside the report (the method tables on pages 3 and 4, the 665-entity table on page 5, the
  register and the issues table on page 7). Each says so in its subtitle. A PDF or screenshot shows only the first rows.

## 4. Known limitations

These are carried from the data-quality decision log and the Phase 8 and 9 documents. They are properties of the data or of the design,
not defects.

- **Supplier concentration is a lower bound.** 2,226 eligible awards (NGN 670.4bn, 20.4% of eligible award value) carry the bare buyer
  ID `NG-BPP-` as supplier and cannot be attributed to a supplier (DQ-19, DQ-14). Suppliers are identified by source ID and are not
  merged on name similarity, so true concentration may be higher.
- **Single bidder is a count pattern.** The meaning of the number of tenderers (bids received or expressions of interest) is not
  confirmed in the source. Direct Procurement, Sole Source and Repeat Procurement are single-supplier by design.
- **A budget is a plan.** Awarded value as a multiple of planned budget is a difference between two recorded figures only. 16
  budgets under NGN 100,000 look like placeholder entries; they are kept and produce the extreme ratios.
- **Dates are sparse.** Valid dates exist for about 52% of tenders (tender duration), 45% of processes (award lag) and 74% of
  contracts (signature lag). Missing dates are reporting gaps, not delays. There is no shared date dimension (decision of 2026-10-14);
  time analysis is limited to the award and timing pages.
- **Implementation coverage is reporting coverage.** It shows whether implementation data was published, not how a contract
  performed. Transaction dates are absent and transaction values are not analysed (DQ-11, DQ-12).
- **The portal test entity** (`TEST MINISTRY - NOCOPO`) is excluded from every population (DQ-20).
- **Entity names are shown as published.** The source file stores some names with character-encoding artefacts (for example
  `HADEJIA-JAMAÄ»ARE RBDA`). They are kept as published, because original source names are preserved; the buyer ID identifies the entity.
- **Entity-level medians are precomputed** per entity in SQL and cannot be recombined across entities.

## 5. Keeping it correct

After any change to the data or the views: refresh the database snapshot, re-run the validation suites (`--phase 7`, `--phase 8`,
`--phase 9`), refresh the report, and re-run the reconciliation (`README.md` §9). `reconciliation_log.md` records the last full
check: 177 figures, 177 matching the SQL.
