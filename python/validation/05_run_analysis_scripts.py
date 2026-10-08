"""
NOCOPO — Business-Question Analysis Runner
==========================================
Phase 8: Business-Question SQL Analysis
Project: Nigeria Public Procurement Intelligence

Purpose
-------
Run every script in sql/06_analysis/ and write all labelled result sets to
docs/phase8_analysis/phase8_analysis_results.md, so that each business-question
answer can be re-run, read and spot-checked in one place.

Each analysis script is split into result sets by marker comments:

    -- [RS1] Title of the result set
    SELECT ...;

Before running, every script is checked statically:
  * it must read only from the analytics schema (no stg.* or core.* references
    outside comments), and
  * it must not contain DDL or DML (analysis scripts create no objects).
The queries then run inside a read-only transaction.

Usage
-----
    python python/validation/05_run_analysis_scripts.py              # all scripts
    python python/validation/05_run_analysis_scripts.py --only 03    # one script
    python python/validation/05_run_analysis_scripts.py --skip-register
        skips result sets that read analytics.vw_metric_population (a few seconds each)

A partial run (--only / --skip-register) prints to the console and does not
overwrite the results file.

Output
------
    docs/phase8_analysis/phase8_analysis_results.md (full runs only)
    Exit code 1 if a script breaks the static rules or a query fails.
"""

import argparse
import glob
import os
import re
import sys
import time
from datetime import datetime
from decimal import Decimal

import psycopg

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SCRIPT_DIR = os.path.join(ROOT, "sql", "06_analysis")
OUTPUT_REL = os.path.join("docs", "phase8_analysis", "phase8_analysis_results.md")

MARKER = re.compile(r"^-- \[(RS\w+)\]\s*(.*)$")
FORBIDDEN_SOURCE = re.compile(r"\b(stg|core)\s*\.\s*\w+", re.IGNORECASE)
FORBIDDEN_DDL = re.compile(r"\b(CREATE|ALTER|DROP|INSERT|UPDATE|DELETE|TRUNCATE|GRANT)\b", re.IGNORECASE)


def split_script(text):
    """Return (header_lines, [(rs_id, title, sql), ...])."""
    header, sections, current = [], [], None
    for line in text.splitlines():
        m = MARKER.match(line)
        if m:
            current = [m.group(1), m.group(2), []]
            sections.append(current)
        elif current is None:
            header.append(line)
        else:
            current[2].append(line)
    return header, [(i, t, "\n".join(s).strip()) for i, t, s in sections]


def strip_comments(sql):
    return "\n".join(re.sub(r"--.*$", "", line) for line in sql.splitlines())


def static_problems(text):
    problems = []
    code = strip_comments(text)
    for m in FORBIDDEN_SOURCE.finditer(code):
        problems.append(f"reads a non-analytics object: {m.group(0)}")
    for m in FORBIDDEN_DDL.finditer(code):
        problems.append(f"contains DDL/DML keyword: {m.group(0)}")
    return problems


def fmt(v, col=""):
    if v is None:
        return ""
    if isinstance(v, bool):
        return "yes" if v else "no"
    if isinstance(v, int):
        return str(v) if "year" in col.lower() and 1900 <= v <= 2100 else f"{v:,}"
    if isinstance(v, (Decimal, float)):
        text = format(Decimal(str(v)), ",f")
        return text.rstrip("0").rstrip(".") if "." in text else text
    return str(v).replace("|", "\\|")


def md_table(cols, rows):
    out = ["| " + " | ".join(cols) + " |", "|" + "|".join("---" for _ in cols) + "|"]
    out += ["| " + " | ".join(fmt(v, c) for v, c in zip(row, cols)) + " |" for row in rows]
    return out


def main():
    parser = argparse.ArgumentParser(description="Run the NOCOPO business-question analysis scripts.")
    parser.add_argument("--only", help="run only scripts whose file name starts with this prefix, e.g. 03")
    parser.add_argument("--skip-register", action="store_true",
                        help="skip result sets that read analytics.vw_metric_population")
    args = parser.parse_args()
    partial = bool(args.only) or args.skip_register

    files = sorted(glob.glob(os.path.join(SCRIPT_DIR, "*.sql")))
    if args.only:
        files = [f for f in files if os.path.basename(f).startswith(args.only)]
    if not files:
        print("No analysis scripts found.")
        sys.exit(1)

    conninfo = dict(
        host=os.environ.get("PGHOST", "localhost"),
        port=os.environ.get("PGPORT", "5433"),
        user=os.environ.get("PGUSER", "postgres"),
        dbname=os.environ.get("PGDATABASE", "nocopo_db"),
    )

    failures, report, summary = [], [], []
    with psycopg.connect(**conninfo) as conn:
        conn.read_only = True
        server = conn.execute("SHOW server_version").fetchone()[0]
        for path in files:
            name = os.path.basename(path)
            with open(path, encoding="utf-8") as fh:
                text = fh.read()
            problems = static_problems(text)
            header, sections = split_script(text)
            report += ["", f"## {name}", ""]
            question = next((l[2:].strip() for l in header if l.startswith("-- Question:")), "")
            if question:
                report += [f"*{question}*", ""]
            if problems:
                for p in problems:
                    failures.append(f"{name}: {p}")
                    report.append(f"**STATIC CHECK FAILED:** {p}")
                summary.append((name, len(sections), 0, "static check failed", 0.0))
                continue
            ran, started = 0, time.time()
            for rs_id, title, sql in sections:
                if args.skip_register and "vw_metric_population" in sql:
                    report += [f"### {rs_id} — {title}", "", "*(skipped: --skip-register)*", ""]
                    continue
                t0 = time.time()
                try:
                    cur = conn.execute(sql)
                    cols = [d.name for d in cur.description]
                    rows = cur.fetchall()
                except Exception as exc:  # report and continue with the next result set
                    conn.rollback()
                    failures.append(f"{name} {rs_id}: {exc}")
                    report += [f"### {rs_id} — {title}", "", f"**ERROR:** `{exc}`".replace("\n", " "), ""]
                    continue
                ran += 1
                report += [f"### {rs_id} — {title}", "", f"*{len(rows):,} row(s), {time.time() - t0:.1f} s*", ""]
                report += md_table(cols, rows) + [""]
                if partial:
                    print(f"\n[{name} {rs_id}] {title}  ({len(rows)} rows)")
                    print(" | ".join(cols))
                    for r in rows:
                        print(" | ".join(fmt(v, c) for v, c in zip(r, cols)))
            summary.append((name, len(sections), ran, "ok", time.time() - started))
        conn.rollback()

    print("\nScript summary")
    for name, total, ran, status, secs in summary:
        print(f"  {name}: {ran}/{total} result sets run, {secs:.0f} s, {status}")
    for f in failures:
        print(f"  FAILED {f}")

    if not partial:
        out = [
            "# Phase 8 — Business-Question Analysis Results",
            "",
            f"> **Runner:** `python/validation/05_run_analysis_scripts.py`  ",
            f"> **Run date:** {datetime.now():%Y-%m-%d %H:%M:%S}  ",
            f"> **Database:** `{conninfo['dbname']}` on {conninfo['host']}:{conninfo['port']} (PostgreSQL {server})  ",
            f"> **Scripts:** {len(files)}; {sum(s[2] for s in summary)} result sets run; "
            f"{'no failures' if not failures else str(len(failures)) + ' FAILURE(S)'}.",
            "",
            "Every script reads only `analytics.*` views and runs in a read-only transaction. "
            "Interpretation, limitations and spot-checks: `docs/phase8_analysis/phase8_business_question_analysis.md`.",
        ] + report + ["", "---", "",
                      "*Generated by `python/validation/05_run_analysis_scripts.py`. "
                      "Raw dataset, stg.* and core.* not modified.*", ""]
        os.makedirs(os.path.dirname(os.path.join(ROOT, OUTPUT_REL)), exist_ok=True)
        with open(os.path.join(ROOT, OUTPUT_REL), "w", encoding="utf-8") as fh:
            fh.write("\n".join(out))
        print(f"Report: {OUTPUT_REL}")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
