"""
NOCOPO — Findings Claim-Trace Check (Gate D)
============================================
Phase 10: Business Interpretation, Findings & Recommendations
Project: Nigeria Public Procurement Intelligence

Purpose
-------
Gate D says every material claim in the executive findings traces to a
specific SQL output. This script tests that mechanically:

1. Coverage. It extracts every figure from docs/phase10_findings/findings.md
   (amounts in NGN, percentages, numbers with thousands separators, decimals,
   and numbers followed by a count or day unit). Each figure must sit in a
   paragraph, list item or table row that carries a claim tag such as [S1], and
   claim_trace.md must have a row with that tag and that figure.
2. Correctness. For every row of docs/phase10_findings/claim_trace.md it finds
   the cited cell, either in a result set of
   docs/phase8_analysis/phase8_analysis_results.md (source "01/RS2") or in the
   reconciliation pack (source "REC/EXE-03": the SQL value recorded in
   dashboard/reconciliation_log.md from dashboard/reconciliation_expected_values.sql).
   The cell must equal the row's source value, and the stated figure must equal
   that value times the row's scale, rounded to the stated precision.
3. Wording. The terms fraud, corrupt*, collu*, misconduct and kickback may
   appear only in the findings' disclaimer section ("About this report").
4. Other documents. In the README and the portfolio documents (ALSO_CHECKED),
   every figure in a block that carries a claim tag must match a claim_trace.md
   row under that tag. Untagged blocks there (rule thresholds, suite counts,
   audit evidence linked to its phase document) are not checked.

With --live it also re-runs dashboard/reconciliation_expected_values.sql
(read-only) and fails if any value cited from the reconciliation pack no
longer matches the database.

Figures not extracted: identifiers (DQ-14, M-S01, RS3, C-06), section and
phase numbers, versions, dates and years, and small integers written without
a unit (claim_trace.md still lists and verifies those it cites).

Usage
-----
    python python/validation/07_check_findings_trace.py
    python python/validation/07_check_findings_trace.py --live

Output
------
    docs/phase10_findings/claim_trace_check_results.md   (exit code 1 on any failure)
"""

import argparse
import importlib.util
import os
import re
import sys
from datetime import datetime
from decimal import Decimal, ROUND_HALF_UP, InvalidOperation

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FINDINGS = os.path.join(ROOT, "docs", "phase10_findings", "findings.md")
TRACE = os.path.join(ROOT, "docs", "phase10_findings", "claim_trace.md")
RESULTS = os.path.join(ROOT, "docs", "phase8_analysis", "phase8_analysis_results.md")
REC_LOG = os.path.join(ROOT, "dashboard", "reconciliation_log.md")
REC_SQL = os.path.join(ROOT, "dashboard", "reconciliation_expected_values.sql")
OUTPUT = os.path.join(ROOT, "docs", "phase10_findings", "claim_trace_check_results.md")

ALSO_CHECKED = ["README.md", "docs/business_requirements.md", "docs/methodology.md",
                "docs/data_dictionary.md", "docs/assumptions_and_limitations.md", "docs/phase12_qa/qa_checklist.md"]
DISCLAIMER_HEADING = "About this report"
PROHIBITED = re.compile(r"fraud|corrupt|collu|misconduct|kickback", re.I)
TAG = re.compile(r"\[([A-Z]\d+)\]")

UNITS = (r"days?|awards?|tenders?|tenderers?|suppliers?|entities|entity|OCIDs?|contracts?|processes|process"
         r"|budget lines?|lines?|records?")
# Masked before extraction: identifiers, references, versions, dates.
MASKS = [
    r"`[^`]*`",                                   # inline code
    r"\]\([^)]*\)",                               # link targets
    r"\[[A-Z]\d+\]",                              # claim tags
    r"\b(?:DQ|C|P|D|I|O|R|M|BQ|RS|AV|SP|WF|EXE|SUP|COM|BVA|TIM|ENT|IMP)-?[A-Z]?\d+[A-Za-z0-9-]*",
    r"\b(?:Phase|phase|Version|version|v)\s?\d+(?:\.\d+)+",
    r"§\s?\d+(?:\.\d+)*",
    r"\b\d{4}-\d{2}-\d{2}\b",
    r"SHA-256",
]
TOKEN_PATTERNS = [
    ("NGN", re.compile(r"([−-])?₦\s?(\d[\d,]*(?:\.\d+)?)\s?(tn|bn|m)\b")),
    ("PCT", re.compile(r"([−-])?(\d[\d,]*(?:\.\d+)?)\s?%")),
    ("NUM", re.compile(r"(?<![\w.])([−-])?(\d[\d,]*(?:\.\d+)?)\s(?:" + UNITS + r")\b")),
    ("NUM", re.compile(r"(?<![\w.,])([−-])?(\d{1,3}(?:,\d{3})+(?:\.\d+)?)(?![\d,])")),
    ("NUM", re.compile(r"(?<![\w.,])([−-])?(\d+\.\d+)(?!\.?\d)")),     # a sentence-final full stop is not part of it
]
NO_UNIT_PREFIX = re.compile(r"(?:top|largest|first|Top)[ -]$")


# ------------------------------------------------------------------
# Parsing helpers
# ------------------------------------------------------------------
def dec(text):
    t = text.strip().replace(",", "").replace("%", "").replace("−", "-")
    try:
        return Decimal(t)
    except InvalidOperation:
        return None


def canonical(kind, sign, number, unit=""):
    n = number.replace(",", "")
    return f"{kind}:{'-' if sign else ''}{n}{':' + unit if unit else ''}"


def extract_tokens(text):
    """Figures in a block of findings text, as canonical strings."""
    for m in MASKS:
        text = re.sub(m, lambda x: " " * len(x.group(0)), text)
    found = []
    for kind, pat in TOKEN_PATTERNS:
        def take(m):
            if kind == "NUM" and pat is TOKEN_PATTERNS[2][1] and NO_UNIT_PREFIX.search(text[: m.start()]):
                return " " * len(m.group(0))
            unit = m.group(3) if kind == "NGN" else ""
            found.append((canonical(kind, m.group(1), m.group(2), unit), m.group(0).strip()))
            return " " * len(m.group(0))
        text = pat.sub(take, text)
    return found


def parse_stated(stated):
    s = stated.strip()
    if re.fullmatch(r"[−-]?\d+(?:\.\d+)?", s):          # a bare number, e.g. a small integer
        return canonical("NUM", s[0] in "−-", s.lstrip("−-")), s
    toks = extract_tokens(s)
    return toks[0] if len(toks) == 1 else (None, stated)


def md_cells(line):
    return [c.strip() for c in line.strip().strip("|").split("|")]


def load_results():
    """{ '01': { 'RS2': (cols, rows) } } from the Phase 8 results log."""
    tables, script, rs, cols = {}, None, None, None
    with open(RESULTS, encoding="utf-8") as fh:
        for line in fh:
            m = re.match(r"## (\d\d)_", line)
            if m:
                script, rs, cols = m.group(1), None, None
                tables[script] = {}
                continue
            m = re.match(r"### (RS\w+) —", line)
            if m:
                rs, cols = m.group(1), None
                continue
            if script and rs and line.startswith("|"):
                cells = md_cells(line)
                if cols is None:
                    cols = cells
                    tables[script][rs] = (cols, [])
                elif not set(line.strip()) <= set("|-"):
                    tables[script][rs][1].append(cells)
    return tables


def load_rec_log():
    """{ 'EXE-03': {'SQL value': ..., 'Eligible n': ...} } from the reconciliation log."""
    out, cols = {}, None
    with open(REC_LOG, encoding="utf-8") as fh:
        for line in fh:
            if not line.startswith("|"):
                cols = None
                continue
            cells = md_cells(line)
            if cells and cells[0] == "ID":
                cols = cells
                continue
            if cols and not set(line.strip()) <= set("|-"):
                out[cells[0]] = dict(zip(cols, cells))
    return out


def load_trace():
    rows, cols = [], None
    with open(TRACE, encoding="utf-8") as fh:
        for n, line in enumerate(fh, 1):
            if not line.startswith("|"):
                cols = None
                continue
            cells = md_cells(line)
            if cells[:3] == ["Tag", "Claim", "Stated figure"]:
                cols = cells
                continue
            if cols and not set(line.strip()) <= set("|-"):
                rows.append(dict(zip(cols, cells), _line=n))
    return rows


def findings_blocks(path=FINDINGS):
    """(section heading, block text, first line number) for paragraphs, list items and table rows."""
    blocks, cur, start, section, in_code = [], [], 0, "", False
    with open(path, encoding="utf-8") as fh:
        lines = fh.read().split("\n")

    def flush():
        nonlocal cur
        if cur:
            blocks.append((section, " ".join(cur), start))
        cur = []

    for n, line in enumerate(lines, 1):
        s = line.strip()
        if s.startswith("```"):
            flush()
            in_code = not in_code
            continue
        if in_code:
            continue
        if s.startswith("#"):
            flush()
            if s.startswith("## "):
                section = s[3:]
            continue
        if not s or s == "---":
            flush()
            continue
        if s.startswith("|"):
            flush()
            if not set(s) <= set("|-: "):
                blocks.append((section, s, n))
            continue
        if re.match(r"(?:[-*]|\d+\.)\s", s) or s.startswith(">"):
            flush()
            start = n
            cur = [s]
            continue
        if not cur:
            start = n
        cur.append(s)
    flush()
    return blocks


# ------------------------------------------------------------------
# Checks
# ------------------------------------------------------------------
def locate(row, tables, rec):
    """Return (cell value, problem)."""
    src, where, col = row.get("Source", ""), row.get("Row", ""), row.get("Column", "")
    if src.startswith("REC/"):
        fid = src[4:]
        if fid not in rec:
            return None, f"reconciliation figure {fid} not found"
        return rec[fid].get("SQL value"), None
    m = re.fullmatch(r"(\d\d)/(RS\w+)", src)
    if not m:
        return None, f"unrecognised source '{src}'"
    script, rs = m.groups()
    if script not in tables or rs not in tables[script]:
        return None, f"result set {src} not found"
    cols, rows = tables[script][rs]
    col = col.strip("`")
    if col not in cols:
        return None, f"column '{col}' not in {src}"
    cand = rows
    if where and where not in ("—", "-"):
        for cond in where.split(";"):
            k, _, v = cond.strip().partition("=")
            k = k.strip().strip("`")
            if k not in cols:
                return None, f"row key '{k}' not in {src}"
            i = cols.index(k)
            cand = [r for r in cand if r[i] == v.strip()]
    if len(cand) != 1:
        return None, f"row selector '{where}' matches {len(cand)} rows in {src}"
    return cand[0][cols.index(col)], None


def check_row(row, tables, rec):
    cell, problem = locate(row, tables, rec)
    if problem:
        return problem
    recorded = row.get("Source value", "")
    if dec(cell) is None or dec(cell) != dec(recorded):
        return f"source cell is '{cell}', claim_trace records '{recorded}'"
    canon, raw = parse_stated(row.get("Stated figure", ""))
    if canon is None:
        return f"stated figure '{row.get('Stated figure')}' is not a single recognisable figure"
    stated = dec(re.sub(r"^[A-Z]+:", "", canon).split(":")[0])
    scale = dec(row.get("Scale") or "1") or Decimal(1)
    places = Decimal(1).scaleb(stated.as_tuple().exponent)
    computed = (dec(cell) * scale).quantize(places, rounding=ROUND_HALF_UP)
    if computed != stated:
        return f"source value {cell} x {scale} rounds to {computed}, but findings state {stated}"
    if not (row.get("Eligible n") or "").strip() or not re.search(r"\d", row.get("Eligible n", "")):
        return "eligible n is missing"
    return None


def live_check(rec, cited_ids):
    """Re-run the reconciliation pack and compare with the logged SQL values."""
    import psycopg
    spec = importlib.util.spec_from_file_location(
        "reclog", os.path.join(ROOT, "python", "validation", "06_generate_reconciliation_log.py"))
    reclog = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(reclog)
    conninfo = dict(host=os.environ.get("PGHOST", "localhost"), port=os.environ.get("PGPORT", "5433"),
                    user=os.environ.get("PGUSER", "postgres"), dbname=os.environ.get("PGDATABASE", "nocopo_db"))
    with open(REC_SQL, encoding="utf-8") as fh:
        sql = fh.read()
    with psycopg.connect(**conninfo) as conn:
        conn.read_only = True
        cur = conn.execute(sql)
        cols = [d.name for d in cur.description]
        live = {r[cols.index("figure_id")]: r for r in cur.fetchall()}
    problems = []
    for fid in sorted(cited_ids):
        r = live.get(fid)
        if r is None:
            problems.append(f"{fid}: not returned by the reconciliation pack")
            continue
        shown = reclog.fmt(r[cols.index("expected_value")], r[cols.index("unit")])
        if shown != rec[fid].get("SQL value"):
            problems.append(f"{fid}: database now gives {shown}, log records {rec[fid].get('SQL value')}")
    return problems, len(live)


# ------------------------------------------------------------------
# Main
# ------------------------------------------------------------------
def main():
    ap = argparse.ArgumentParser(description="Check that every figure in the findings traces to SQL output.")
    ap.add_argument("--live", action="store_true", help="also re-run the reconciliation pack against the database")
    args = ap.parse_args()
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    tables, rec, trace = load_results(), load_rec_log(), load_trace()
    failures = []

    # 2. correctness of every claim_trace row
    row_results = []
    for row in trace:
        problem = check_row(row, tables, rec)
        row_results.append((row, problem))
        if problem:
            failures.append(f"claim_trace.md line {row['_line']} [{row.get('Tag')}] {row.get('Stated figure')}: {problem}")

    by_tag = {}
    for row in trace:
        canon, _ = parse_stated(row.get("Stated figure", ""))
        by_tag.setdefault(row.get("Tag"), set()).add(canon)

    # 1. coverage of every figure in the findings
    blocks = findings_blocks()
    tokens_total, used = 0, set()
    for section, text, line in blocks:
        toks = extract_tokens(text)
        if not toks:
            continue
        tags = TAG.findall(text)
        for canon, raw in toks:
            tokens_total += 1
            hit = [t for t in tags if canon in by_tag.get(t, set())]
            if not tags:
                failures.append(f"findings.md line {line}: '{raw}' has no claim tag in its block")
            elif not hit:
                failures.append(f"findings.md line {line}: '{raw}' not listed in claim_trace.md under {', '.join(tags)}")
            else:
                used.update((t, canon) for t in hit)
        for t in tags:
            if t not in by_tag:
                failures.append(f"findings.md line {line}: tag [{t}] has no rows in claim_trace.md")

    orphans = [r for r in trace if (r.get("Tag"), parse_stated(r.get("Stated figure", ""))[0]) not in used]

    # 4. tagged figures in the README and the portfolio documents
    also_total, also_failed, also_files = 0, 0, []
    for rel in ALSO_CHECKED:
        path = os.path.join(ROOT, rel)
        if not os.path.exists(path):
            continue
        also_files.append(rel)
        for section, text, line in findings_blocks(path):
            tags = TAG.findall(text)
            if not tags:
                continue
            for t in tags:
                if t not in by_tag:
                    failures.append(f"{rel} line {line}: tag [{t}] has no rows in claim_trace.md")
            for canon, raw in extract_tokens(text):
                also_total += 1
                if not any(canon in by_tag.get(t, set()) for t in tags):
                    also_failed += 1
                    failures.append(f"{rel} line {line}: '{raw}' not listed in claim_trace.md under {', '.join(tags)}")

    # 3. wording
    wording = []
    for section, text, line in blocks:
        for m in PROHIBITED.finditer(text):
            if DISCLAIMER_HEADING not in section:
                wording.append(f"findings.md line {line} ({section}): '{m.group(0)}'")
    with open(TRACE, encoding="utf-8") as fh:
        for n, l in enumerate(fh, 1):
            for m in PROHIBITED.finditer(l):
                wording.append(f"claim_trace.md line {n}: '{m.group(0)}'")
    failures += [f"prohibited wording outside the disclaimer: {w}" for w in wording]

    live_note = "not run (use --live)"
    if args.live:
        cited = {r["Source"][4:] for r in trace if r.get("Source", "").startswith("REC/")}
        problems, n_live = live_check(rec, cited)
        failures += [f"reconciliation pack (live): {p}" for p in problems]
        live_note = (f"run {datetime.now():%Y-%m-%d %H:%M}: {n_live} figures returned; "
                     f"{len(cited)} cited figures compared, {len(problems)} mismatches")

    passed = not failures
    tags_used = sorted({r.get("Tag") for r in trace})
    lines = [
        "# Findings Claim-Trace Check (Gate D)",
        "# Nigeria Public Procurement Intelligence",
        "",
        f"> **Generated:** {datetime.now():%Y-%m-%d %H:%M} by `python/validation/07_check_findings_trace.py`"
        f"{' --live' if args.live else ''}  ",
        "> **Checks:** `docs/phase10_findings/findings.md` against `docs/phase10_findings/claim_trace.md`, "
        "`docs/phase8_analysis/phase8_analysis_results.md` and the reconciliation pack  ",
        f"> **Result:** {'PASS' if passed else 'FAIL'}",
        "",
        "| Check | Result |",
        "|---|---|",
        f"| Claim-trace rows verified against their source cell | {sum(1 for _, p in row_results if not p)} of {len(row_results)} |",
        f"| Claim tags | {len(tags_used)} |",
        f"| Figures extracted from the findings | {tokens_total} |",
        f"| Figures without a matching claim-trace row | {sum(1 for f in failures if f.startswith('findings.md'))} |",
        f"| Claim-trace rows whose figure is not extracted from the findings text (verified, but not auto-located) | {len(orphans)} |",
        f"| Prohibited terms outside the disclaimer section | {len(wording)} |",
        f"| Tagged figures in the README and portfolio documents ({len(also_files)} files) matched to claim-trace rows | "
        f"{also_total - also_failed} of {also_total} |",
        f"| Reconciliation pack re-run against the database | {live_note} |",
        "",
    ]
    if failures:
        lines += ["## Failures", ""] + [f"- {f}" for f in failures] + [""]
    if orphans:
        lines += ["## Rows verified but not auto-located in the text", "",
                  "These figures are written without a unit the extractor recognises (for example a small integer). "
                  "Each was still checked against its source cell.", "",
                  "| Tag | Stated figure | Source |", "|---|---|---|"]
        lines += [f"| {r.get('Tag')} | {r.get('Stated figure')} | {r.get('Source')} |" for r in orphans] + [""]
    lines += ["## Row-by-row result", "",
              "| Tag | Stated figure | Source | Row | Column | Source value | Scale | Result |",
              "|---|---|---|---|---|---|---|---|"]
    for row, problem in row_results:
        lines.append(f"| {row.get('Tag')} | {row.get('Stated figure')} | {row.get('Source')} | {row.get('Row')} | "
                     f"{row.get('Column')} | {row.get('Source value')} | {row.get('Scale') or '1'} | "
                     f"{'ok' if not problem else 'FAIL: ' + problem} |")
    lines += ["", "---", "",
              "*Generated by `python/validation/07_check_findings_trace.py`. Read-only: no source or database object changed.*", ""]
    with open(OUTPUT, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(lines))

    print(f"Claim-trace rows: {len(row_results)}; figures in findings: {tokens_total}; "
          f"tagged figures in other documents: {also_total}; failures: {len(failures)}")
    for f in failures[:40]:
        print("  " + f)
    print(f"Report: {os.path.relpath(OUTPUT, ROOT)}")
    sys.exit(0 if passed else 1)


if __name__ == "__main__":
    main()
