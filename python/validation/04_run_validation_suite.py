"""
NOCOPO — Gate B Validation Suite Runner
=======================================
Phase 6: Core Model Implementation & Validation
Project: Nigeria Public Procurement Intelligence

Purpose
-------
Run the full validation suite and write the Gate B results log.

  Stage 1  Raw -> staging: python/ingest/02_reconcile_staging.py
           (independent traversal of the source JSON).
  Stage 2  Every sql/03_data_quality/*.sql file, in filename order.
           Each file returns rows of:
             check_id, check_group, check_name, severity, expected, actual, passed
           severity GATE must pass; INFO records a measurement.

The checks themselves live in SQL. This script only executes them and
formats the results.

Usage
-----
    Gate B (Phase 6, default):
        python python/validation/04_run_validation_suite.py
    Phase 7 analytical views:
        python python/validation/04_run_validation_suite.py --phase 7
    Phase 8 business-question outputs and DQ-impact view:
        python python/validation/04_run_validation_suite.py --phase 8
    Phase 9 Power BI layer (read-only role and presentation dimensions):
        python python/validation/04_run_validation_suite.py --phase 9

Output
------
    Phase 6: docs/phase6_core_model/phase6_validation_results.md
    Phase 7: docs/phase7_analytics/phase7_view_validation_results.md
    Phase 8: docs/phase8_analysis/phase8_validation_results.md
    Phase 9: docs/phase9_dashboard/phase9_validation_results.md
    Exit code 1 if any GATE check fails.
"""

import argparse
import glob
import os
import subprocess
import sys
from datetime import datetime

import psycopg

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SUITE_DIR = os.path.join(ROOT, "sql", "03_data_quality")
STAGE1 = os.path.join(ROOT, "python", "ingest", "02_reconcile_staging.py")
SUITES = {
    # phase: (sql file pattern, output report, title, interpretation doc, runs stage 1)
    "6": ("0[1-8]_*.sql",
          os.path.join("docs", "phase6_core_model", "phase6_validation_results.md"),
          "Phase 6 — Gate B Validation Results", "docs/phase6_core_model/phase6_core_model.md", True),
    "7": ("09_*.sql",
          os.path.join("docs", "phase7_analytics", "phase7_view_validation_results.md"),
          "Phase 7 — Analytical View Validation Results", "docs/phase7_analytics/phase7_analytical_views.md", False),
    "8": ("10_*.sql",
          os.path.join("docs", "phase8_analysis", "phase8_validation_results.md"),
          "Phase 8 — Business-Question Validation Results",
          "docs/phase8_analysis/phase8_business_question_analysis.md", False),
    "9": ("11_*.sql",
          os.path.join("docs", "phase9_dashboard", "phase9_validation_results.md"),
          "Phase 9 — Power BI Layer Validation Results",
          "docs/phase9_dashboard/phase9_dashboard.md", False),
}
GATE_LABELS = {"6": "Gate B result", "7": "Phase 7 exit-gate result", "8": "Phase 8 validation result",
                "9": "Phase 9 validation result"}


def main():
    parser = argparse.ArgumentParser(description="Run a NOCOPO validation suite.")
    parser.add_argument("--phase", choices=sorted(SUITES), default="6")
    args = parser.parse_args()
    pattern, output_rel, title, notes_doc, run_stage1 = SUITES[args.phase]
    output = os.path.join(ROOT, output_rel)

    # Stage 1 — raw -> staging (independent of SQL); Gate B suite only
    stage1_ok, stage1_summary = True, None
    if run_stage1:
        stage1 = subprocess.run([sys.executable, STAGE1], capture_output=True, text=True)
        stage1_summary = (stage1.stdout.strip().splitlines() or ["(no output)"])[-1].split(" Report:")[0]
        stage1_ok = stage1.returncode == 0

    # Stage 2 — SQL suite
    conninfo = dict(
        host=os.environ.get("PGHOST", "localhost"),
        port=os.environ.get("PGPORT", "5433"),
        user=os.environ.get("PGUSER", "postgres"),
        dbname=os.environ.get("PGDATABASE", "nocopo_db"),
    )
    files = sorted(glob.glob(os.path.join(SUITE_DIR, pattern)))
    results = []
    with psycopg.connect(**conninfo) as conn, conn.cursor() as cur:
        server = cur.execute("SHOW server_version").fetchone()[0]
        for path in files:
            with open(path, encoding="utf-8") as fh:
                cur.execute(fh.read())
            for row in cur.fetchall():
                results.append((os.path.basename(path),) + row)

    gate = [r for r in results if r[4] == "GATE"]
    gate_failed = [r for r in gate if r[7] is not True]
    info = [r for r in results if r[4] == "INFO"]
    passed = stage1_ok and not gate_failed

    fmt = lambda v: "" if v is None else (f"{int(v):,}" if v.lstrip("-").isdigit() else v)
    gate_label = GATE_LABELS[args.phase]
    out = [
        f"# {title}",
        "",
        f"> **Runner:** `python/validation/04_run_validation_suite.py --phase {args.phase}`  ",
        f"> **Run date:** {datetime.now():%Y-%m-%d %H:%M:%S}  ",
        f"> **Database:** `{conninfo['dbname']}` on {conninfo['host']}:{conninfo['port']} (PostgreSQL {server})  ",
        f"> **{gate_label}:** {'**PASSED**' if passed else '**FAILED**'}. "
        + (f"Stage 1 {'passed' if stage1_ok else 'FAILED'}; " if run_stage1 else "")
        + f"{len(gate) - len(gate_failed)} / {len(gate)} GATE checks passed; {len(info)} INFO measurements.",
        "",
        f"Interpretation and decisions: `{notes_doc}`.",
    ]
    if run_stage1:
        out += [
            "",
            "## Stage 1 — Raw → staging (independent JSON traversal)",
            "",
            f"`python/ingest/02_reconcile_staging.py`: {stage1_summary} "
            f"({'✓' if stage1_ok else '✗ FAIL'}). Detail: `docs/phase5_staging/phase5_staging_results.md`.",
        ]
    out += ["", f"## {'Stage 2 — ' if run_stage1 else ''}SQL validation suite (`sql/03_data_quality/{pattern}`)"]
    group = None
    for f, cid, grp, name, sev, exp, act, ok in results:
        if grp != group:
            group = grp
            out += ["", f"### {grp} — `{f}`", "", "| ID | Check | Severity | Expected | Actual | Result |",
                    "|---|---|---|---|---|---|"]
        status = "✓" if ok is True else ("✗ FAIL" if sev == "GATE" else "info")
        out.append(f"| {cid} | {name} | {sev} | {fmt(exp)} | {fmt(act)} | {status} |")
    out += ["", "---", "", "*Generated by `python/validation/04_run_validation_suite.py`. Raw dataset not modified.*", ""]

    os.makedirs(os.path.dirname(output), exist_ok=True)
    with open(output, "w", encoding="utf-8") as fh:
        fh.write("\n".join(out))
    if run_stage1:
        print(f"Stage 1: {stage1_summary}")
    print(f"SQL suite: {len(gate) - len(gate_failed)}/{len(gate)} GATE passed, {len(info)} INFO. "
          f"Report: {output_rel}")
    for r in gate_failed:
        print(f"  FAILED {r[1]} {r[3]}: expected {r[5]}, actual {r[6]}")
    sys.exit(0 if passed else 1)


if __name__ == "__main__":
    main()
