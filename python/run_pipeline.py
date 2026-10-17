"""
NOCOPO — One-Command Reproducible Build
=======================================
Phase 11: Documentation & GitHub Portfolio Packaging
Project: Nigeria Public Procurement Intelligence

Purpose
-------
Rebuild the whole analytical database from the raw source file, then validate it,
in one command. Against an EMPTY database it runs, in order:

   1  schema       sql/02_schema/00_draft_core_schema.sql (stg + core DDL, executed v1.x)
   2  staging      python/ingest/01_load_staging.py (raw JSON -> stg.*, SHA-256 checked)
   3  core         sql/02_schema/02_performance_indexes.sql,
                   sql/04_transformations/01_build_dim_buyer.sql, 02_build_dim_supplier.sql,
                   03_process_snapshot.sql (materialised process snapshot)
   4  refresh      sql/04_transformations/04_refresh_snapshot.sql
   5  analytics    sql/05_views/*.sql in filename order (01 ... 11)
   6  bi role      database/seed_and_setup/01_create_bi_role.sql (read-only Power BI role)
   7  analyze      ANALYZE on the whole database (fresh planner statistics after the bulk load;
                   without it several validation queries can take many minutes on a new build)
   8  suites       python/validation/04_run_validation_suite.py --phase 6, 7, 8, 9, 10
   9  analysis     python/validation/05_run_analysis_scripts.py
  10  trace        python/validation/07_check_findings_trace.py --live (Gate D)

It stops at the first failure and prints a summary. SQL files run through psycopg
(no psql needed on PATH); each file runs as one script, as `psql -f` would.

Steps 8 to 10 regenerate the committed result logs in docs/ (and
docs/phase5_staging/phase5_staging_results.md, written by the Gate B suite's stage 1).
On an unchanged source file the only differences are run metadata: run dates,
timings and the database name.

Requirements
------------
- PostgreSQL 15+ reachable through the usual PG* variables (defaults: localhost,
  5433, postgres). The password comes from pgpass.conf / PGPASSWORD, never from
  the command line.
- The source file at "NOCOPO dataset/all07010.json" (see data/README.md); the
  loader checks its SHA-256.
- An empty target database. The script refuses to build into a database that
  already has stg, core or analytics tables, so it cannot overwrite a working build.

Database name
-------------
The BI role script grants CONNECT on `nocopo_db`. When --db names another
database, the pipeline substitutes that name in this one statement at run time;
the file itself is unchanged. The role nocopo_bi is cluster-wide and is created
only if it does not exist; no password is set (see the script header).

Usage
-----
    python python/run_pipeline.py                     # build into nocopo_db (must be empty)
    python python/run_pipeline.py --db nocopo_test --create-db
    python python/run_pipeline.py --skip-suites       # build and analyse, skip steps 8 and 10

Exit code 1 on the first failing step.
"""

import argparse
import glob
import os
import subprocess
import sys
import time

import psycopg
from psycopg import sql

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PY = sys.executable


def rel(*parts):
    return os.path.join(ROOT, *parts)


SCHEMA_FILES = [rel("sql", "02_schema", "00_draft_core_schema.sql")]
CORE_FILES = [rel("sql", "02_schema", "02_performance_indexes.sql"),
              rel("sql", "04_transformations", "01_build_dim_buyer.sql"),
              rel("sql", "04_transformations", "02_build_dim_supplier.sql"),
              rel("sql", "04_transformations", "03_process_snapshot.sql")]
REFRESH_FILES = [rel("sql", "04_transformations", "04_refresh_snapshot.sql")]
VIEW_FILES = sorted(glob.glob(rel("sql", "05_views", "*.sql")))
BI_ROLE_FILE = rel("database", "seed_and_setup", "01_create_bi_role.sql")
SUITE_PHASES = ["6", "7", "8", "9", "10"]


def conninfo(dbname):
    return dict(host=os.environ.get("PGHOST", "localhost"), port=os.environ.get("PGPORT", "5433"),
                user=os.environ.get("PGUSER", "postgres"), dbname=dbname)


def run_sql_files(db, files, transform=None):
    """Run each file as one script on an autocommit connection (files may carry BEGIN/COMMIT)."""
    with psycopg.connect(**conninfo(db), autocommit=True) as conn:
        for path in files:
            with open(path, encoding="utf-8") as fh:
                text = fh.read()
            if transform:
                text = transform(text)
            print(f"      {os.path.relpath(path, ROOT).replace(os.sep, '/')}", flush=True)
            conn.execute(text)


def analyze_database(db):
    with psycopg.connect(**conninfo(db), autocommit=True) as conn:
        print("      ANALYZE", flush=True)
        conn.execute("ANALYZE")


def run_python(db, script, *args):
    env = dict(os.environ, PGDATABASE=db, PYTHONIOENCODING="utf-8")
    cmd = [PY, rel(*script.split("/"))] + list(args)
    print(f"      {script} {' '.join(args)}".rstrip(), flush=True)
    res = subprocess.run(cmd, cwd=ROOT, env=env, capture_output=True, text=True, encoding="utf-8", errors="replace")
    tail = [l for l in res.stdout.strip().splitlines() if l.strip()][-3:]
    for line in tail:
        print(f"        {line}")
    if res.returncode != 0:
        if res.stderr.strip():
            print("        " + "\n        ".join(res.stderr.strip().splitlines()[-15:]))
        raise RuntimeError(f"{script} {' '.join(args)} exited with code {res.returncode}")
    return tail[-1] if tail else ""


def ensure_database(db, create):
    with psycopg.connect(**conninfo("postgres"), autocommit=True) as conn:
        exists = conn.execute("SELECT 1 FROM pg_database WHERE datname = %s", (db,)).fetchone()
        if not exists:
            if not create:
                raise RuntimeError(f"database {db} does not exist (use --create-db to create it)")
            conn.execute(sql.SQL("CREATE DATABASE {} WITH TEMPLATE template0 ENCODING 'UTF8'").format(sql.Identifier(db)))
            print(f"Created database {db}.")
    with psycopg.connect(**conninfo(db)) as conn:
        n = conn.execute("""SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
                            WHERE n.nspname IN ('stg', 'core', 'analytics') AND c.relkind IN ('r', 'v', 'm')""").fetchone()[0]
    if n:
        raise RuntimeError(f"database {db} already holds {n} stg/core/analytics relations; "
                           "build into an empty database (for example --db nocopo_rebuild --create-db)")


def main():
    ap = argparse.ArgumentParser(description="Rebuild and validate the NOCOPO database from the raw file.")
    ap.add_argument("--db", default=os.environ.get("PGDATABASE", "nocopo_db"), help="target database (must be empty)")
    ap.add_argument("--create-db", action="store_true", help="create the target database if it does not exist")
    ap.add_argument("--skip-suites", action="store_true", help="skip the validation suites and the trace check")
    args = ap.parse_args()
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    db = args.db

    def bi_role_for_db(text):
        return text if db == "nocopo_db" else text.replace("ON DATABASE nocopo_db", f'ON DATABASE "{db}"')

    steps = [
        ("schema", lambda: run_sql_files(db, SCHEMA_FILES)),
        ("staging", lambda: run_python(db, "python/ingest/01_load_staging.py")),
        ("core", lambda: run_sql_files(db, CORE_FILES)),
        ("refresh", lambda: run_sql_files(db, REFRESH_FILES)),
        ("analytics", lambda: run_sql_files(db, VIEW_FILES)),
        ("bi role", lambda: run_sql_files(db, [BI_ROLE_FILE], transform=bi_role_for_db)),
        ("analyze", lambda: analyze_database(db)),
    ]
    if not args.skip_suites:
        steps += [(f"suite {p}", (lambda p=p: run_python(db, "python/validation/04_run_validation_suite.py", "--phase", p)))
                  for p in SUITE_PHASES]
    steps.append(("analysis", lambda: run_python(db, "python/validation/05_run_analysis_scripts.py")))
    if not args.skip_suites:
        steps.append(("trace", lambda: run_python(db, "python/validation/07_check_findings_trace.py", "--live")))

    print(f"NOCOPO pipeline -> database {db}")
    summary, started, current, t0 = [], time.time(), "setup", time.time()
    try:
        ensure_database(db, args.create_db)
        for i, (name, fn) in enumerate(steps, 1):
            current, t0 = name, time.time()
            print(f"[{i}/{len(steps)}] {name}", flush=True)
            note = fn()
            summary.append((name, "ok", time.time() - t0, note or ""))
    except Exception as exc:  # stop on the first failure
        summary.append((current, "FAILED", time.time() - t0, str(exc).splitlines()[0]))
        ok = False
    else:
        ok = True

    print("\nSummary")
    for name, status, secs, note in summary:
        print(f"  {name:<10} {status:<7} {secs:7.1f} s  {note}")
    print(f"Total {time.time() - started:.0f} s: {'all steps passed' if ok else 'stopped at the first failure'}.")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
