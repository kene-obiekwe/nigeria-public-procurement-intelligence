"""
NOCOPO — Relative Link Check
============================
Phase 11: Documentation & GitHub Portfolio Packaging
Project: Nigeria Public Procurement Intelligence

Purpose
-------
Check that every relative link and image in the repository's tracked Markdown
files resolves: the target file or folder exists, and a `#fragment` matches a
heading in the target Markdown file (GitHub heading anchors). External links
(http, https, mailto) are not fetched. Links inside code spans and fenced code
blocks are ignored.

Usage
-----
    python python/validation/09_check_links.py

Exit code 1 if any link is broken.
"""

import os
import re
import subprocess
import sys
from urllib.parse import unquote

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LINK = re.compile(r"!?\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
HTML_SRC = re.compile(r"<(?:img|a)\s[^>]*(?:src|href)=\"([^\"]+)\"", re.I)


def tracked_markdown():
    out = subprocess.run(["git", "ls-files", "*.md"], cwd=ROOT, capture_output=True, text=True, check=True).stdout
    return [p for p in out.splitlines() if p]


def slug(heading):
    """GitHub-style anchor for a heading."""
    h = re.sub(r"[`*_~]", "", heading.strip().lower())
    h = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", h)           # link text only
    h = re.sub(r"[^\w\- ]", "", h, flags=re.UNICODE)
    return h.replace(" ", "-")


def anchors(path):
    found, seen, in_code = set(), {}, False
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            if line.lstrip().startswith("```"):
                in_code = not in_code
                continue
            m = None if in_code else re.match(r"#{1,6}\s+(.*?)\s*#*\s*$", line)
            if m:
                base = slug(m.group(1))
                n = seen.get(base, 0)
                found.add(base if n == 0 else f"{base}-{n}")
                seen[base] = n + 1
    return found


def links_in(path):
    in_code = False
    with open(path, encoding="utf-8") as fh:
        for n, line in enumerate(fh, 1):
            if line.lstrip().startswith("```"):
                in_code = not in_code
                continue
            if in_code:
                continue
            text = re.sub(r"`[^`]*`", "", line)
            for m in list(LINK.finditer(text)) + list(HTML_SRC.finditer(text)):
                yield n, m.group(1)


def main():
    broken, checked = [], 0
    cache = {}
    for rel in tracked_markdown():
        src = os.path.join(ROOT, rel)
        for line, target in links_in(src):
            if re.match(r"^(https?:|mailto:)", target):
                continue
            checked += 1
            path_part, _, frag = target.partition("#")
            dest = src if not path_part else os.path.normpath(os.path.join(os.path.dirname(src), unquote(path_part)))
            if not os.path.exists(dest):
                broken.append(f"{rel}:{line}: {target} (missing file)")
                continue
            if frag and dest.endswith(".md"):
                if dest not in cache:
                    cache[dest] = anchors(dest)
                if frag.lower() not in cache[dest]:
                    broken.append(f"{rel}:{line}: {target} (no heading #{frag})")
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    print(f"Markdown files: {len(tracked_markdown())}; relative links checked: {checked}; broken: {len(broken)}")
    for b in broken:
        print("  " + b)
    sys.exit(1 if broken else 0)


if __name__ == "__main__":
    main()
