# Source Verification of Open Items
# Nigeria Public Procurement Intelligence

> **Generated:** 2026-10-17 18:09 by `python/validation/08_verify_source_items.py`  
> **Source:** `NOCOPO dataset/all07010.json`, SHA-256 `6151466…bc90c` (matches the pinned file)  
> **Mode:** read-only. Nothing in the raw file, `stg`, `core` or `analytics` was changed.  
> **Classification and proposals:** `docs/phase10_findings/findings.md` §9 (this file holds the evidence only).

Values are as published. NGN amounts are shown to two decimals so that whole-naira entries are visible.

## A. The top supplier's NGN 210bn award

Supplier `NG-BPP-73422` has two eligible awards (Phase 8, script 01 RS3: NGN 210.29bn in total). Every release of both OCIDs:

**ocds-gyl66f-2-005025**, release `113333` (release date 2025-03-11; tags: planning)

| Section | Field | Value |
|---|---|---|
| buyer | id / name | `NG-BPP-BPP-NOC-2` / FEDERAL CAPITAL TERRITORY ADMINISTRATION |
| planning | budget amount (NGN) | 900,000,000.00 |
| planning | budget projectID / project | 233875 / STDD/Emergency evacuation of slit and drainages and gutters in the satellite towns (Abaji) lot1 |
| planning | budget description | maintenance of dumps sites in satellite town |
| contract | — | (no contract in this release) |

**ocds-gyl66f-2-005025**, release `118873` (release date 2026-02-19; tags: planning, tender, award, contract)

| Section | Field | Value |
|---|---|---|
| buyer | id / name | `NG-BPP-BPP-NOC-2` / FEDERAL CAPITAL TERRITORY ADMINISTRATION |
| planning | budget amount (NGN) | 16,500,000,000.00 |
| planning | budget projectID / project | 233875 / STDD/Emergency evacuation of slit and drainages and gutters in the satellite towns (Abaji) lot1 |
| planning | budget description | Service wide Contingency |
| tender | method / details / status | open / Emergency / active |
| tender | value (NGN) / numberOfTenderers | 210,080,562,800.00 / 1 |
| tender | tender period | 2024-05-01 to 2024-05-13 |
| tender | title / description | STDD/Emergency evacuation of slit and drainages and gutters in the satellite towns (Abaji) lot1 / To provide good drainages and gutters in the FCT Satellite Towns (BWARI/KUBWA ) |
| award `19325` | status / date | active / 2024-05-08 |
| award `19325` | value (NGN) | 210,080,562,800.00 |
| award `19325` | suppliers | `NG-BPP-73422` Lemaco Engineering Ltd |
| award `19325` | title | Emergency Evacuation of Silt Drainages and Gutters in the satellite Town Gwagwalada Town Lot 2 |
| contract `18967` | status / date signed | active / 2024-05-21 |
| contract `18967` | value (NGN) | 210,080,562,800.00 |
| contract `18967` | title | Emergency Evacuation of Silt and Drainages in Gwagwalada Area council |
| contract `18967` | implementation | 0 transaction(s), values summed 0.00; 0 milestone(s) |

**ocds-gyl66f-2-005019**, release `113346` (release date 2025-03-11; tags: planning)

| Section | Field | Value |
|---|---|---|
| buyer | id / name | `NG-BPP-BPP-NOC-2` / FEDERAL CAPITAL TERRITORY ADMINISTRATION |
| planning | budget amount (NGN) | 300,000,000.00 |
| planning | budget projectID / project | 233776 / AMMC/FMM/Emergency desilting of blocked drainage system on jabi, gudu, apo, katampe, airport and onex abuja (… |
| planning | budget description | Maintenance of drainages in the city |
| contract | — | (no contract in this release) |

**ocds-gyl66f-2-005019**, release `118869` (release date 2026-02-19; tags: planning, tender, award)

| Section | Field | Value |
|---|---|---|
| buyer | id / name | `NG-BPP-BPP-NOC-2` / FEDERAL CAPITAL TERRITORY ADMINISTRATION |
| planning | budget amount (NGN) | 16,500,000,000.00 |
| planning | budget projectID / project | 233776 / AMMC/FMM/Emergency desilting of blocked drainage system on jabi, gudu, apo, katampe, airport and onex abuja (… |
| planning | budget description | Service wide Contingency |
| tender | method / details / status | open / Emergency / active |
| tender | value (NGN) / numberOfTenderers | 213,168,292.50 / 1 |
| tender | tender period |  to  |
| tender | title / description | AMMC/FMM/Emergency desilting of blocked drainage system on jabi, gudu, apo, katampe, airport and one / To enhance good conducive environs within the FCC |
| award `19321` | status / date | active / 2024-06-03 |
| award `19321` | value (NGN) | 213,168,292.50 |
| award `19321` | suppliers | `NG-BPP-73422` Lemaco Engineering Ltd |
| award `19321` | title | Emergency desilting of blocked drainage system on jabi, gudu, apo, katampe, airport and onex abuja (lot3) |
| contract | — | (no contract in this release) |

**Mechanical tests**

| Test | Result |
|---|---|
| Larger award / the same supplier's sibling award from the same buyer | 985.5 |
| Larger award / its budget line in the first release | 233.4 |
| Larger award / its budget line in the latest release | 12.7 |
| Larger award / 1,000 (NGN), for comparison with the sibling award | 210,080,562.80 |
| Dropped-decimal test (larger award against its latest budget) | no (award / 100 = 0.13 x budget) |

## B. Federal Medical Centre, Taraba State

All OCIDs whose latest release names buyer `NG-BPP-BPP-NOC-521027034` and that carry an award, with the award value in the latest release:

| OCID | Releases | Award status | Award value (NGN) | Budget line (NGN) | Supplier ID | Contract |
|---|---|---|---|---|---|---|
| ocds-gyl66f-521027034-000011 | 1 | active | 88,847,642.00 | 120,000,000.00 | NG-BPP- | yes |
| ocds-gyl66f-521027034-000013 | 1 | active | 90,122,355.00 |  | NG-BPP- | yes |
| ocds-gyl66f-521027034-000014 | 1 | active | 91,174,360.00 | 99,000,000.00 | NG-BPP- | yes |
| ocds-gyl66f-521027034-000015 | 1 | active | 216,053,530.32 |  | NG-BPP- | yes |
| ocds-gyl66f-521027034-000016 | 1 | active | 174,000,017,612.91 |  | NG-BPP- | no |
| ocds-gyl66f-521027034-000017 | 1 | active | 491,059,529.87 |  | NG-BPP-30669 | yes |
| ocds-gyl66f-521027034-000018 | 1 | active | 240,721,687.76 |  | NG-BPP- | yes |
| ocds-gyl66f-521027034-000019 | 1 | active | 459,819,854.59 |  | NG-BPP-30671 | yes |
| ocds-gyl66f-521027034-000035 | 1 | active | 96,560,060.00 | 100,000,000.00 | NG-BPP- | no |
| ocds-gyl66f-521027034-000036 | 1 | active | 49,532,888.00 | 60,000,000.00 | NG-BPP-30758 | yes |

Every release of the OCID with the largest award:

**ocds-gyl66f-521027034-000016**, release `45865` (release date 2024-03-26; tags: planning, tender, award)

| Section | Field | Value |
|---|---|---|
| buyer | id / name | `NG-BPP-BPP-NOC-521027034` / FEDERAL MEDICAL CENTRE, TARABA STATE |
| planning | budget | (no budget line in this release) |
| tender | method / details / status | open / Selective Tendering / complete |
| tender | value (NGN) / numberOfTenderers | 174,000,017,612.91 / 2 |
| tender | tender period |  to  |
| tender | title / description | Upgrading of medical facilities in federal medical centre jalingo / Upgrading of medical facilities in federal medical centre jalingo |
| award `8319` | status / date | active / 2022-04-01 |
| award `8319` | value (NGN) | 174,000,017,612.91 |
| award `8319` | suppliers | `NG-BPP-` L.B. ATAKE NIG. LTD |
| award `8319` | title | Upgrading of medical facilities in federal medical centre jalingo |
| contract | — | (no contract in this release) |

## C. HADEJIA-JAMAÄ»ARE RBDA

Raw bytes of the buyer name: `b'HADEJIA-JAMA\xc3\x84\xc2\xbbARE RBDA'`. The bytes `C3 84 C2 BB` are the UTF-8 encoding of the characters `Ä»`, which are themselves the UTF-8 bytes of `Ļ` read as Latin-1 (double encoding). The name is kept exactly as published.

Active awards of `NG-BPP-BPP-NOC-252041001` whose value is more than ten times the budget line in the same (latest) release:

| OCID | Releases | Budget (NGN) | Award (NGN) | Award / budget | Dropped-decimal test | Implementation transactions, summed (NGN) | Tenderers | Supplier |
|---|---|---|---|---|---|---|---|---|
| ocds-gyl66f-252041001-000246 | 1 | 100,000,000.00 | 24,749,394,674.00 | 247.5 | no (award / 100 = 2.47 x budget) | 87,922,999.64 | 4 | M SULUM NIGERIA LIMITED |
| ocds-gyl66f-252041001-000194 | 1 | 285,000,000.00 | 22,761,273,572.00 | 79.9 | yes (award / 100 = 0.80 x budget) | 145,171,216.01 | 5 | Mellon De Company International Ltd |
| ocds-gyl66f-252041001-000192 | 1 | 285,000,000.00 | 15,606,941,602.00 | 54.8 | yes (award / 100 = 0.55 x budget) | 38,277,914.40 | 4 | Potenzia Seed Ltd |
| ocds-gyl66f-252041001-000254 | 1 | 99,078,205.79 | 9,907,820,579.00 | 100.0 | yes (award / 100 = 1.00 x budget) | 14,065,865.00 | 5 | QUADRAPPLE CONSTRUCTION OF COMPANY LIMI… |
| ocds-gyl66f-252041001-000196 | 1 | 30,000,000.00 | 3,234,144,865.00 | 107.8 | yes (award / 100 = 1.08 x budget) | 24,000,000.00 | 5 | Dumba Business Solution Limited |
| ocds-gyl66f-252041001-000198 | 1 | 14,250,000.00 | 2,933,169,750.00 | 205.8 | no (award / 100 = 2.06 x budget) | 14,199,754.63 | 5 | Mai Ulu Nigeria Limited |
| ocds-gyl66f-252041001-000173 | 1 | 40,000,000.00 | 2,244,739,750.00 | 56.1 | yes (award / 100 = 0.56 x budget) | 22,372,147.50 | 5 | Princes Glam KN Ltd |
| ocds-gyl66f-252041001-000139 | 1 | 19,000,000.00 | 249,071,329.50 | 13.1 | no (award has a fractional part) | 19,000,000.00 | 5 | KYE BUILDERS & INVESTMENT LTD |
| ocds-gyl66f-252041001-000209 | 1 | 4,750,000.00 | 248,048,385.33 | 52.2 | no (award has a fractional part) | 37,207,257.79 | 5 | AMHO NIG LTD |

Awards passing the dropped-decimal test: 5 of 9, NGN 53.75bn of NGN 81.93bn. Transaction values are shown for context only; their meaning is unresolved (DQ-12) and they are never summed in a metric.

Full record of the largest award:

**ocds-gyl66f-252041001-000246**, release `10797` (release date 2021-06-24; tags: planning, tender, award, contract, implementation)

| Section | Field | Value |
|---|---|---|
| buyer | id / name | `NG-BPP-BPP-NOC-252041001` / HADEJIA-JAMAÄ»ARE RBDA |
| planning | budget amount (NGN) | 100,000,000.00 |
| planning | budget projectID / project | 56649 / FANDA/HAMDULLAHI/HUNGU EROSION CONTROL AT ALBASU FEDERAL CONSTITUENCY KANO STATE |
| planning | budget description | FANDA/HAMDULLAHI/HUNGU EROSION CONTROL AT ALBASU FEDERAL CONSTITUENCY KANO STATE |
| tender | method / details / status | open / Selective Tendering / complete |
| tender | value (NGN) / numberOfTenderers | 24,749,394,674.00 / 4 |
| tender | tender period |  to  |
| tender | title / description | Invitation to Tender / Fanda/Hamdullahi/Hungu Erosion Control at Albasu Federal Constituency, Kano State |
| award `2177` | status / date | active /  |
| award `2177` | value (NGN) | 24,749,394,674.00 |
| award `2177` | suppliers | `NG-BPP-BPP-CI-4364` M SULUM NIGERIA LIMITED |
| award `2177` | title | Contract for the Award for the FANDA/HAMDULLAHI/HUNGU EROSION CONTROL AT ALBASU FEDERAL CONSTITUENCY KANO STA… |
| contract `2133` | status / date signed | active /  |
| contract `2133` | value (NGN) | 24,749,394,674.00 |
| contract `2133` | title | Fanda/Hamdullahi/Hungu Erosion Control at Albasu Federal Constituency, Kano State |
| contract `2133` | implementation | 1 transaction(s), values summed 87,922,999.64; 2 milestone(s) |

## D. Release dates (evidence for proposed correction C-12)

| Measure | Value |
|---|---|
| Package `publishedDate` | 2021-05-03T22:44:00Z |
| Releases | 108,277 |
| Distinct release `date` values | 9,786 |
| Releases whose `date` equals the package `publishedDate` | 786 |
| Earliest / latest release `date` | 2021-05-03T22:44:00Z / 2026-07-29T11:17:00Z |
| Releases dated 2021 | 18,462 |
| Releases dated 2022 | 155 |
| Releases dated 2023 | 5,824 |
| Releases dated 2024 | 58,313 |
| Releases dated 2025 | 25,152 |
| Releases dated 2026 | 371 |
| OCIDs with more than one release | 6,280 |
| ... where a release with a lower integer ID has a later date | 0 |

2021-05-03 is the package metadata date, not the date of every release. No metric uses the release date (timing metrics use event dates; the snapshot orders releases by integer release ID).

## E. Award-to-budget ratios near 100 and near 1,000 (sizing for proposed issue DQ-21)

Read-only query on `analytics.vw_budget_award_comparison` (15,574 comparable OCIDs). Phase 8 script 03 RS10 tested only the ratio near 1,000.

| ratio_group | ocids | whole_naira_awards | award_ngn_bn | entities |
|---|---|---|---|---|
| ratio 900 to 1,100 | 9 | 5 | 1.1 | 6 |
| ratio 90 to 110 | 29 | 24 | 203.3 | 19 |
| other ratio above 10 | 189 | 96 | 1,335.8 | 52 |
| ratio 10 or below | 15,347 | 8,902 | 1,551.4 | 259 |

Whole-naira awards are common at every ratio (see the last row), so a whole-naira amount is not evidence on its own; the dropped-decimal test in §C also needs the award divided by a hundred to land near the budget.

```sql
SELECT CASE WHEN award_to_budget_ratio BETWEEN 90 AND 110 THEN 'ratio 90 to 110'
            WHEN award_to_budget_ratio BETWEEN 900 AND 1100 THEN 'ratio 900 to 1,100'
            WHEN award_to_budget_ratio > 10 THEN 'other ratio above 10'
            ELSE 'ratio 10 or below' END                                   AS ratio_group,
       count(*)                                                            AS ocids,
       count(*) FILTER (WHERE award_value_amount = trunc(award_value_amount)) AS whole_naira_awards,
       round(sum(award_value_amount) / 1e9, 1)                             AS award_ngn_bn,
       count(DISTINCT buyer_id)                                            AS entities
FROM analytics.vw_budget_award_comparison
GROUP BY 1
ORDER BY min(award_to_budget_ratio) DESC
```

---

*Generated by `python/validation/08_verify_source_items.py`. Raw dataset, stg.*, core.* and analytics.* not modified.*
