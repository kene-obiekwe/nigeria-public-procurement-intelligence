# Power Query scripts for all 15 tables

Companion to `dashboard/README.md` §4.1 and §4.2. Each block below is the complete M script for one table:
it connects, keeps only the needed columns, renames and labels the procurement-method column where there is one, and sets
the data types (monetary columns as Fixed decimal number).

## How to use

1. In Power BI Desktop: **Get data → PostgreSQL database**, server `localhost:5433`, database `nocopo_db`, mode **Import**, user `nocopo_bi`.
2. In the Navigator, tick **all 15** `analytics.*` views and click **Transform Data** (not Load).
3. In the Power Query window, for **each** query in the left pane:
   1. Click it, press **F2** and rename it to the name in the heading below (for example `analytics vw_award_lag_eligible` → `AwardLag`).
   2. **Home → Advanced Editor**, select everything, paste the block for that table, click **Done**.
   3. If a yellow bar asks for permission or credentials, click *Edit Credentials* → *Database* → `nocopo_bi` and the password → *Connect*.
4. When all 15 are done, **Home → Close & Apply**.
5. Check the row counts in the *Data* view against the README §4.1 table (for example `Competition` = 17,266).

The table names must be exactly as below: the DAX measures refer to them.

---

## DimBuyer

```
let
    Source = PostgreSQL.Database("localhost:5433", "nocopo_db"),
    Raw    = Source{[Schema = "analytics", Item = "vw_dim_buyer"]}[Data],
    Kept   = Table.SelectColumns(Raw, {"buyer_id", "buyer_name", "buyer_code", "buyer_label"})
in
    Kept
```

## DimMethod

```
let
    Source = PostgreSQL.Database("localhost:5433", "nocopo_db"),
    Raw    = Source{[Schema = "analytics", Item = "vw_dim_procurement_method"]}[Data],
    Kept   = Table.SelectColumns(Raw, {"procurement_method", "is_not_stated"}),
    Typed  = Table.TransformColumnTypes(Kept, {{"is_not_stated", type logical}})
in
    Typed
```

## Budget

```
let
    Source = PostgreSQL.Database("localhost:5433", "nocopo_db"),
    Raw    = Source{[Schema = "analytics", Item = "vw_budget_eligible"]}[Data],
    Kept   = Table.SelectColumns(Raw, {"ocid", "budget_project_id", "buyer_id", "budget_amount", "budget_currency", "multi_project_flag"}),
    Typed  = Table.TransformColumnTypes(Kept, {{"budget_amount", Currency.Type}})
in
    Typed
```

## Competition

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

## Awards

```
let
    Source   = PostgreSQL.Database("localhost:5433", "nocopo_db"),
    Raw      = Source{[Schema = "analytics", Item = "vw_award_value_eligible"]}[Data],
    Kept     = Table.SelectColumns(Raw, {"ocid", "award_id", "buyer_id", "procurement_method_details", "award_value_amount",
                                         "award_date", "award_date_flag"}),
    Renamed  = Table.RenameColumns(Kept, {{"procurement_method_details", "procurement_method"}}),
    Labelled = Table.ReplaceValue(Renamed, null, "(method not stated)", Replacer.ReplaceValue, {"procurement_method"}),
    Typed    = Table.TransformColumnTypes(Labelled, {{"award_value_amount", Currency.Type}, {"award_date", type date}})
in
    Typed
```

## Suppliers

```
let
    Source   = PostgreSQL.Database("localhost:5433", "nocopo_db"),
    Raw      = Source{[Schema = "analytics", Item = "vw_supplier_award_eligible"]}[Data],
    Kept     = Table.SelectColumns(Raw, {"ocid", "award_id", "buyer_id", "procurement_method_details", "supplier_id", "supplier_name",
                                         "name_variant_count", "award_value_amount"}),
    Renamed  = Table.RenameColumns(Kept, {{"procurement_method_details", "procurement_method"}}),
    Labelled = Table.ReplaceValue(Renamed, null, "(method not stated)", Replacer.ReplaceValue, {"procurement_method"}),
    Typed    = Table.TransformColumnTypes(Labelled, {{"award_value_amount", Currency.Type}, {"name_variant_count", Int64.Type}})
in
    Typed
```

## BudgetVsAward

```
let
    Source   = PostgreSQL.Database("localhost:5433", "nocopo_db"),
    Raw      = Source{[Schema = "analytics", Item = "vw_budget_award_comparison"]}[Data],
    Kept     = Table.SelectColumns(Raw, {"ocid", "award_id", "buyer_id", "procurement_method_details", "budget_project_id",
                                         "budget_amount", "award_value_amount", "variance_amount", "award_to_budget_ratio"}),
    Renamed  = Table.RenameColumns(Kept, {{"procurement_method_details", "procurement_method"}}),
    Labelled = Table.ReplaceValue(Renamed, null, "(method not stated)", Replacer.ReplaceValue, {"procurement_method"}),
    Typed    = Table.TransformColumnTypes(Labelled, {{"budget_amount", Currency.Type}, {"award_value_amount", Currency.Type},
                                                     {"variance_amount", Currency.Type}, {"award_to_budget_ratio", type number}})
in
    Typed
```

## TenderDuration

```
let
    Source   = PostgreSQL.Database("localhost:5433", "nocopo_db"),
    Raw      = Source{[Schema = "analytics", Item = "vw_tender_duration_eligible"]}[Data],
    Kept     = Table.SelectColumns(Raw, {"ocid", "buyer_id", "procurement_method_details", "tender_start_date", "tender_end_date",
                                         "tender_duration_days"}),
    Renamed  = Table.RenameColumns(Kept, {{"procurement_method_details", "procurement_method"}}),
    Labelled = Table.ReplaceValue(Renamed, null, "(method not stated)", Replacer.ReplaceValue, {"procurement_method"}),
    Typed    = Table.TransformColumnTypes(Labelled, {{"tender_start_date", type date}, {"tender_end_date", type date},
                                                     {"tender_duration_days", Int64.Type}})
in
    Typed
```

## AwardLag

```
let
    Source   = PostgreSQL.Database("localhost:5433", "nocopo_db"),
    Raw      = Source{[Schema = "analytics", Item = "vw_award_lag_eligible"]}[Data],
    Kept     = Table.SelectColumns(Raw, {"ocid", "award_id", "buyer_id", "procurement_method_details", "award_status",
                                         "tender_start_date", "award_date", "award_lag_days"}),
    Renamed  = Table.RenameColumns(Kept, {{"procurement_method_details", "procurement_method"}}),
    Labelled = Table.ReplaceValue(Renamed, null, "(method not stated)", Replacer.ReplaceValue, {"procurement_method"}),
    Typed    = Table.TransformColumnTypes(Labelled, {{"tender_start_date", type date}, {"award_date", type date},
                                                     {"award_lag_days", Int64.Type}})
in
    Typed
```

## SignatureLag

```
let
    Source = PostgreSQL.Database("localhost:5433", "nocopo_db"),
    Raw    = Source{[Schema = "analytics", Item = "vw_signature_lag_eligible"]}[Data],
    Kept   = Table.SelectColumns(Raw, {"ocid", "contract_id", "buyer_id", "award_date", "date_signed", "signature_lag_days"}),
    Typed  = Table.TransformColumnTypes(Kept, {{"award_date", type date}, {"date_signed", type date}, {"signature_lag_days", Int64.Type}})
in
    Typed
```

## Lifecycle

```
let
    Source = PostgreSQL.Database("localhost:5433", "nocopo_db"),
    Raw    = Source{[Schema = "analytics", Item = "vw_lifecycle_stage"]}[Data],
    Kept   = Table.SelectColumns(Raw, {"ocid", "buyer_id", "release_count", "highest_stage_rank", "highest_stage"}),
    Typed  = Table.TransformColumnTypes(Kept, {{"release_count", Int64.Type}, {"highest_stage_rank", Int64.Type}})
in
    Typed
```

## Contracts

```
let
    Source = PostgreSQL.Database("localhost:5433", "nocopo_db"),
    Raw    = Source{[Schema = "analytics", Item = "vw_contract_implementation_coverage"]}[Data],
    Kept   = Table.SelectColumns(Raw, {"ocid", "contract_id", "buyer_id", "contract_status", "has_implementation",
                                       "transaction_count", "implementation_milestone_count"}),
    Typed  = Table.TransformColumnTypes(Kept, {{"has_implementation", type logical}, {"transaction_count", Int64.Type},
                                               {"implementation_milestone_count", Int64.Type}})
in
    Typed
```

## EntityBenchmark

```
let
    Source = PostgreSQL.Database("localhost:5433", "nocopo_db"),
    Raw    = Source{[Schema = "analytics", Item = "vw_entity_benchmark"]}[Data],
    Kept   = Table.RemoveColumns(Raw, {"buyer_name"}),
    Typed  = Table.TransformColumnTypes(Kept, {
                 {"process_count", Int64.Type}, {"processes_reaching_tender", Int64.Type}, {"tender_reach_rate", type number},
                 {"processes_reaching_award", Int64.Type}, {"budget_line_n", Int64.Type}, {"planned_budget_total", Currency.Type},
                 {"competition_n", Int64.Type}, {"median_tenderers", type number}, {"single_bidder_rate", type number},
                 {"award_n", Int64.Type}, {"award_value_total", Currency.Type}, {"median_award_value", Currency.Type},
                 {"distinct_supplier_n", Int64.Type}, {"top_supplier_value_share", type number},
                 {"contract_n", Int64.Type}, {"implementation_coverage_rate", type number}})
in
    Typed
```

## MetricPopulation

```
let
    Source = PostgreSQL.Database("localhost:5433", "nocopo_db"),
    Raw    = Source{[Schema = "analytics", Item = "vw_metric_population"]}[Data],
    Typed  = Table.TransformColumnTypes(Raw, {{"candidate_count", Int64.Type}, {"eligible_count", Int64.Type}, {"eligible_pct", type number}})
in
    Typed
```

## DQImpact

```
let
    Source = PostgreSQL.Database("localhost:5433", "nocopo_db"),
    Raw    = Source{[Schema = "analytics", Item = "vw_dq_impact"]}[Data],
    Typed  = Table.TransformColumnTypes(Raw, {{"metric_order", Int64.Type}, {"candidate_records", Int64.Type}, {"eligible_records", Int64.Type},
                                              {"records_with_issue", Int64.Type}, {"records_lost_only_to_issue", Int64.Type},
                                              {"pct_of_candidate", type number}, {"affected_value_ngn", Currency.Type},
                                              {"eligible_value_ngn", Currency.Type}})
in
    Typed
```

---

## If something fails

| Message | Fix |
|---|---|
| "The column 'x' of the table wasn't found" | The view has a different column set than expected. Re-run `sql/05_views` in PostgreSQL and refresh the preview, or tell the project owner which column |
| Yellow bar: "Permission needed to run native queries" | Not expected (no native queries are used); click *Edit Permission* only if the source is `localhost:5433` / `nocopo_db` |
| "Please specify how to connect" | *Edit Credentials* → *Database* → user `nocopo_bi` → *Connect* |
| "This server does not support SSL" | In the credentials dialog untick *Encrypt connections* |
| A table shows *Error* values after Close & Apply | Open that query, find the step with the red error, and check the column type step against the block above |
| Can see `stg` or `core` in the Navigator | You are connected as the wrong user. Edit the credentials to `nocopo_bi` |
