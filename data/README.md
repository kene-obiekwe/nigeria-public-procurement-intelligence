# Data Source and Acquisition

This project uses a single public bulk export from the **Nigeria Open Contracting
Portal (NOCOPO)**, published by the Bureau of Public Procurement (BPP) in the
Open Contracting Data Standard (OCDS) format.

The raw file is **not committed** to this repository (see [Redistribution](#redistribution)).
It is treated as immutable. Every transformation produces new artefacts downstream.

---

## Source Inventory

| Item | Value |
|---|---|
| Publisher | The Bureau of Public Procurement (scheme `NG-BPP`, uid `BPP-01`) |
| Portal | Nigeria Open Contracting Portal: http://nocopo.bpp.gov.ng |
| Package URI (recorded in file) | `http://nocopo.bpp.gov.ng/ocdsjson.ashx?ocid=all` |
| Standard | OCDS 1.1 release package |
| Package published date | 2021-05-03T22:44:00Z |
| File name | `all07010.json` |
| Format | JSON, single file, UTF-8 |
| Size | 219,816,927 bytes (209.6 MB) |
| SHA-256 | `615146696f51d18f72c12c0152888280c12f280981096aae8408843e7d1bc90c` |
| Contents | 108,277 releases; 98,866 unique OCIDs |
| Local acquisition date | 2026-08-14 (filesystem timestamp of the saved file) |
| Licence | ODC Public Domain Dedication and Licence (ODC-PDDL) |
| Licence page | http://nocopo.bpp.gov.ng/license (checked 2026-10-07) |
| Publication policy | http://nocopo.bpp.gov.ng/policy |

The package metadata (URI, version, published date, publisher) is read directly
from the file by `python/profiling/01_structural_profiler.py`. The release and
OCID counts are verified by `python/profiling/02_targeted_validation.py`.

---

## Local Placement

The scripts expect the file at this path, relative to the repository root:

```
NOCOPO dataset/all07010.json
```

This folder is listed in `.gitignore`.

To verify a local copy, run either command and compare the result with the
SHA-256 above:

```bash
sha256sum "NOCOPO dataset/all07010.json"
```

```powershell
Get-FileHash "NOCOPO dataset\all07010.json" -Algorithm SHA256
```

---

## Reproducibility Caveat

**This analysis is pinned to the 2021-05-03 snapshot identified by the checksum above.**

As of 2026-10-07, the package URI no longer serves that snapshot. It redirects to
a freshly generated zipped export (`downloads.aspx?file=Exported/JSON/all<timestamp>.zip`).
A new download will contain different, more recent data and will not match the
checksum. All figures in `docs/` refer to the pinned snapshot. Re-running the
pipeline on a newer export requires re-running the Phase 2 profiling and
reviewing the data-quality decisions before relying on the results.

---

## Redistribution

ODC-PDDL places the data in the public domain, so the licence allows
redistribution. The file is still excluded from Git for practical reasons:

- At 209.6 MB it exceeds GitHub's 100 MB per-file limit.
- The published-source-plus-checksum approach keeps the repository light while
  keeping the exact input verifiable.

---

## Known Publisher Caveats

These carry forward to the limitations section of the final findings:

- **Single publication timestamp.** Every release has the same `date` value
  (`2021-05-03T22:44:00Z`). It records when the package was published, not when
  any procurement event happened (DQ-10).
- **Uneven lifecycle coverage.** All releases carry planning data, but only
  about 17% carry tender data and about 16% carry award data. Missing stages
  are a reporting-coverage gap, not evidence that the event did not occur.
- **Repeated releases per process.** 6,280 OCIDs appear in more than one
  release. The content sometimes differs between those releases (see
  `docs/phase4_1_snapshot_validation_report.md`).
- **Coverage scope.** The portal reflects what entities chose or were able to
  publish. It is not a complete record of Nigerian public procurement.
