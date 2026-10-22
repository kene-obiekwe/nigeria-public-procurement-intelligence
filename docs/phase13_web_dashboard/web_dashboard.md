# Web Dashboard
# Nigeria Public Procurement Intelligence

> **Phase:** 13 (release v1.1) · **Date:** 2026-10-22 · **Status:** deployed and verified live
> **Live:** <https://nocopo-dashboard.vercel.app> · **Live check:** <https://nocopo-dashboard.vercel.app/check.html>
> **Code:** [`web/`](../../web/) · **Data export and check:** [`python/web/`](../../python/web/) ·
> **Design and decisions:** [`web_design_note.md`](web_design_note.md) · **Check results:** [`web_reconciliation_results.md`](web_reconciliation_results.md)

---

## 1. What it is

A static website with the eight pages of the Power BI report (1, 2a, 2b, 3 to 7). It needs no server and no database
at runtime: `python/web/export_web_data.py` writes the validated `analytics.*` views to JSON files in `web/data/` once,
and the browser computes every figure from those files with functions that mirror the DAX measures
(`web/js/metrics.js`). The same 177 figures that reconcile the Power BI report reconcile the web pages.

- Plain HTML, CSS and JavaScript modules; Apache ECharts 5.6.0, vendored. No framework and no build step.
- 2.17 MB of JSON (0.47 MB compressed); ECharts adds 1.0 MB (0.35 MB compressed).
- Every page has its own address (`#overview`, `#suppliers`, `#competition`, `#budget`, `#timing`, `#entities`,
  `#implementation`, `#data-quality`), and the filters are part of it (for example `#competition?method=Emergency`), so a
  view can be shared and the back button works.
- Light and dark themes (system setting, or the button at the top right; the choice is kept in the browser).
- No cookies, analytics, tracking or requests to any other site. The Content-Security-Policy allows only the site itself.

## 2. Pages and filters

A filter changes only the visuals whose data carries that field, as the Power BI slicers do (design note §2.3).

| Page | Address | Filters | What does not respond |
|---|---|---|---|
| 1 Executive overview | `#overview` | none (as in Power BI) | — |
| 2a Supplier concentration | `#suppliers` | entity, method, Top N (1 to 100) | DQ-21 panel |
| 2b Competition | `#competition` | entity, method | entity tables ignore the method (precomputed per entity) |
| 3 Budget versus award | `#budget` | entity, method | DQ-21 panel |
| 4 Procurement-cycle timing | `#timing` | entity, method, tender start year, award year | signature lag ignores method and years; coverage cards (register) ignore all |
| 5 Entity benchmark | `#entities` | entity, Top N, minimum tenders / awards / contracts / processes, DQ-21 switch | KPIs are precomputed per entity |
| 6 Implementation and lifecycle | `#implementation` | entity, contract status | stage chart and lowest-coverage table ignore the contract status |
| 7 Data quality and coverage | `#data-quality` | metric, impact type (issues table only) | register, cross-check cards |

**Data-quality flag DQ-21** (awards flagged as possible scale errors; decisions D-1 and F-2):
- Pages 1, 2a and 3 show a fixed panel, "Sensitivity: without awards flagged as possible scale errors (DQ-21)", with only
  the figures that the Phase 10.1 result sets check (01 RS6/RS6b, 03 RS11, and the flag footprint from 03 RS11a). The
  panel does not respond to the page filters and says so.
- Page 5 has the switch "Include awards flagged as possible scale errors (DQ-21)", on by default. Switched off, only
  entity award value, the share held by the largest entities and the order by award value change (checked against
  05 RS7/RS7b); the per-entity KPIs and medians stay as published, and a caption says so.

## 3. Rebuilding the data

Re-export whenever the database changes (after `python/run_pipeline.py` or a snapshot refresh). On unchanged data the
export is byte-identical; only `manifest.json` records a new time.

```bash
python python/web/export_web_data.py
```

```bash
python python/web/check_web_data.py
```

Then open `check.html` in a browser (section 5) and record its result line:

```bash
python python/web/check_web_data.py --browser-result "PASS: figures 177/177 PASS; DQ-21 sensitivity 277/277 cells PASS; ..."
```

| Script | Reads | Role it needs | Writes |
|---|---|---|---|
| `python/web/export_web_data.py` | `analytics.*` only, in a read-only transaction; a static check refuses any query that names another schema or contains DDL/DML | `nocopo_bi` (read-only) is sufficient | `web/data/*.json`, `web/data/manifest.json`, `web/data/expected.json` |
| `python/web/check_web_data.py` | `web/data/`; the reconciliation pack and the Phase 10.1 result sets, which read `analytics.*` only | `nocopo_bi` is sufficient | `docs/phase13_web_dashboard/web_reconciliation_results.md` |

Connection: the usual `PG*` variables (defaults `localhost`, `5433`, `postgres`, `nocopo_db`). To run as the read-only role
set `PGUSER=nocopo_bi` and supply its password through `PGPASSWORD` or `pgpass.conf`, or connect as the owner and pass
`--role nocopo_bi`, which switches role before reading (both scripts).

## 4. What the checks cover

| Check | How | Result (2026-10-22) |
|---|---|---|
| Manifest | Each file's SHA-256 and size equal `manifest.json`; row counts recounted from the JSON equal the manifest and the live views. The site also verifies every file's SHA-256 when it loads. | 14 files verified |
| Reconciliation (Python) | `check_web_data.py` recomputes the 177 figures from the JSON with its own implementation and compares them with the live SQL | 177 / 177 PASS |
| DQ-21 sensitivity | The seven Phase 10.1 result sets, cell by cell | 277 / 277 cells PASS |
| Reconciliation (browser) | `check.html` runs the site's own JavaScript over the same JSON | 177 / 177 and 277 / 277 PASS, at 1440 px and at 375 px |
| Cards on the pages | Every card on pages 1 to 7, unfiltered, compared with its figure in `expected.json` | 66 / 66 comparisons (46 figure IDs) PASS |
| Filtered cards | The pack's sliced figures (method, buyer, contract status, tender start year: SUP-16 to 18, COM-07/08/10, BVA-08/09, TIM-14 to 17, IMP-04/05); table figures BVA-10 and ENT-11 to 14 | 14 / 14 and 5 / 5 PASS |
| Entity and method filters | One entity and one method filter on each page that has them, compared with values computed by `check_web_data.py`'s functions | 48 / 48 PASS |
| DQ-21 switch (page 5) | Top N share at N = 1, 5, 10, 20, 50, 100 with and without flagged awards against 05 RS7; the top-10 order against 05 RS7b | 12 / 12 and 10 / 10 PASS |
| Layout | Every page at 1440, 800 and 375 px: no horizontal page scroll; long tables scroll in their own box; filters collapsed on phones, open on wider screens | 0 px overflow on all 8 pages at all three widths |
| Browser console and CSP | All pages and filtered views, chart tooltips and card taps, served with the `vercel.json` headers | 0 errors, 0 policy violations, 0 requests to other sites |
| Wording | The words of `dashboard/README.md` §7.3 in the site's HTML, JavaScript and CSS; the §8 caveat sentences allowed verbatim | 24 files, 0 findings |

## 5. Previewing locally

```bash
python -m http.server 8000 --directory web
```

Open `http://localhost:8000/` for the site and `http://localhost:8000/check.html` for the self-check (also linked as
"Data checks" in the footer). The HTML pages carry the same Content-Security-Policy as a `<meta>` tag, so a plain local
server already enforces it; the other headers in `web/vercel.json` apply only on Vercel.

## 6. Deploying and redeploying (Vercel)

The site is deployed from GitHub, with `web/` as the project root and no build step. It is live at <https://nocopo-dashboard.vercel.app>.

Deployment facts (as configured):

- **Root directory:** `web`, set under **Settings → Build and Deployment**.
- **Framework preset:** Other.
- **Build Command** and **Install Command:** overridden, and both left empty.
- **Output Directory:** left as it is (the root directory is served as is).
- **If `web` is missing from the folder picker:** the import screen's picker can show a stale repository tree. Type `web` into the Root Directory field under **Settings → Build and Deployment** instead.

First deployment:

1. Push the repository to GitHub, so that `web/` is on the `main` branch.
2. Go to <https://vercel.com>, choose **Sign Up** (or **Log In**) and then **Continue with GitHub**. When GitHub asks
   which repositories Vercel may access, choose **Only select repositories** and pick
   `nigeria-public-procurement-intelligence`.
3. In the Vercel dashboard choose **Add New… → Project**, find `nigeria-public-procurement-intelligence` under
   **Import Git Repository** and choose **Import**.
4. On **Configure Project**:
   - **Project Name:** any name (it becomes part of the address, for example `nocopo-dashboard`).
   - **Framework Preset:** **Other**.
   - **Root Directory:** choose **Edit**, select `web`, then **Continue**.
   - **Build and Output Settings:** open it. Turn on **Override** for **Build Command** and leave the field empty
     (no build command). Turn on **Override** for **Install Command** and leave it empty. Leave **Output Directory**
     as it is (the root directory, `web/`, is served as is).
   - **Environment Variables:** none.
5. Choose **Deploy** and wait for "Congratulations" (about a minute).
6. The address is on that page and later under the project's **Settings → Domains** (and on the project's overview
   page under **Domains**), in the form `https://<project-name>.vercel.app`.
7. Open the address and then `/check.html`: it must show "PASS: figures 177/177 …". In the browser's developer tools
   (Network, the document request) the response should carry the `Content-Security-Policy` header from `vercel.json`.
8. Put the address after "Live dashboard" in the repository [`README.md`](../../README.md) and commit (done: see above).

Redeploying: every push to `main` deploys again automatically, so a data refresh is: rebuild the database,
re-export (section 3), check, commit `web/data/` and push. Pushes to other branches create preview deployments only.

## 7. Differences from the Power BI report

| Item | Power BI | Web |
|---|---|---|
| DQ-21 | not shown | sensitivity panel on pages 1, 2a, 3; switch on page 5 (decisions D-1, F-2) |
| Highest and lowest entity tables (pages 2b, 6) | 4 to 8 rows visible (page space) | 10 (page 2b) and 15 (page 6) rows as in `dashboard/README.md` §7.1; ties listed |
| Largest difference tables (page 3) | two tables, a few rows visible | two tables, 15 rows each, scrolling |
| Timing caveat (page 4) | static text | the `[Timing Caveat]` measure, computed from the register, as in README §8 |
| Year lines (page 4) | n as a second series | n of each year in the tooltip |
| Entity filter | drop-down list | searchable input (type part of a name or buyer code) with an **All** button |
| Cards | compact values | compact values; the exact value in the tooltip and shown in place on tap or Enter |
| Card colours | navy, gold for timing and implementation | the same two-colour scheme in light and dark themes |

## 8. Licences

Data: NOCOPO OCDS export, Bureau of Public Procurement, ODC Public Domain Dedication and Licence (ODC-PDDL). Code and
documentation: MIT. Apache ECharts 5.6.0: Apache License 2.0 (`web/vendor/ECHARTS-LICENSE.txt`, `ECHARTS-NOTICE.txt`;
copied from the npm package `echarts@5.6.0`, whose sha512 integrity was verified against the registry).

## 9. Screenshots

[`screenshots/`](screenshots/): every page at 1440 px (`*_desktop.png`) and at 375 px (`*_375px.png`), full page, light
theme, no filters, captured from the local preview with the `vercel.json` headers.
