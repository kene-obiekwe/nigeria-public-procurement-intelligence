# Power BI Dashboard Blueprint
# Nigeria Public Procurement Intelligence

> **Phase 9.** This guide contains everything needed to build the report in Power BI Desktop without
> further questions: the connection, the data model, every DAX measure, the page layout with mandatory
> caveats, and the reconciliation procedure. The `.pbix` file is built by the project owner; nothing in
> this repository creates or edits one.
>
> **Status of this guide:** written against the validated `analytics.*` layer as of 2026-10-08 (Phase 8.1
> populations). The DAX and Power Query below were checked line by line against the SQL definitions and
> the expected values in `reconciliation_expected_values.sql`, but they could not be run inside Power BI
> Desktop here. Any difference you find when you build is a defect to report; the reconciliation log
> (§9) is how you find it.

---

## 1. Rules the report follows

1. **Gate C.** Power BI connects only to `analytics.*`, through the read-only role `nocopo_bi`. The role
   has no privilege on `stg` or `core`, so the rule is enforced by the database, not by convention.
2. **SQL-first.** Eligibility, deduplication, the process snapshot and every data-quality exclusion live
   in PostgreSQL. DAX only aggregates (sum, count, median, percentile, rate) and applies slicers. DAX
   never re-decides which records count. Where DAX needs a parameter that SQL also uses (minimum n, band
   cut-offs), it is listed in §5.5 as a documented duplicate and checked by the reconciliation pack.
3. **Every figure carries its eligible n.** Each measure has a companion "n" measure (§5), and each card or
   chart shows it.
4. **Observation, not accusation.** No title, label, tooltip or caption uses fraud, corruption, collusion,
   misconduct or causal wording. §7.3 lists the words to avoid and neutral replacements.
5. **The population register travels with the figures** (`MetricPopulation`, page 7).

---

## 2. One-time setup: the read-only role

1. As the database owner, create the role and its grants (no password is set by the script):

   ```bash
   psql -h localhost -p 5433 -U postgres -d nocopo_db -v ON_ERROR_STOP=1 -f database/seed_and_setup/01_create_bi_role.sql
   ```

2. Set the password yourself. Nothing is stored in the repository:

   ```bash
   psql -h localhost -p 5433 -U postgres -d nocopo_db
   ```

   then, inside psql, type `\password nocopo_bi` and enter the password twice. (`pg_hba.conf` requires
   `scram-sha-256` on localhost, so a password is mandatory.)

3. Prove the gate (optional but recommended; no password needed, it uses `SET ROLE`):

   ```bash
   psql -h localhost -p 5433 -U postgres -d nocopo_db -f database/seed_and_setup/02_test_bi_role.sql
   ```

   Expected: `analytics.*` queries return rows; every `stg.*`, `core.*`, write and DDL attempt prints
   `permission denied`. `04_run_validation_suite.py --phase 9` repeats these checks (BI-01 to BI-05).

4. Re-run step 1 after any rebuild that drops views (`DROP ... CASCADE` removes their grants).

---

## 3. Connection and refresh

| Setting | Value |
|---|---|
| Connector | Get data → **PostgreSQL database** |
| Server | `localhost:5433` |
| Database | `nocopo_db` |
| Data connectivity mode | **Import** |
| Credentials | *Database* tab → user `nocopo_bi`, the password you set in §2 |
| Encryption | If Power BI reports that the server does not support SSL, untick *Encrypt connections* (local server) |
| Navigator | Schema **analytics** only. If you can see `stg` or `core`, you are connected as the wrong user |

**Why Import and not DirectQuery.**
- The whole layer is about 300,000 rows across 15 tables (a few tens of MB compressed). Import is small and fast.
- Medians, percentiles and `TOPN` are the core measures. They are complete and fast in the Import engine and
  restricted or slow over DirectQuery.
- The analysis is pinned to one source file (SHA-256 `6151466…bc90c`, published 2021-05-03). The data change
  only when the database is rebuilt, so a stored snapshot is the right shape: the dashboard shows exactly what
  was validated, and it never queries a half-rebuilt database.
- A local PostgreSQL needs a gateway for the Power BI service; Import with a `.pbix` shared as a file avoids that.

**Refresh sequence** (needed only when the data changed):

1. If `stg.*` or `core.dim_buyer` changed, refresh the materialised snapshot in PostgreSQL **first**:

   ```bash
   psql -h localhost -p 5433 -U postgres -d nocopo_db -v ON_ERROR_STOP=1 -f sql/04_transformations/04_refresh_snapshot.sql
   ```

   The analytics views read the materialised snapshot. Skipping this step makes Power BI import stale figures
   and the reconciliation fail.
2. If views were rebuilt, re-run `sql/05_views/01` to `10` and then `database/seed_and_setup/01_create_bi_role.sql`.
3. Run the validation suites (`04_run_validation_suite.py --phase 7`, `--phase 8`, `--phase 9`). They must pass.
4. In Power BI Desktop, **Home → Refresh**. A full refresh takes seconds to a minute.
5. Re-run the reconciliation (§9).

---

## 4. Data model

### 4.1 Tables to import

Load each view from the **analytics** schema, then apply the Power Query steps in §4.2. Rename the table as shown.
The *rows* column is the expected row count after load (as of 2026-10-08); a different count means the model is
not reading the validated view.

| Power BI table | analytics view | Grain (one row per) | Rows | Role |
|---|---|---|---|---|
| `DimBuyer` | `vw_dim_buyer` | complete procuring entity | 665 | dimension |
| `DimMethod` | `vw_dim_procurement_method` | procurement method (plus "not stated") | 11 | dimension |
| `Budget` | `vw_budget_eligible` | planning budget line | 96,802 | fact (M-P01) |
| `Competition` | `vw_competition_eligible` | OCID with a tender | 17,266 | fact (M-C01, M-C02) |
| `Awards` | `vw_award_value_eligible` | OCID with one active award | 15,763 | fact (M-V01) |
| `Suppliers` | `vw_supplier_award_eligible` | award × distinct supplier | 13,537 | fact (M-S01) |
| `BudgetVsAward` | `vw_budget_award_comparison` | OCID | 15,574 | fact (Pillar 4) |
| `TenderDuration` | `vw_tender_duration_eligible` | OCID | 9,040 | fact (M-E01) |
| `AwardLag` | `vw_award_lag_eligible` | OCID | 7,462 | fact (M-E02) |
| `SignatureLag` | `vw_signature_lag_eligible` | contract | 12,006 | fact (signature lag) |
| `Lifecycle` | `vw_lifecycle_stage` | OCID | 98,454 | fact (M-E03) |
| `Contracts` | `vw_contract_implementation_coverage` | contract | 16,221 | fact (M-I01) |
| `EntityBenchmark` | `vw_entity_benchmark` | complete procuring entity | 665 | entity KPIs |
| `MetricPopulation` | `vw_metric_population` | metric | 12 | register |
| `DQImpact` | `vw_dq_impact` | metric × data-quality issue | 47 | register |

Do **not** import any other object. There is no date table because several views carry no date (see §10).

### 4.2 Power Query steps (all tables)

For every table:

1. **Choose columns** exactly as below (this drops long text and the array column, which the connector may not read).
2. **Rename** `procurement_method_details` to `procurement_method` where it exists, and **replace null with
   `(method not stated)`** in that column. This is a label for the relationship to match, not a business rule: the
   fact views carry NULL for "not stated" and `DimMethod` has an explicit row for it.
3. **Data types**: monetary columns (`*_amount`, `award_value_*`, `variance_amount`, `*_total`, `eligible_value_ngn`,
   `affected_value_ngn`) → **Fixed decimal number**; counts → **Whole number**; ratios and rates → **Decimal number**;
   flags → **True/False**; dates → **Date**. Fixed decimal is needed because the monetary totals have 14 digits and a
   floating-point total can differ from SQL in the last digit. The largest total, planned budget at about NGN 93.3
   trillion, fits the Fixed decimal range (about 922 trillion).

| Table | Keep these columns | Drop |
|---|---|---|
| `DimBuyer` | buyer_id, buyer_name, buyer_code, buyer_label | — |
| `DimMethod` | procurement_method, is_not_stated | — |
| `Budget` | ocid, budget_project_id, buyer_id, budget_amount, budget_currency, multi_project_flag | release_id, buyer_name, budget_description, budget_project |
| `Competition` | ocid, tender_id, buyer_id, procurement_method, tender_status, number_of_tenderers, tenderer_count_flag, in_primary_population, is_single_bidder | tender_release_id, buyer_name, buyer_id_flag |
| `Awards` | ocid, award_id, buyer_id, procurement_method, award_value_amount, award_date, award_date_flag | award_release_id, buyer_name, buyer_id_flag, award_value_currency |
| `Suppliers` | ocid, award_id, buyer_id, procurement_method, supplier_id, supplier_name, name_variant_count, award_value_amount | buyer_name, buyer_id_flag, distinct_supplier_count |
| `BudgetVsAward` | ocid, award_id, buyer_id, procurement_method, budget_project_id, budget_amount, award_value_amount, variance_amount, award_to_budget_ratio | buyer_name, buyer_id_flag |
| `TenderDuration` | ocid, buyer_id, procurement_method, tender_start_date, tender_end_date, tender_duration_days | tender_release_id, buyer_name, buyer_id_flag |
| `AwardLag` | ocid, award_id, buyer_id, procurement_method, award_status, tender_start_date, award_date, award_lag_days | buyer_name, buyer_id_flag |
| `SignatureLag` | ocid, contract_id, buyer_id, award_date, date_signed, signature_lag_days | buyer_name, buyer_id_flag |
| `Lifecycle` | ocid, buyer_id, release_count, highest_stage_rank, highest_stage | tags_observed (array), buyer_name, buyer_id_flag |
| `Contracts` | ocid, contract_id, buyer_id, contract_status, has_implementation, transaction_count, implementation_milestone_count | contract_release_id, buyer_name, buyer_id_flag |
| `EntityBenchmark` | all columns except buyer_name | buyer_name |
| `MetricPopulation` | all columns | — |
| `DQImpact` | all columns | — |

Example for one table (the others follow the same pattern; the exact step names do not matter):

```
let
    Source   = PostgreSQL.Database("localhost:5433", "nocopo_db"),
    Raw      = Source{[Schema = "analytics", Item = "vw_competition_eligible"]}[Data],
    Kept     = Table.SelectColumns(Raw, {"ocid", "tender_id", "buyer_id", "procurement_method_details", "tender_status",
                                         "number_of_tenderers", "tenderer_count_flag", "in_primary_population", "is_single_bidder"}),
    Renamed  = Table.RenameColumns(Kept, {{"procurement_method_details", "procurement_method"}}),
    Labelled = Table.ReplaceValue(Renamed, null, "(method not stated)", Replacer.ReplaceValue, {"procurement_method"}),
    Typed    = Table.TransformColumnTypes(Labelled, {{"number_of_tenderers", Int64.Type},
                                                     {"in_primary_population", type logical}, {"is_single_bidder", type logical}})
in
    Typed
```

After loading, check each table's row count against §4.1. Then switch off **File → Options → Current file → Data load →
Time intelligence (auto date/time)**, so Power BI does not add hidden date tables.

### 4.3 Relationships (star schema)

Create these in Model view. All are **single direction** (dimension filters fact), **many-to-one**, active.

| From (many) | To (one) | Columns |
|---|---|---|
| `Budget`, `Competition`, `Awards`, `Suppliers`, `BudgetVsAward`, `TenderDuration`, `AwardLag`, `SignatureLag`, `Lifecycle`, `Contracts` | `DimBuyer` | `buyer_id` → `buyer_id` |
| `Competition`, `Awards`, `Suppliers`, `BudgetVsAward`, `TenderDuration`, `AwardLag` | `DimMethod` | `procurement_method` → `procurement_method` |
| `EntityBenchmark` | `DimBuyer` | `buyer_id` → `buyer_id`; **one-to-one**, single direction |

```
                       DimMethod                         DimBuyer
                   (procurement_method)                 (buyer_id)
                  /    |     |    |    \  \          /  |   |   |  ...
         Competition Awards Suppliers BudgetVsAward ...        Budget  Lifecycle  Contracts
         TenderDuration AwardLag   (method-bearing facts)      SignatureLag  EntityBenchmark (1:1)
```

**Tables that must NOT be related to each other** (different grains or different eligible subsets; a relationship
would double-count or silently narrow a population):
- `Awards`, `Suppliers`, `BudgetVsAward`: `Suppliers` is award × supplier and `BudgetVsAward` is a subset of `Awards`.
  They share an `award_id` but are compared through *measures* (§5.3), never joined.
- `Competition`, `TenderDuration`, `AwardLag`, `SignatureLag`, `Lifecycle`: all are OCID-level but each holds a
  different eligible subset.
- `Budget` (budget line) with anything but `DimBuyer`.
- `MetricPopulation`, `DQImpact`, `Stage`, `Top N` and the minimum-n tables: stand-alone, no relationships.

**Behaviour to expect.**
- Fact rows whose buyer is the bare `NG-BPP-` ID (98 rows across the views, DQ-19) have no `DimBuyer` row. They count in
  every total and appear as **(Blank)** when a visual is split by buyer. Selecting a buyer in a slicer excludes them.
  This matches SQL, where process-level metrics keep them and entity-level views drop them.
- `DimMethod` does not filter `Budget`, `SignatureLag`, `Lifecycle`, `Contracts` or `EntityBenchmark`, because those views
  carry no method. Scope the method slicer to the pages whose facts have one (§7).
- Four buyer names are shared by two different IDs (they are deliberately not merged). Always slice on `buyer_label` /
  `buyer_id`, never on `buyer_name`.

### 4.4 Helper tables and calculated columns

Create these in the model (Modeling → New table / New column). They hold labels and presentation bins only.

**Parameter tables** (the analyst parameters confirmed on 2026-10-08). Each `GENERATESERIES` table has one column named `Value`:

```
Top N = GENERATESERIES(1, 100, 1)
Min Competition n = GENERATESERIES(1, 200, 1)
Min Award n = GENERATESERIES(1, 200, 1)
Min Contract n = GENERATESERIES(1, 200, 1)
Min Process n = GENERATESERIES(1, 200, 1)
```

Add a single-select slicer for each, hidden from pages that do not use it. The defaults live in the measures (§5.1).

**Stage labels** for the lifecycle funnel (labels only; the stage rank itself comes from `Lifecycle`):

```
Stage = DATATABLE("Stage Rank", INTEGER, "Stage", STRING,
            {{1, "Planning"}, {2, "Tender"}, {3, "Award"}, {4, "Contract"}, {5, "Implementation"}})
```

Set `Stage[Stage]` to *Sort by column* `Stage[Stage Rank]`.

**Measure table.** Create an empty table `_Measures` (Home → Enter data, one blank column) and put every measure from §5 in it.

**Calculated columns** (presentation bins; the thresholds duplicate the SQL cut-offs on purpose and are reconciled by figure
IDs COM-B, BVA-B, TIM-D and IMP-T):

```
-- Competition
Participation Band =
SWITCH(TRUE(),
    Competition[number_of_tenderers] = 1,   "1 tenderer",
    Competition[number_of_tenderers] = 2,   "2 tenderers",
    Competition[number_of_tenderers] <= 5,  "3-5 tenderers",
    Competition[number_of_tenderers] <= 10, "6-10 tenderers",
    Competition[number_of_tenderers] <= 20, "11-20 tenderers",
    Competition[number_of_tenderers] <= 50, "21-50 tenderers",
    Competition[number_of_tenderers] <= 100,"51-100 tenderers",
    "101-1,000 (sensitivity only)")

Participation Band Order =
SWITCH(TRUE(),
    Competition[number_of_tenderers] = 1, 1, Competition[number_of_tenderers] = 2, 2,
    Competition[number_of_tenderers] <= 5, 3, Competition[number_of_tenderers] <= 10, 4,
    Competition[number_of_tenderers] <= 20, 5, Competition[number_of_tenderers] <= 50, 6,
    Competition[number_of_tenderers] <= 100, 7, 8)

-- BudgetVsAward
Ratio Band =
SWITCH(TRUE(),
    BudgetVsAward[award_to_budget_ratio] < 0.5,  "Below 0.5",
    BudgetVsAward[award_to_budget_ratio] < 0.9,  "0.5 to under 0.9",
    BudgetVsAward[award_to_budget_ratio] <= 1.1, "0.9 to 1.1",
    BudgetVsAward[award_to_budget_ratio] <= 1.5, "Over 1.1 to 1.5",
    BudgetVsAward[award_to_budget_ratio] <= 10,  "Over 1.5 to 10",
    "Over 10")

Ratio Band Order =
SWITCH(TRUE(),
    BudgetVsAward[award_to_budget_ratio] < 0.5, 1, BudgetVsAward[award_to_budget_ratio] < 0.9, 2,
    BudgetVsAward[award_to_budget_ratio] <= 1.1, 3, BudgetVsAward[award_to_budget_ratio] <= 1.5, 4,
    BudgetVsAward[award_to_budget_ratio] <= 10, 5, 6)

-- TenderDuration, AwardLag, SignatureLag (same pattern; replace the column name)
Duration Band =
SWITCH(TRUE(),
    TenderDuration[tender_duration_days] <= 7,   "Up to 7 days",
    TenderDuration[tender_duration_days] <= 30,  "8-30 days",
    TenderDuration[tender_duration_days] <= 90,  "31-90 days",
    TenderDuration[tender_duration_days] <= 180, "91-180 days",
    TenderDuration[tender_duration_days] <= 365, "181-365 days",
    "Over 1 year")
Duration Band Order =
SWITCH(TRUE(),
    TenderDuration[tender_duration_days] <= 7, 1, TenderDuration[tender_duration_days] <= 30, 2,
    TenderDuration[tender_duration_days] <= 90, 3, TenderDuration[tender_duration_days] <= 180, 4,
    TenderDuration[tender_duration_days] <= 365, 5, 6)

-- Years for time slicing (valid dates only; the timing views contain VALID dates by construction)
TenderDuration[Tender Start Year] = YEAR(TenderDuration[tender_start_date])
AwardLag[Award Year]              = YEAR(AwardLag[award_date])
SignatureLag[Signed Year]         = YEAR(SignatureLag[date_signed])
Awards[Award Year]                = IF(Awards[award_date_flag] = "VALID", YEAR(Awards[award_date]))

-- Contracts
Implementation Data Type =
SWITCH(TRUE(),
    Contracts[transaction_count] > 0 && Contracts[implementation_milestone_count] > 0, "Transactions and milestones",
    Contracts[implementation_milestone_count] > 0, "Milestones only",
    Contracts[transaction_count] > 0, "Transactions only",
    "No implementation data")
Implementation Data Type Order =
SWITCH(TRUE(),
    Contracts[transaction_count] > 0 && Contracts[implementation_milestone_count] > 0, 1,
    Contracts[implementation_milestone_count] > 0, 2, Contracts[transaction_count] > 0, 3, 4)
```

Set each `... Band` / `Implementation Data Type` column to *Sort by column* its `... Order` column.

---

## 5. DAX measures

Names are exact: the reconciliation pack refers to them. Each block states the SQL definition it reproduces. Set
display formats: NGN measures `#,0` (or billions via a display unit), counts `#,0`, shares `0.00%`, ratios `0.0000`, days `0.0`.

### 5.1 Parameters (the confirmed analyst choices)

```
Top N Selected          = SELECTEDVALUE('Top N'[Value], 10)
Min Competition n       = SELECTEDVALUE('Min Competition n'[Value], 30)
Min Award n             = SELECTEDVALUE('Min Award n'[Value], 10)
Min Contract n          = SELECTEDVALUE('Min Contract n'[Value], 20)
Min Process n           = SELECTEDVALUE('Min Process n'[Value], 30)
```

(The single column of a `GENERATESERIES` table is named `Value`.) These equal the constants in `sql/06_analysis`
(10 awards, 30 tenders, 20 contracts, 30 processes). Changing a default here changes only the dashboard.

### 5.2 Executive and lifecycle

```
Processes (n)         = COUNTROWS(Lifecycle)                                         -- M-E03 population
Planning-Only Share   = DIVIDE(CALCULATE(COUNTROWS(Lifecycle), Lifecycle[highest_stage_rank] = 1), [Processes (n)])
OCIDs Reaching Stage  =
    VAR k = SELECTEDVALUE(Stage[Stage Rank])
    RETURN CALCULATE(COUNTROWS(Lifecycle), Lifecycle[highest_stage_rank] >= k)
Stage Conversion Rate =
    VAR k = SELECTEDVALUE(Stage[Stage Rank])
    RETURN IF(k > 1, DIVIDE([OCIDs Reaching Stage],
                            CALCULATE(COUNTROWS(Lifecycle), Lifecycle[highest_stage_rank] >= k - 1)))
```

SQL: `analytics.vw_lifecycle_stage` (M-E03). `[OCIDs Reaching Stage]` is the funnel; `Stage Conversion Rate` is blank for stage 1.
Eligible n = `[Processes (n)]`.

### 5.3 Budget (M-P01), awards (M-V01), suppliers (M-S01), budget-to-award

```
-- M-P01
Planned Budget (NGN)       = SUM(Budget[budget_amount])
Budget Lines (n)           = COUNTROWS(Budget)                                       -- eligible n

-- M-V01
Award Value (NGN)          = SUM(Awards[award_value_amount])
Median Award Value (NGN)   = MEDIAN(Awards[award_value_amount])
Eligible Awards (n)        = COUNTROWS(Awards)                                       -- eligible n

-- M-S01 (every award x distinct supplier; full award value to its single supplier)
M-S01 Eligible Awards      = DISTINCTCOUNT(Suppliers[award_id])                      -- eligible n
Suppliers (n)              = DISTINCTCOUNT(Suppliers[supplier_id])
Supplier Value (NGN)       = SUM(Suppliers[award_value_amount])
Top N Supplier Value (NGN) =
    VAR TopSuppliers = TOPN([Top N Selected], VALUES(Suppliers[supplier_id]), [Supplier Value (NGN)], DESC)
    RETURN SUMX(TopSuppliers, [Supplier Value (NGN)])
Top N Supplier Share       = DIVIDE([Top N Supplier Value (NGN)], [Supplier Value (NGN)])
Supplier HHI               =
    VAR Total = [Supplier Value (NGN)]
    RETURN SUMX(VALUES(Suppliers[supplier_id]), DIVIDE([Supplier Value (NGN)], Total) ^ 2) * 10000
Suppliers With One Award   =
    COUNTROWS(FILTER(VALUES(Suppliers[supplier_id]), CALCULATE(DISTINCTCOUNT(Suppliers[award_id])) = 1))
Supplier Rank              = RANKX(ALLSELECTED(Suppliers[supplier_id]), [Supplier Value (NGN)], , DESC, Skip)
Supplier Share             = DIVIDE([Supplier Value (NGN)], CALCULATE([Supplier Value (NGN)], ALLSELECTED(Suppliers[supplier_id])))
Cumulative Supplier Share  =
    VAR r = [Supplier Rank]
    VAR Total = CALCULATE([Supplier Value (NGN)], ALLSELECTED(Suppliers[supplier_id]))
    RETURN DIVIDE(SUMX(TOPN(r, ALLSELECTED(Suppliers[supplier_id]), [Supplier Value (NGN)], DESC), [Supplier Value (NGN)]), Total)

-- M-S01 disclosure (read from the data, never typed in)
M-S01 Excluded Awards      = [Eligible Awards (n)] - [M-S01 Eligible Awards]
M-S01 Excluded Value (NGN) = [Award Value (NGN)] - [Supplier Value (NGN)]
M-S01 Excluded Value Share = DIVIDE([M-S01 Excluded Value (NGN)], [Award Value (NGN)])
M-S01 Excluded Awards (DQ view) =
    CALCULATE(SUM(DQImpact[records_with_issue]), DQImpact[metric_id] = "M-S01", DQImpact[dq_ref] = "DQ-14")
M-S01 Excluded Value (DQ view)  =
    CALCULATE(SUM(DQImpact[affected_value_ngn]), DQImpact[metric_id] = "M-S01", DQImpact[dq_ref] = "DQ-14")
M-S01 Disclosure =
    "Lower bound: " & FORMAT([M-S01 Excluded Awards], "#,##0") & " of " & FORMAT([Eligible Awards (n)], "#,##0")
    & " eligible awards (NGN " & FORMAT([M-S01 Excluded Value (NGN)] / 1000000000, "#,##0.0") & "bn, "
    & FORMAT([M-S01 Excluded Value Share], "0.0%") & " of eligible award value) have no usable supplier ID and are left out. "
    & "Suppliers are identified by source ID and are not merged, so true concentration may be higher."

-- Budget-to-award (OCIDs with an eligible award and exactly one valid budget line)
Comparable OCIDs                 = COUNTROWS(BudgetVsAward)                          -- eligible n
Budget of Comparable OCIDs (NGN) = SUM(BudgetVsAward[budget_amount])
Award of Comparable OCIDs (NGN)  = SUM(BudgetVsAward[award_value_amount])
Net Variance (NGN)               = SUM(BudgetVsAward[variance_amount])               -- award minus budget
Aggregate Award-to-Budget Ratio  = DIVIDE([Award of Comparable OCIDs (NGN)], [Budget of Comparable OCIDs (NGN)])
Median Award-to-Budget Ratio     = MEDIAN(BudgetVsAward[award_to_budget_ratio])
Share Within 10% of Budget       =
    DIVIDE(CALCULATE(COUNTROWS(BudgetVsAward), BudgetVsAward[award_to_budget_ratio] >= 0.9,
                     BudgetVsAward[award_to_budget_ratio] <= 1.1), [Comparable OCIDs])
OCIDs With Budget Under 100k     = CALCULATE(COUNTROWS(BudgetVsAward), BudgetVsAward[budget_amount] < 100000)
```

Notes:
- `M-S01 Excluded Awards` equals candidate minus eligible because the M-S01 view is built from the M-V01 view (the identity is
  asserted in SQL: checks AV-05 to AV-07). It responds to buyer and method slicers; the `(DQ view)` pair does not (it is the
  whole-dataset figure from `vw_dq_impact`) and is shown on page 7 as a cross-check.
- `TOPN` returns every row tied at the cut-off. Supplier values are not tied at ranks 1, 5, 10, 20 and 100 (the reconciled
  cut-offs). Other values of N can show a marginally larger share if a tie falls on the boundary.
- `Supplier Rank` and `Cumulative Supplier Share` are for the top-20 table (visual-level filter *Top N* by `[Supplier Value (NGN)]`
  = 20). Do not use them in a visual that lists all 9,800 suppliers.
- `Net Variance` is award minus budget. A negative number means awards were below budget in total; it is not a saving.

### 5.4 Competition (M-C01, M-C02), timing, implementation, entities

```
-- Competition: primary population = 1-100 tenderers (flag NORMAL); sensitivity adds 101-1,000
Competition n (primary)          = CALCULATE(COUNTROWS(Competition), Competition[in_primary_population] = TRUE())
Competition n (sensitivity)      = COUNTROWS(Competition)
Tenders (n)                      = COUNTROWS(Competition)
Median Tenderers (primary)       = CALCULATE(MEDIAN(Competition[number_of_tenderers]), Competition[in_primary_population] = TRUE())
Median Tenderers (sensitivity)   = MEDIAN(Competition[number_of_tenderers])
Single-Bidder Rate (primary)     =
    DIVIDE(CALCULATE(COUNTROWS(Competition), Competition[in_primary_population] = TRUE(), Competition[is_single_bidder] = TRUE()),
           [Competition n (primary)])
Single-Bidder Rate (sensitivity) =
    DIVIDE(CALCULATE(COUNTROWS(Competition), Competition[is_single_bidder] = TRUE()), [Competition n (sensitivity)])

-- Timing: eligible = both dates valid and later date not before earlier date (decided in SQL)
Tender Duration n          = COUNTROWS(TenderDuration)
Award Lag n                = COUNTROWS(AwardLag)
Signature Lag n            = COUNTROWS(SignatureLag)
Median Tender Duration (days) = MEDIAN(TenderDuration[tender_duration_days])
Median Award Lag (days)       = MEDIAN(AwardLag[award_lag_days])
Median Signature Lag (days)   = MEDIAN(SignatureLag[signature_lag_days])
P90 Tender Duration (days)    = PERCENTILE.INC(TenderDuration[tender_duration_days], 0.9)
P90 Award Lag (days)          = PERCENTILE.INC(AwardLag[award_lag_days], 0.9)
P90 Signature Lag (days)      = PERCENTILE.INC(SignatureLag[signature_lag_days], 0.9)
Award Lag Over 1 Year Share   = DIVIDE(CALCULATE(COUNTROWS(AwardLag), AwardLag[award_lag_days] > 365), [Award Lag n])
Coverage M-E01 =
    DIVIDE(CALCULATE(MAX(MetricPopulation[eligible_count]),  MetricPopulation[metric_id] = "M-E01"),
           CALCULATE(MAX(MetricPopulation[candidate_count]), MetricPopulation[metric_id] = "M-E01"))
Coverage M-E02 =
    DIVIDE(CALCULATE(MAX(MetricPopulation[eligible_count]),  MetricPopulation[metric_id] = "M-E02"),
           CALCULATE(MAX(MetricPopulation[candidate_count]), MetricPopulation[metric_id] = "M-E02"))
Coverage Signature Lag =
    DIVIDE(CALCULATE(MAX(MetricPopulation[eligible_count]),  MetricPopulation[metric_id] = "P5-SIG"),
           CALCULATE(MAX(MetricPopulation[candidate_count]), MetricPopulation[metric_id] = "P5-SIG"))
Timing Caveat =
    "Valid dates exist for " & FORMAT([Coverage M-E01], "0%") & " of tenders (tender duration), "
    & FORMAT([Coverage M-E02], "0%") & " of processes (award lag) and " & FORMAT([Coverage Signature Lag], "0%")
    & " of contracts (signature lag). Missing dates are reporting gaps, not delays. Results describe only the processes that published valid dates."

-- Implementation coverage (M-I01): reporting coverage, not performance
Contracts (n)                       = COUNTROWS(Contracts)                           -- eligible n
Contracts With Implementation Data  = CALCULATE(COUNTROWS(Contracts), Contracts[has_implementation] = TRUE())
Implementation Coverage Rate        = DIVIDE([Contracts With Implementation Data], [Contracts (n)])

-- Entity benchmark (665 complete buyer IDs; KPIs are precomputed per entity in SQL)
Entities (n)                  = COUNTROWS(EntityBenchmark)
Entity Processes              = SUM(EntityBenchmark[process_count])
Entity Planned Budget (NGN)   = SUM(EntityBenchmark[planned_budget_total])
Entity Award Value (NGN)      = SUM(EntityBenchmark[award_value_total])
Entity Awards (n)             = SUM(EntityBenchmark[award_n])
Entity Competition n          = SUM(EntityBenchmark[competition_n])
Entity Contracts (n)          = SUM(EntityBenchmark[contract_n])
Top N Entity Share            =
    VAR TopEntities = TOPN([Top N Selected], VALUES(DimBuyer[buyer_id]), [Entity Award Value (NGN)], DESC)
    RETURN DIVIDE(SUMX(TopEntities, [Entity Award Value (NGN)]), [Entity Award Value (NGN)])

-- One-entity KPIs: show a value only when exactly one entity is in context (table rows, a buyer slicer)
Entity Single-Bidder Rate      = IF(HASONEVALUE(DimBuyer[buyer_id]), MAX(EntityBenchmark[single_bidder_rate]))
Entity Median Tenderers        = IF(HASONEVALUE(DimBuyer[buyer_id]), MAX(EntityBenchmark[median_tenderers]))
Entity Top-Supplier Share      = IF(HASONEVALUE(DimBuyer[buyer_id]), MAX(EntityBenchmark[top_supplier_value_share]))
Entity Implementation Coverage = IF(HASONEVALUE(DimBuyer[buyer_id]), MAX(EntityBenchmark[implementation_coverage_rate]))
Entity Tender Reach Rate       = IF(HASONEVALUE(DimBuyer[buyer_id]), MAX(EntityBenchmark[tender_reach_rate]))
Entity Median Award Value (NGN)= IF(HASONEVALUE(DimBuyer[buyer_id]), MAX(EntityBenchmark[median_award_value]))

-- The same KPIs, blank when the entity is below the confirmed minimum n (use these in ranked tables)
Entity Single-Bidder Rate (min n)      = IF([Entity Competition n] >= [Min Competition n], [Entity Single-Bidder Rate])
Entity Top-Supplier Share (min n)      = IF([Entity Awards (n)] >= [Min Award n], [Entity Top-Supplier Share])
Entity Implementation Coverage (min n) = IF([Entity Contracts (n)] >= [Min Contract n], [Entity Implementation Coverage])
Entity Tender Reach Rate (min n)       = IF([Entity Processes] >= [Min Process n], [Entity Tender Reach Rate])

-- Spread of entity KPIs across entities that meet the minimum n (the yardstick for the table)
Median Entity Single-Bidder Rate =
    MEDIANX(FILTER(EntityBenchmark, EntityBenchmark[competition_n] >= [Min Competition n]), EntityBenchmark[single_bidder_rate])
Median Entity Top-Supplier Share =
    MEDIANX(FILTER(EntityBenchmark, EntityBenchmark[award_n] >= [Min Award n]), EntityBenchmark[top_supplier_value_share])
Median Entity Implementation Coverage =
    MEDIANX(FILTER(EntityBenchmark, EntityBenchmark[contract_n] >= [Min Contract n]), EntityBenchmark[implementation_coverage_rate])
```

Notes:
- A blank entity KPI means "no eligible records or below minimum n", never zero (matches `vw_entity_benchmark`).
- Do not average, sum or re-aggregate the entity rates and medians: they are precomputed per entity. The overall single-bidder
  rate and medians come from the fact tables (`Competition`, `Awards`, ...), not from `EntityBenchmark`.
- Entity ranks: `RANKX(ALLSELECTED(DimBuyer[buyer_id]), [Entity Award Value (NGN)], , DESC, Skip)` in a table visual.

### 5.5 Data-quality page

```
Candidate Records   = SUM(MetricPopulation[candidate_count])
Eligible Records    = SUM(MetricPopulation[eligible_count])
Eligible Share      = DIVIDE([Eligible Records], [Candidate Records])
Issue Records       = SUM(DQImpact[records_with_issue])
Lost To This Issue Only = SUM(DQImpact[records_lost_only_to_issue])
Issue Value (NGN)   = SUM(DQImpact[affected_value_ngn])
Issue % of Candidates = AVERAGE(DQImpact[pct_of_candidate]) / 100
```

Use these in a table/matrix where a single `metric_id` and `dq_ref` is in context. `Issue Records` overlap across issues and must not
be summed down a column (the counts are not additive; `Lost To This Issue Only` is). The materiality rating (high / moderate / low)
is a SQL-script output (`sql/06_analysis/07_data_quality_impact.sql`), not recomputed in DAX.

### 5.6 Documented duplicates of SQL constants

| In DAX | Same constant in SQL | Guard |
|---|---|---|
| Minimum n: 10 awards, 30 tenders, 20 contracts, 30 processes | `sql/06_analysis/05_entity_benchmarking.sql` RS0 | ENT-08 to ENT-10 |
| Band cut-offs (participation, ratio, duration, implementation type) | `sql/06_analysis/02, 03, 04, 06` | COM-B, BVA-B, TIM-D, IMP-T |
| Top N values 1, 5, 10, 20, 100 | `sql/06_analysis/01`, `05` | SUP-04 to SUP-08, ENT-05 to ENT-07 |

---

## 6. Measure catalogue and reconciliation map

Every measure maps to a SQL source/metric and to the figure ID(s) in `reconciliation_expected_values.sql`. "n" measures are the
eligible n shown next to the figure.

| Measure | SQL source / metric | Figure IDs |
|---|---|---|
| `[Processes (n)]` | `vw_lifecycle_stage`, M-E03 | EXE-01 |
| `[Planning-Only Share]` | `vw_lifecycle_stage` (DQ-02) | EXE-13 |
| `[OCIDs Reaching Stage]`, `[Stage Conversion Rate]` | `vw_lifecycle_stage`, M-E03 | IMP-S1 to IMP-S5, IMP-C2 to IMP-C5 |
| `[Planned Budget (NGN)]`, `[Budget Lines (n)]` | `vw_budget_eligible`, M-P01 | EXE-02 |
| `[Award Value (NGN)]`, `[Median Award Value (NGN)]`, `[Eligible Awards (n)]` | `vw_award_value_eligible`, M-V01 | EXE-03, EXE-04 |
| `[M-S01 Eligible Awards]`, `[Suppliers (n)]`, `[Supplier Value (NGN)]` | `vw_supplier_award_eligible`, M-S01 | SUP-01, SUP-02, SUP-03 |
| `[Top N Supplier Share]` (N = 1, 5, 10, 20, 100; and by method) | M-S01 | SUP-04 to SUP-08, SUP-16, SUP-17, EXE-07 |
| `[Supplier HHI]` | M-S01 | SUP-09, SUP-18 |
| `[Suppliers With One Award]` | M-S01 | SUP-10 |
| `[M-S01 Excluded Awards]`, `[... Value (NGN)]`, `[... Value Share]` | M-V01 minus M-S01 (disclosure) | SUP-11, SUP-12, SUP-13, EXE-08 |
| `[M-S01 Excluded Awards (DQ view)]`, `[... Value (DQ view)]` | `vw_dq_impact` (M-S01, DQ-14) | SUP-14, SUP-15 |
| `[Competition n (primary)]`, `[Competition n (sensitivity)]` | `vw_competition_eligible` | COM-01, COM-02 |
| `[Median Tenderers (primary)]`, `[... (sensitivity)]` | M-C01 | COM-03, COM-04, COM-10, EXE-06 |
| `[Single-Bidder Rate (primary)]`, `[... (sensitivity)]` | M-C02 | COM-05 to COM-09, EXE-05 |
| `[Tenders (n)]` by `[Participation Band]` | `vw_competition_eligible` | COM-B1 to COM-B8 |
| `[Comparable OCIDs]` and the budget / award / variance sums | `vw_budget_award_comparison` | BVA-01 to BVA-04 |
| `[Aggregate Award-to-Budget Ratio]`, `[Median Award-to-Budget Ratio]` | `vw_budget_award_comparison` | BVA-05, BVA-06, BVA-08, BVA-09, EXE-09 |
| `[Share Within 10% of Budget]`, `[OCIDs With Budget Under 100k]` | `vw_budget_award_comparison` | BVA-07, BVA-11 |
| `[Net Variance (NGN)]` by entity | `vw_budget_award_comparison` | BVA-10 |
| `[Comparable OCIDs]` by `[Ratio Band]` | `vw_budget_award_comparison` | BVA-B1 to BVA-B6 |
| `[Tender Duration n]`, `[Award Lag n]`, `[Signature Lag n]` | timing views, M-E01 / M-E02 / signature lag | TIM-01 to TIM-03 |
| `[Median ... (days)]` (3) and `[P90 ... (days)]` (3) | timing views | TIM-04 to TIM-09, TIM-14 to TIM-17, EXE-10, EXE-11 |
| `[Coverage M-E01]`, `[Coverage M-E02]`, `[Coverage Signature Lag]` | `vw_metric_population` | TIM-10 to TIM-12 |
| `[Award Lag Over 1 Year Share]` | `vw_award_lag_eligible` | TIM-13 |
| duration measures by `[Duration Band]` | timing views | TIM-D1-1 to TIM-D3-6 |
| `[Entities (n)]`, `[Entity Processes]`, `[Entity Planned Budget (NGN)]`, `[Entity Award Value (NGN)]` | `vw_entity_benchmark` | ENT-01 to ENT-04 |
| `[Top N Entity Share]` | `vw_entity_benchmark` | ENT-05 to ENT-07 |
| `[Median Entity ...]` (3) | `vw_entity_benchmark` | ENT-08 to ENT-10 |
| `[Entity ...]` one-entity KPIs | `vw_entity_benchmark` | ENT-11 to ENT-15 |
| `[Contracts (n)]`, `[Contracts With Implementation Data]`, `[Implementation Coverage Rate]` | `vw_contract_implementation_coverage`, M-I01 | IMP-01 to IMP-05, EXE-12 |
| `[Contracts (n)]` by `[Implementation Data Type]` | `vw_contract_implementation_coverage` | IMP-T1 to IMP-T4 |
| `[Candidate Records]`, `[Eligible Records]`, `[Eligible Share]` | `vw_metric_population` | DQ-C-*, DQ-E-*, DQ-P-* |
| `[Issue Records]`, `[Issue Value (NGN)]` | `vw_dq_impact` | DQ-X1 to DQ-X7 |

---

## 7. Report layout

Seven pages, one theme (two neutral colours plus grey; no red/green "good/bad" colouring). Put the page caveat in a text box at
the foot of the page, using the exact wording in §8. Every card has its eligible n as a subtitle or tooltip.

### 7.1 Pages

| # | Page | Business question | Slicers | Visuals |
|---|---|---|---|---|
| 1 | **Executive overview** | What does the published record show, and how complete is it? | none (a *Buyer* slicer is allowed but clear it before reconciling) | Cards: processes, planned budget, awarded value, median award value, share of tenders with one bidder, median tenderers, top-10 supplier share, median award-to-budget ratio, median tender duration, median award lag, implementation reporting coverage, planning-only share (each with its n). Bar chart: `Eligible Share` by metric (from `MetricPopulation`). Text box: `[M-S01 Disclosure]` |
| 2 | **Supplier concentration and competition** | Q1: How concentrated is awarded value among suppliers? Q2: How competitive are processes, and where is competition unusually low or high? | Buyer (`buyer_label`), Procurement method, *Top N* | Left (suppliers): cards for `[M-S01 Eligible Awards]`, `[Suppliers (n)]`, `[Top N Supplier Share]`, `[Supplier HHI]`; table of the top 20 suppliers (rank, supplier name, awards, value, share, cumulative share, name-variant note from `name_variant_count > 1`); bar of `[Top N Supplier Share]` with N = 1 by `DimMethod[procurement_method]`; text box `[M-S01 Disclosure]`. Right (competition): cards `[Median Tenderers (primary)]`, `[Single-Bidder Rate (primary)]`, `[Competition n (primary)]`; column chart `[Tenders (n)]` by `[Participation Band]`; bar of `[Single-Bidder Rate (primary)]` by method with `[Competition n (primary)]` labels; table of entities by single-bidder rate (`[Entity Single-Bidder Rate (min n)]`, highest and lowest 10) |
| 3 | **Budget versus award** | Q3: How does awarded value compare with recorded budgets, and which entities or methods differ most? | Buyer, Procurement method | Cards: `[Comparable OCIDs]`, `[Aggregate Award-to-Budget Ratio]`, `[Median Award-to-Budget Ratio]`, `[Share Within 10% of Budget]`, `[OCIDs With Budget Under 100k]`; column chart `[Comparable OCIDs]` by `[Ratio Band]`; table by method (n, budget, award, aggregate ratio, median ratio); table of the 15 entities with the largest absolute `[Net Variance (NGN)]` (visual filter: `[Comparable OCIDs]` ≥ 10) |
| 4 | **Procurement-cycle timing** | Q4: What do valid dates say about cycle duration, and where are dates too incomplete to measure? | Procurement method, Buyer, year (`Tender Start Year` / `Award Year`) | Three cards (median days, with n and coverage %); `[Timing Caveat]` text box; column charts of the three durations by `[Duration Band]`; line chart of `[Median Tender Duration (days)]` by `Tender Start Year` and of `[Median Award Lag (days)]` by `Award Year`, with the n of each year as a second series; table by method (n and median for tender duration and award lag; a "small n" label where n < 30) |
| 5 | **Entity benchmark** | Q5: Which entities account for the most activity, and how do they compare on the KPIs? | Buyer, *Top N*, minimum-n tables | Cards: `[Entities (n)]`, `[Top N Entity Share]`; bar of the top 15 entities by `[Entity Award Value (NGN)]` (with `[Entity Processes]`); table (entity, processes, planned budget, award value, tender reach, median tenderers, single-bidder rate, top-supplier share, implementation coverage, each KPI with its n and shown only if it meets the minimum n); three cards with `[Median Entity ...]` as the yardstick |
| 6 | **Implementation and lifecycle** | Q6: What share of contracts has usable implementation data, and what does reporting completeness show? | Buyer, contract status | Cards: `[Contracts (n)]`, `[Contracts With Implementation Data]`, `[Implementation Coverage Rate]`; stacked bar `[Contracts (n)]` by `[Implementation Data Type]`; bar of `[Implementation Coverage Rate]` by `contract_status`; funnel `[OCIDs Reaching Stage]` by `Stage[Stage]` with `[Stage Conversion Rate]` labels; table of the 15 entities with the lowest `[Entity Implementation Coverage (min n)]` |
| 7 | **Data quality and coverage** | Q7: Which data-quality issues could materially affect interpretation? | Metric (`DQImpact[metric_id]`), impact type | Table from `MetricPopulation` (metric, candidate, eligible, `[Eligible Share]`); matrix `DQImpact`: rows `dq_ref` + `dq_issue`, columns `metric_id`, values `[Issue Records]` and `[Issue % of Candidates]`, slicer on `impact_type`; table of `DQ-14` and `DQ-06` value effects (`[Issue Value (NGN)]`); the cross-check cards `[M-S01 Excluded Awards]` vs `[M-S01 Excluded Awards (DQ view)]` |

Slicer scope (Format → Edit interactions): *Procurement method* filters pages 2 to 4 only; *Buyer* filters every page; the *Top N* and
minimum-n slicers sit only on the pages that use them.

### 7.2 Titles and labels

Use these neutral titles (plain description of what is counted):

- "Share of tenders with a single bidder" (not "bid-rigging risk").
- "Awarded value as a multiple of planned budget" (not "overspend").
- "Share of awarded value held by the largest suppliers" (not "dominance").
- "Contracts with implementation data published" (not "contracts delivered").
- "Processes published only at planning stage".
- "Records excluded from the metric" (not "bad data").

### 7.3 Words not to use

No title, label, tooltip, alt text or caption may contain or imply: *fraud, corrupt/corruption, collusion, bid rigging,
kickback, embezzle, misconduct, irregularity, suspicious, red flag, overpriced, inflated, overrun, loss, saving, wasteful,
underperforming, non-performing, failed contractor*. Use: *observed pattern, unusual value, reporting gap, concentration, difference
between recorded figures, requires further validation*. Do not use red/green traffic-light colours on entities.

---

## 8. Mandatory caveat text (use these exact sentences)

| Where | Text |
|---|---|
| Every page, footer | "Figures describe what was published to the Nigeria Open Contracting Portal (source file published 2021-05-03). They show patterns in reported data, not findings about conduct." |
| Pages 1 and 2, supplier visuals | `[M-S01 Disclosure]` (dynamic). Also: "Supplier concentration is a lower bound. Suppliers are identified by source ID and are not merged on name similarity." |
| Page 2, competition | "Number of tenderers as recorded; the meaning (bids received or expressions of interest) is unconfirmed. A single bidder is a count pattern, not evidence of impropriety. Direct Procurement, Sole Source and Repeat Procurement are single-supplier by design, so compare like with like." |
| Page 3 | "A budget is a plan, not a contract estimate or spend. A ratio above or below 1 is a difference between two recorded figures, not an overrun or a saving. Budgets under NGN 100,000 look like placeholder entries and are kept; extreme ratios come from them." |
| Page 3, band "Over 10" | "Awards above 10 times budget are a small group of OCIDs that hold a large share of the award value (see the band chart for the counts). Pattern only; cause not established; units and budget entry should be checked against the source." *(Do not type counts or shares into text boxes; they come from the measures.)* |
| Page 4 | `[Timing Caveat]` (dynamic). Also: "Medians describe only processes with valid dates and are not estimates for all procurement." |
| Page 5 | "Entities differ in size and method mix. Ranks and medians show relative position, not a target. A KPI is shown only where the entity meets the minimum number of records (10 awards, 30 tenders, 20 contracts, 30 processes). Entities are identified by buyer ID and are not merged." |
| Page 6 | "Implementation coverage shows whether implementation data (milestones or transactions) was published. It is a reporting signal, not a measure of contract performance. Transaction dates are absent and transaction values are not analysed (DQ-11, DQ-12)." |
| Page 6, funnel | "Most processes were published only at planning stage; conversion reflects what the portal holds, not how procurement progressed." |
| Page 7 | "The portal test entity (DQ-20) is removed before every population is defined, and the bare buyer ID (DQ-19) is excluded from entity views. Issue counts overlap; they are not additive. Materiality ratings are in sql/06_analysis/07." |

---

## 9. Reconciliation (Phase 9 exit gate)

Gate: **every figure shown on the dashboard reconciles with its source SQL view/query.**

1. Run `reconciliation_expected_values.sql` (about 10 s, read-only; it also works as `nocopo_bi`):

   ```bash
   psql -h localhost -p 5433 -U postgres -d nocopo_db -f dashboard/reconciliation_expected_values.sql
   ```

2. Generate the log with the SQL values filled in (it refuses to overwrite a log that may hold sign-offs):

   ```bash
   .venv/Scripts/python python/validation/06_generate_reconciliation_log.py
   ```

3. Open `reconciliation_log.md`. For each figure ID, clear all slicers, set only the filter in the *Slice* column, read the dashboard
   value, and enter it, the match, and your initials and date. The *DAX measure* column names the measure to check.
4. Tolerances: counts, days and bands exact; NGN to the whole naira; ratios and shares to the displayed precision.
5. The gate is passed when every row reads `yes`. A `NO` is a model or measure defect: fix it, refresh, re-check.

The pack covers 177 figures (at the time of writing): executive cards (EXE), supplier concentration (SUP), competition (COM), budget versus award (BVA),
timing (TIM), entity benchmark (ENT), implementation and lifecycle (IMP), and the register (DQ).

---

## 10. Known limitations of the data layer

- **No date column** exists in the competition, budget, lifecycle, implementation or entity views, so time-period slicing is
  available only for awards and the three timing metrics (`Award Year`, `Tender Start Year`, `Signed Year`). There is no shared
  date dimension. If a time slicer is wanted on the other pages, add valid date columns to those views in SQL (a later phase),
  not in DAX.
- **Procurement method** is the only category-like field. There is no sector or commodity category in the source.
- **Entity-level medians** are precomputed per entity; there is no way to combine them across entities in DAX.
- **Array column** `tags_observed` in `vw_lifecycle_stage` is dropped in Power Query because the connector may not read it.
- **Not tested in Power BI Desktop** by the author of this guide (see the status note at the top).

---

## 11. Build checklist

1. §2 role created, password set, gate test run.
2. §3 connect as `nocopo_bi`; Import the 15 views; apply §4.2; row counts match §4.1.
3. §4.3 relationships; auto date/time off; §4.4 helper tables and calculated columns.
4. §5 measures into `_Measures`; formats set.
5. §7 pages; §8 caveats; §7.3 wording check.
6. §9 reconciliation log completed with every row `yes`.
7. Save the `.pbix` and screenshots to `dashboard/` and `dashboard/screenshots/` (see the note there). Do not commit credentials.
