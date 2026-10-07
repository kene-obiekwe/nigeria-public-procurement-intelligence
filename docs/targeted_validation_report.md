# NOCOPO Dataset — Targeted Validation Report

> **Project:** Nigeria Public Procurement Intelligence  
> **Script:** `python/profiling/02_targeted_validation.py`  
> **Run date:** 2026-08-16 10:24:14  
> **Phase:** 2 — Targeted follow-up validation  
> **Raw data is READ-ONLY. All figures derived directly from the dataset.**

This report addresses specific anomalies and internal inconsistencies identified in the
initial profiling report (`docs/data_profiling_report.md`). All statistics are freshly
calculated from the raw source file.


---

## 1. OCID / Release Count Reconciliation

### 1.1 Corrected Core Metrics

| Metric | Value |
|--------|-------|
| Total releases | 108,277 |
| Unique OCIDs (all) | 98,866 |
| Null OCIDs | 0 |
| Non-null unique OCIDs | 98,866 |
| OCIDs appearing exactly once | 92,586 |
| **OCIDs appearing more than once** | **6,280** |
| Excess releases (sum of (count-1) for repeated OCIDs) | 9,411 |
| Maximum releases for a single OCID | 74 |
| Unique release IDs | 108,277 |

### 1.2 Distribution of Release Counts per OCID

| Releases per OCID | Number of OCIDs |
|-------------------|----------------|
| 1 | 92,586 |
| 2 | 4,760 |
| 3 | 879 |
| 4 | 326 |
| 5 | 158 |
| 6 | 55 |
| 7 | 39 |
| 8 | 13 |
| 9 | 8 |
| 10 | 17 |
| 11 | 4 |
| 12 | 1 |
| 13 | 3 |
| 14 | 4 |
| 15 | 2 |
| 16 | 3 |
| 17 | 1 |
| 19 | 2 |
| 22 | 1 |
| 25 | 1 |
| 29 | 1 |
| 57 | 1 |
| 74 | 1 |

### 1.3 Top 10 Most-Released OCIDs

| OCID | Number of releases |
|------|--------------------|
| `ocds-gyl66f-517021020-000050` | 74 |
| `ocds-gyl66f-521027049-000011` | 57 |
| `ocds-gyl66f-521027009-000020` | 29 |
| `ocds-gyl66f-521049003-000015` | 25 |
| `ocds-gyl66f-437001002-000177` | 22 |
| `ocds-gyl66f-521027024-000087` | 19 |
| `ocds-gyl66f-521027014-000502` | 19 |
| `ocds-gyl66f-521027009-000033` | 17 |
| `ocds-gyl66f-535004001-000014` | 16 |
| `ocds-gyl66f-521027026-000058` | 16 |

### 1.4 Resolution of the 6,280 vs 9,411 Discrepancy

The initial profiling report contained two conflicting figures:

- **Section 2** (OCID Analysis table): reported `6,280` OCIDs appearing more than once.
- **Section 13** (Data-Quality Issues summary): stated `9,411 OCIDs appear in >1 release`.

**Both figures were incorrect as stated.** The correct figure, recalculated directly from the raw dataset, is:

**6,280 OCIDs appear in more than one release.**

**Explanation of the original error:**

The Section 2 figure (`6,280`) correctly counts OCIDs with release count > 1.
The Section 13 figure (`9,411`) was a copy-paste error from an earlier, unfixed version of
the profiling script. It was never recalculated after the script was corrected and re-run.
Section 13 was written before the final script run and was not updated to reflect the
corrected output. **Section 13 contains a reporting error; Section 2 is correct.**

The confirmed correct metrics are:
- **6,280 OCIDs** appear in more than one release (i.e., multi-release procurement processes).
- **9,411 excess releases** exist beyond the first release per repeated OCID.
- **92,586 OCIDs** have exactly one release.

> **CONFIRMED FACT:** Total releases: 108,277. Unique OCIDs: 98,866. OCIDs with >1 release: 6,280. Excess releases: 9,411.

> **PRELIMINARY INTERPRETATION:** The repeated OCIDs represent procurement processes with multiple lifecycle stages captured as separate OCDS releases. This is standard OCDS 1.1 behaviour, not duplication. The maximum of 74 releases for one OCID warrants closer inspection to confirm this is legitimate lifecycle history and not a data loading artefact.

> **DATA-QUALITY ISSUE:** Section 13 of the initial profiling report (`docs/data_profiling_report.md`) contained a stale figure of 9,411 for repeated OCIDs. The correct figure is 6,280. The profiling report should be regenerated or annotated.

> **RECOMMENDED FUTURE TREATMENT:** Retain all releases. The release/version modelling strategy (Phase 3 decision) must specify how repeated OCIDs are handled before monetary aggregation to avoid double-counting.

---

## 2. numberOfTenderers — Outlier Inspection and Missingness Verification

### 2.1 Corrected Missingness Figures

| Metric | Value |
|--------|-------|
| Tender releases | 18,408 |
| numberOfTenderers present (non-null) | 18,408 (100.0%) |
| numberOfTenderers null/missing | 0 (0.0%) |
| numberOfTenderers = 0 (zero) | 0 |

> **CONFIRMED FACT:** numberOfTenderers is present (non-null) in all 18,408 tender releases. The initial profiling report was correct on this point — there are 0 missing values.

### 2.2 Distribution Statistics

| Statistic | Value |
|-----------|-------|
| Count | 18,408 |
| Minimum | 1 |
| Q1 (25th percentile) | 1.0 |
| Median | 2.0 |
| Q3 (75th percentile) | 4.0 |
| 95th percentile | 9.0 |
| 99th percentile | 24.0 |
| Maximum | 90865 |
| Mean | 28.3 |
| Count > 100 | 79 |
| Count > 500 | 70 |
| Count > 1,000 | 65 |

### 2.3 Extreme Record Inspection (numberOfTenderers > 1,000)

**65 release(s) with numberOfTenderers > 1,000:**

**OCID:** `ocds-gyl66f-231001001-001187`  
**Release ID:** `14014`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Supply of 1No Toyota Prado SUV, VX V6, Leather Seat (Automatic Transmission) for Senior Special Advi  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 41,058,550.00  
**numberOfTenderers:** **5,678**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001188`  
**Release ID:** `14084`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Supply and Installation of 300 Nos Extension Box (APC) and 100Nos UPS(2.2KVA)  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 9,975,000.00  
**numberOfTenderers:** **6,759**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001190`  
**Release ID:** `14086`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Supply of Office Items  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 9,570,135.00  
**numberOfTenderers:** **2,341**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001192`  
**Release ID:** `14088`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Supply of Photocopying Papers  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 9,922,500.00  
**numberOfTenderers:** **6,758**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001197`  
**Release ID:** `14101`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Supplies of Stores Materials  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 9,705,837.00  
**numberOfTenderers:** **6,759**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001202`  
**Release ID:** `14106`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Production and Airing of Special Video Documentaries on Ilorin Jebba Mokwa Road Project and Nnamdi A  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 12,574,100.00  
**numberOfTenderers:** **3,480**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001205`  
**Release ID:** `14203`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** DUALISATION OF KANO-KATSINA ROAD FROM KANO AIRPORT ROUNDABOUT TO DAWANAU ROUNDABOUT (ADDITIONAL ONE  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 980,000,000.00  
**numberOfTenderers:** **65,432**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001206`  
**Release ID:** `14205`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** REHABILITATION OF KONTAGORA - BANGI ROAD, NIGER STATE  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 245,046,060.00  
**numberOfTenderers:** **6,543**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001207`  
**Release ID:** `14207`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** REHABILITATION OF THE OUTER MARINA ROAD IN LAGOS STATE  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 204,205,050.00  
**numberOfTenderers:** **6,432**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001208`  
**Release ID:** `14208`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** REHABILITATION OF IRRUA - IBORE, AFUDA, UDOMI - OHE ROAD AND DRAINS EDO STATE  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 163,364,040.00  
**numberOfTenderers:** **5,673**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001233`  
**Release ID:** `14234`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** REHABILITATION OF UMUAHIA (IKWUANO)-IKOT EKPENE ROAD: UMUAHIAUMUDIKE IN ABIA STATE C/NO.6562  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 273,540,000.00  
**numberOfTenderers:** **6,759**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001252`  
**Release ID:** `14346`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Provision of Security Services in Ministry Headquarters, Mabushi Abuja  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 19,260,000.00  
**numberOfTenderers:** **1,238**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001253`  
**Release ID:** `14361`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Insurance, Registration and Tracking 2Nos of Toyota Prado Jeep, 2Nos Toyota Hilux  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 8,100,000.00  
**numberOfTenderers:** **4,532**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001254`  
**Release ID:** `14367`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Engagement of Media Consultant for the Production of Video Documentary on the ''Road Signage and Lan  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 19,450,200.00  
**numberOfTenderers:** **90,865**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001255`  
**Release ID:** `14368`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Production of Video Documentaries (6) of the Key Projects of the Federal Ministry of Works and Housi  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 82,650,000.00  
**numberOfTenderers:** **3,876**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001256`  
**Release ID:** `14370`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Production of Visual Content Development and Digital Documentary for the Federal Ministry of Works H  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 1,260,000,000.00  
**numberOfTenderers:** **2,675**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001259`  
**Release ID:** `14381`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Erosion Control and Road Rehabilitation along Adeshina Street, Iwo Area, Ilesha, Osun State  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 100,000,000.00  
**numberOfTenderers:** **7,650**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001265`  
**Release ID:** `14388`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** REHABILITATION OF ZARIA-HUNKUYI-KAFUR-GIDAN MUTUN DAYA ROAD IN KADUNA/KANO STATES  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 367,569,090.00  
**numberOfTenderers:** **7,654**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001270`  
**Release ID:** `14393`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Construction of Road Network, Drainage, Culvert and Asphalt Overlay at City College Leha-Shebwokpoma  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 100,750,000.00  
**numberOfTenderers:** **3,672**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001276`  
**Release ID:** `14408`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Construction of 2 Blocks of 3 Classroom at Ganisa Village Primary School, Mbulo District, Jada LGA,  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 28,000,000.00  
**numberOfTenderers:** **7,509**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001280`  
**Release ID:** `14419`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Reconstruction/Rehabilitation of Badly affected 33KV Transmission Line from Daura Substation to Gwiw  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 94,500,000.00  
**numberOfTenderers:** **1,683**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001283`  
**Release ID:** `14424`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Supply and Installation of 25Nos. Solar Street Lights in Federal College of Education (Tech.), Gombe  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 27,500,000.00  
**numberOfTenderers:** **6,759**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001286`  
**Release ID:** `14430`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Construction of Roads and Drains in Umana-Ndiagu-Agba, Annir/Awgu/Oji River, Enugu State  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 206,640,000.00  
**numberOfTenderers:** **2,590**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001288`  
**Release ID:** `14437`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Rehabilitation of Classroom Block at Igwebuike Primary School, Ibeme Isiala Mbano LGA, Imo North Sen  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 18,522,000.00  
**numberOfTenderers:** **6,743**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001293`  
**Release ID:** `14445`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Construction of Maternity Health Centre at Damaturu, Yobe State  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 14,064,681.00  
**numberOfTenderers:** **2,765**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001296`  
**Release ID:** `14451`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Construction of 1No Maternity Health Centre at Abokan-Huldar Asibiti, Hadejia, Jigawa State  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 16,000,000.00  
**numberOfTenderers:** **3,289**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001298`  
**Release ID:** `14456`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Erosion Control in Zone D Apo Legislative Quarters Behind Anglican Girls Secondary School, Apo, FCT  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 397,400,000.00  
**numberOfTenderers:** **1,754**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001300`  
**Release ID:** `14458`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Construction of Motorised Borehole at Eddo in Muye/Egba Ward Niger State  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 10,187,100.00  
**numberOfTenderers:** **3,410**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001302`  
**Release ID:** `14460`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Provision of 1No Motorised Borehole at Abule Iroko Village, Ogun State  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 11,000,000.00  
**numberOfTenderers:** **1,197**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001305`  
**Release ID:** `14463`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Construction of Motorised Borehole at Bida Local Government (BanyagiDaracita Bye-Pass)  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 10,187,100.00  
**numberOfTenderers:** **9,064**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001306`  
**Release ID:** `14464`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Construction of Motorised Borehole at Umuduruzo Village in Nwanegele LGA, Imo State  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 10,172,810.03  
**numberOfTenderers:** **8,902**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001311`  
**Release ID:** `14469`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Construction of Block of 3 Classroom at LGEA Primary School, Anchim Centre, Oju LGA, Benue State  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 14,000,000.00  
**numberOfTenderers:** **5,000**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001313`  
**Release ID:** `14471`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Provision and Installation of 20 Poles of all in One Solar Street Lighting in Kaduna State  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 18,500,000.00  
**numberOfTenderers:** **3,421**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001317`  
**Release ID:** `14476`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Construction of a Block of Three Classroom in Community Secondary School, Finima, Bonny LGA, Rivers  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 12,965,400.00  
**numberOfTenderers:** **5,234**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001340`  
**Release ID:** `15452`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Construction of 1No. Solar Powered Borehole in Fakuwa, Kankia LGA, Katsina Stat  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 11,666,666.00  
**numberOfTenderers:** **1,432**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001344`  
**Release ID:** `15459`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Construction of 1No. Solar Powered Borehole in Galtimari Ward, Maiduguri, Borno State  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 11,666,666.00  
**numberOfTenderers:** **6,759**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001345`  
**Release ID:** `15460`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Construction of 1No. Solar Powered Borehole in Takatsaba in Suletankarkar LGA, Jigawa State  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 11,666,666.00  
**numberOfTenderers:** **4,446**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001348`  
**Release ID:** `15466`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:**  Construction of Solar Powered Borehole with overhead tank at St. Peters Anglican Secondary School,  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 13,891,500.00  
**numberOfTenderers:** **5,432**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001351`  
**Release ID:** `15469`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Construction of Erosion/Gully Controlled at Computer profession Registration Council of Nigeria, FCT  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 92,610,000.00  
**numberOfTenderers:** **1,258**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001354`  
**Release ID:** `15472`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Provision of 500KVA Transformers at Kusada Massallacin Yan Izala, Emiworo, Wushishi Town, Niger Stat  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 13,000,000.00  
**numberOfTenderers:** **6,759**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001356`  
**Release ID:** `15474`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Construction of a block of 3 Classrooms at Isaba Baptist School 3, Eruwa, ibarapa East LGA, Ibarapa  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 12,965,000.00  
**numberOfTenderers:** **6,759**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001357`  
**Release ID:** `15475`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Supply and Installation of 15 poles solar street lights at various locations in Ogbaru, Anambra Stat  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 17,275,747.00  
**numberOfTenderers:** **4,446**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001361`  
**Release ID:** `15479`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Renovation of Community Council Halls at Wuese, Gbogbo, Korinya in Konishisha LGA, Benue state  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 69,457,500.00  
**numberOfTenderers:** **6,759**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001363`  
**Release ID:** `15482`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Provision of 227Nos. Integrated Solar Street Lights in Kebbi North Senatorial District, Kebbi State  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 249,700,000.00  
**numberOfTenderers:** **6,000**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001365`  
**Release ID:** `15486`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Installation of Solar Power Supply to Gwagwalada, Kwali, Abaji, Bwari and Kuje Area Councils, FCT  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 250,000,000.00  
**numberOfTenderers:** **6,759**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001368`  
**Release ID:** `15489`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Provision of 200Nos Integrated Solar Street Lights in Kebbi Central Senatorial District, Kebbi State  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 220,000,000.00  
**numberOfTenderers:** **3,480**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001370`  
**Release ID:** `15492`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Construction of 1No. Solar Powered Borehole at Iseyin Area of Oke-Ogun, Oyo State  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 11,666,666.00  
**numberOfTenderers:** **6,759**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001384`  
**Release ID:** `15532`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Supply and Installation of 151Nos Solar Street Lights in in Fantuo, Ogbolomabiri, Nembe LGA and Otua  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 165,855,000.00  
**numberOfTenderers:** **6,759**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001385`  
**Release ID:** `15535`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Construction of 5Nos Deep Well Boreholes in Hausari Ward, Kaliari Ward Government College, Universit  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 85,000,000.00  
**numberOfTenderers:** **4,446**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001387`  
**Release ID:** `15538`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Construction of 5Nos Deep Well Boreholes in Diginsa Village, Birinwa LGA, Galadi Village, Maigatari  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 80,000,000.00  
**numberOfTenderers:** **6,000**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001391`  
**Release ID:** `15543`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Provision of 1No. Motorised Borehole at Abule Iroko Village, Ogun State  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 11,000,000.00  
**numberOfTenderers:** **5,678**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001392`  
**Release ID:** `15545`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Provision of 500KVA Transformer at Abogunde, Ogbomosho North LGA, Oyo State  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 13,000,000.00  
**numberOfTenderers:** **5,678**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001394`  
**Release ID:** `15548`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Construction of 1No. Solar Powered Borehole in Old Dispensary, Jakusko LGA, Yobe State  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 11,666,666.00  
**numberOfTenderers:** **9,064**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001395`  
**Release ID:** `15549`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Construction of 1No. Solar Powered Borehole in Azbak Village, Bade West LGA, Yobe State  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 11,666,666.00  
**numberOfTenderers:** **6,000**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001396`  
**Release ID:** `15551`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Provision of Solar Street in Babura/Garki Federal Constituency, Jigawa State  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 92,610,000.00  
**numberOfTenderers:** **6,759**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001397`  
**Release ID:** `15554`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Construction of 1No. Solar powered Borehole in Sabaru, Kusada LGA, Katsina State  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 11,666,666.00  
**numberOfTenderers:** **4,328**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001403`  
**Release ID:** `15575`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Construction of 1 Block of 3 classroom at Almajir School, Chief Imam House, Saho-Rami Kontagora LGA,  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 14,000,000.00  
**numberOfTenderers:** **1,980**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001404`  
**Release ID:** `15576`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Construction of 11Nos Solar Powered Boreholes in Adamawa, Bauchi, Yobe and Borno State, North East G  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 127,906,966.00  
**numberOfTenderers:** **3,410**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001407`  
**Release ID:** `15580`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Construction of 11Nos Solar Powered Boreholes in Osun, Oyo and Ogun States South West Geo-Political  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 127,906,966.00  
**numberOfTenderers:** **2,590**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001408`  
**Release ID:** `15583`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Construction of 10Nos Solar Powered Boreholes in Kwara, Kogi, Plateau and Nasarawa States North Cent  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 116,279,060.00  
**numberOfTenderers:** **2,765**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001411`  
**Release ID:** `15586`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Construction of 11Nos Solar Powered Boreholes in Katsina, Kaduna, Kebbi States North West Geo-Politi  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 127,906,966.00  
**numberOfTenderers:** **1,345**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001413`  
**Release ID:** `15588`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Construction of Roads, Drains and Bridge in Tsanyawa Gurun, Nasarawa Road, Tsanyawa, Kano State  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 145,657,098.76  
**numberOfTenderers:** **2,765**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001416`  
**Release ID:** `15591`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Provision of 1No. Motorised Borehole at Yenogoa, Bayelsa State  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 11,000,000.00  
**numberOfTenderers:** **2,341**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001418`  
**Release ID:** `15594`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Provision of 1No. Motorised Borehole at Balanga Village, Balanga LGA, Gombe State  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 11,000,000.00  
**numberOfTenderers:** **2,675**  
**Tender status:** active  

**OCID:** `ocds-gyl66f-231001001-001420`  
**Release ID:** `15596`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Tender title:** Construction of 5Nos Deepwell Boreholes in Ukpagaa, Ogoja LGA, Ibi, Ogoja LGA, Yache, Yala LGA, Ntan  
**Procurement method:** open / National Competitive Bidding  
**Tender value (NGN):** 83,350,000.00  
**numberOfTenderers:** **1,683**  
**Tender status:** active  


> **DATA-QUALITY ISSUE:** numberOfTenderers maximum of 90,865 is implausibly high for a standard procurement process. The 99th percentile is 24.0, indicating this is a severe outlier.

> **PRELIMINARY INTERPRETATION:** The extreme value may reflect a data-entry error, a misused field (e.g., a registration count rather than a tender submission count), or a framework agreement with open registration. Given the magnitude, a data-entry error is the most probable explanation.

> **RECOMMENDED FUTURE TREATMENT:** FLAG this record. Exclude from any statistical analysis of competition levels (e.g., mean, percentile comparisons). Retain in the dataset with a data-quality flag. Do not impute a replacement value without source evidence.

---

## 3. Extreme Budget Value (₦6.5 Trillion) Inspection

### 3.1 Budget Distribution Context

| Statistic | Value (NGN) |
|-----------|-------------|
| Count | 106,628 |
| Minimum | 0.00 |
| Median | 55,274,250.50 |
| 95th percentile | 2,135,558,761.00 |
| 99th percentile | 16,500,000,000.00 |
| Maximum | 6,500,000,000,000.00 |
| Count > ₦100 billion | 144 |
| Count > ₦500 billion | 37 |
| Count > ₦1 trillion | 32 |

### 3.2 Records with Budget ≥ ₦1 Trillion

**OCID:** `ocds-gyl66f-231020001-000611`  
**Release ID:** `27806`  
**Buyer:** TRANSMISSION COMPANY OF NIGERIA (`NG-BPP-BPP-NOC-231020001`)  
**Budget amount (NGN):** 6,500,000,000,000.00  
**Budget description:** Supply of Em,ergency  Restoration System(ERS)  for 330kV and 132kV  Transmission Lines  
**Budget project:** Supply of Em,ergency  Restoration System(ERS)  for 330kV and 132kV  Transmission Lines  
**Budget project ID:** 176294  
**Tender value:** not present  
**Tender title:** None  
**Procurement method details:** None  
**Tags:** ['planning']  

**OCID:** `ocds-gyl66f-517021008-000025`  
**Release ID:** `39327`  
**Buyer:** UNIVERSITY OF CALABAR (`NG-BPP-BPP-NOC-517021008`)  
**Budget amount (NGN):** 1,424,077,802,000.00  
**Budget description:** SUPPLY OF REFRIGERATOR  
**Budget project:** SUPPLY OF REFRIGERATOR  
**Budget project ID:** 124527  
**Tender value:** not present  
**Tender title:** None  
**Procurement method details:** None  
**Tags:** ['planning']  

**OCID:** `ocds-gyl66f-521003001-000694`  
**Release ID:** `40414`  
**Buyer:** NATIONAL PRIMARY HEALTH CARE DEVELOPMENT AGENCY (`NG-BPP-BPP-NOC-521003001`)  
**Budget amount (NGN):** 3,023,863,387,467.00  
**Budget description:** Procurement of Vaccines  
**Budget project:** Supply of ACYM-135 Hajj Vaccines for Niger State  
**Budget project ID:** 175434  
**Tender value:** not present  
**Tender title:** None  
**Procurement method details:** None  
**Tags:** ['planning']  

**OCID:** `ocds-gyl66f-521003001-000695`  
**Release ID:** `40415`  
**Buyer:** NATIONAL PRIMARY HEALTH CARE DEVELOPMENT AGENCY (`NG-BPP-BPP-NOC-521003001`)  
**Budget amount (NGN):** 3,023,863,387,467.00  
**Budget description:** Procurement of Hajj Vaccines  
**Budget project:** Supply of ACYM-135 Hajj Vaccines for Kogi State  
**Budget project ID:** 175438  
**Tender value:** not present  
**Tender title:** None  
**Procurement method details:** None  
**Tags:** ['planning']  

**OCID:** `ocds-gyl66f-521003001-000696`  
**Release ID:** `40416`  
**Buyer:** NATIONAL PRIMARY HEALTH CARE DEVELOPMENT AGENCY (`NG-BPP-BPP-NOC-521003001`)  
**Budget amount (NGN):** 3,023,863,387,467.00  
**Budget description:** Procurement of Hajj Vaccines  
**Budget project:** Supply of ACYM-135 Hajj Vaccines for Kwara State  
**Budget project ID:** 175474  
**Tender value:** not present  
**Tender title:** None  
**Procurement method details:** None  
**Tags:** ['planning']  

**OCID:** `ocds-gyl66f-521003001-000697`  
**Release ID:** `40417`  
**Buyer:** NATIONAL PRIMARY HEALTH CARE DEVELOPMENT AGENCY (`NG-BPP-BPP-NOC-521003001`)  
**Budget amount (NGN):** 3,023,863,387,467.00  
**Budget description:** Procurement of Hajj Vaccines  
**Budget project:** Supply of ACYM-135 Hajj Vaccines for Bauchi State  
**Budget project ID:** 175505  
**Tender value:** not present  
**Tender title:** None  
**Procurement method details:** None  
**Tags:** ['planning']  

**OCID:** `ocds-gyl66f-521003001-000698`  
**Release ID:** `40418`  
**Buyer:** NATIONAL PRIMARY HEALTH CARE DEVELOPMENT AGENCY (`NG-BPP-BPP-NOC-521003001`)  
**Budget amount (NGN):** 3,023,863,387,467.00  
**Budget description:** Procurement of Hajj Vaccines  
**Budget project:** Supply of ACYM-135 Hajj Vaccines for Borno State  
**Budget project ID:** 175764  
**Tender value:** not present  
**Tender title:** None  
**Procurement method details:** None  
**Tags:** ['planning']  

**OCID:** `ocds-gyl66f-521003001-000699`  
**Release ID:** `40419`  
**Buyer:** NATIONAL PRIMARY HEALTH CARE DEVELOPMENT AGENCY (`NG-BPP-BPP-NOC-521003001`)  
**Budget amount (NGN):** 3,023,863,387,467.00  
**Budget description:** Procurement of Hajj Vaccines  
**Budget project:** Supply of ACYM-135 Hajj Vaccines for Adamawa State  
**Budget project ID:** 175767  
**Tender value:** not present  
**Tender title:** None  
**Procurement method details:** None  
**Tags:** ['planning']  

**OCID:** `ocds-gyl66f-521003001-000700`  
**Release ID:** `40420`  
**Buyer:** NATIONAL PRIMARY HEALTH CARE DEVELOPMENT AGENCY (`NG-BPP-BPP-NOC-521003001`)  
**Budget amount (NGN):** 3,023,863,387,467.00  
**Budget description:** Procurement of Hajj Vaccines  
**Budget project:** Supply of ACYM-135 Hajj Vaccines for Kano State  
**Budget project ID:** 175770  
**Tender value:** not present  
**Tender title:** None  
**Procurement method details:** None  
**Tags:** ['planning']  

**OCID:** `ocds-gyl66f-521003001-000701`  
**Release ID:** `40421`  
**Buyer:** NATIONAL PRIMARY HEALTH CARE DEVELOPMENT AGENCY (`NG-BPP-BPP-NOC-521003001`)  
**Budget amount (NGN):** 3,023,863,387,467.00  
**Budget description:** Procurement of Hajj Vaccines  
**Budget project:** Supply of ACYM-135 Hajj Vaccines for Kaduna  
**Budget project ID:** 175771  
**Tender value:** not present  
**Tender title:** None  
**Procurement method details:** None  
**Tags:** ['planning']  

**OCID:** `ocds-gyl66f-521003001-000702`  
**Release ID:** `40422`  
**Buyer:** NATIONAL PRIMARY HEALTH CARE DEVELOPMENT AGENCY (`NG-BPP-BPP-NOC-521003001`)  
**Budget amount (NGN):** 3,023,863,387,467.00  
**Budget description:** Procurement of Hajj Vaccines  
**Budget project:** Supply of ACYM-135 Hajj Vaccines for Sokoto State  
**Budget project ID:** 175772  
**Tender value:** not present  
**Tender title:** None  
**Procurement method details:** None  
**Tags:** ['planning']  

**OCID:** `ocds-gyl66f-521003001-000703`  
**Release ID:** `40423`  
**Buyer:** NATIONAL PRIMARY HEALTH CARE DEVELOPMENT AGENCY (`NG-BPP-BPP-NOC-521003001`)  
**Budget amount (NGN):** 3,023,863,387,467.00  
**Budget description:** Procurement of Hajj Vaccines  
**Budget project:** Supply of ACYM-135 Hajj Vaccines for Katsina State  
**Budget project ID:** 175773  
**Tender value:** not present  
**Tender title:** None  
**Procurement method details:** None  
**Tags:** ['planning']  

**OCID:** `ocds-gyl66f-521003001-000704`  
**Release ID:** `40424`  
**Buyer:** NATIONAL PRIMARY HEALTH CARE DEVELOPMENT AGENCY (`NG-BPP-BPP-NOC-521003001`)  
**Budget amount (NGN):** 3,023,863,387,467.00  
**Budget description:** Procurement of Hajj Vaccines  
**Budget project:** Supply of ACYM-135 Hajj Vaccines for Enugu State  
**Budget project ID:** 175775  
**Tender value:** not present  
**Tender title:** None  
**Procurement method details:** None  
**Tags:** ['planning']  

**OCID:** `ocds-gyl66f-521003001-000705`  
**Release ID:** `40425`  
**Buyer:** NATIONAL PRIMARY HEALTH CARE DEVELOPMENT AGENCY (`NG-BPP-BPP-NOC-521003001`)  
**Budget amount (NGN):** 3,023,863,387,467.00  
**Budget description:** Procurement of Hajj Vaccines  
**Budget project:** Supply of ACYM-135 Hajj Vaccines for Ebonyi State  
**Budget project ID:** 175776  
**Tender value:** not present  
**Tender title:** None  
**Procurement method details:** None  
**Tags:** ['planning']  

**OCID:** `ocds-gyl66f-521003001-000706`  
**Release ID:** `40426`  
**Buyer:** NATIONAL PRIMARY HEALTH CARE DEVELOPMENT AGENCY (`NG-BPP-BPP-NOC-521003001`)  
**Budget amount (NGN):** 3,023,863,387,467.00  
**Budget description:** Procurement of Hajj Vaccines  
**Budget project:** Supply of ACYM-135 Hajj Vaccines for Edo State  
**Budget project ID:** 175777  
**Tender value:** not present  
**Tender title:** None  
**Procurement method details:** None  
**Tags:** ['planning']  

**OCID:** `ocds-gyl66f-521003001-000707`  
**Release ID:** `40427`  
**Buyer:** NATIONAL PRIMARY HEALTH CARE DEVELOPMENT AGENCY (`NG-BPP-BPP-NOC-521003001`)  
**Budget amount (NGN):** 3,023,863,387,467.00  
**Budget description:** Procurement of Hajj Vaccines  
**Budget project:** Supply of Hajj Influenza Vaccines for Niger State  
**Budget project ID:** 175779  
**Tender value:** not present  
**Tender title:** None  
**Procurement method details:** None  
**Tags:** ['planning']  

**OCID:** `ocds-gyl66f-521003001-000708`  
**Release ID:** `40428`  
**Buyer:** NATIONAL PRIMARY HEALTH CARE DEVELOPMENT AGENCY (`NG-BPP-BPP-NOC-521003001`)  
**Budget amount (NGN):** 3,023,863,387,467.00  
**Budget description:** Procurement of Hajj Vaccines  
**Budget project:** Supply of Hajj Influenza Vaccines for Kogi State  
**Budget project ID:** 175781  
**Tender value:** not present  
**Tender title:** None  
**Procurement method details:** None  
**Tags:** ['planning']  

**OCID:** `ocds-gyl66f-521003001-000709`  
**Release ID:** `40429`  
**Buyer:** NATIONAL PRIMARY HEALTH CARE DEVELOPMENT AGENCY (`NG-BPP-BPP-NOC-521003001`)  
**Budget amount (NGN):** 3,023,863,387,467.00  
**Budget description:** Procurement of Hajj Vaccines  
**Budget project:** Supply of Hajj Influenza Vaccines for Bauchi State  
**Budget project ID:** 175782  
**Tender value:** not present  
**Tender title:** None  
**Procurement method details:** None  
**Tags:** ['planning']  

**OCID:** `ocds-gyl66f-521003001-000710`  
**Release ID:** `40448`  
**Buyer:** NATIONAL PRIMARY HEALTH CARE DEVELOPMENT AGENCY (`NG-BPP-BPP-NOC-521003001`)  
**Budget amount (NGN):** 3,023,863,387,467.00  
**Budget description:** Procurement of Hajj Vaccines  
**Budget project:** Supply of Hajj InfluenzaVaccines for Borno State  
**Budget project ID:** 175783  
**Tender value:** not present  
**Tender title:** None  
**Procurement method details:** None  
**Tags:** ['planning']  

**OCID:** `ocds-gyl66f-521003001-000711`  
**Release ID:** `40449`  
**Buyer:** NATIONAL PRIMARY HEALTH CARE DEVELOPMENT AGENCY (`NG-BPP-BPP-NOC-521003001`)  
**Budget amount (NGN):** 3,023,863,387,467.00  
**Budget description:** Procurement of Hajj Vaccines  
**Budget project:** Supply of Hajj Influenza Vaccines for Kano State  
**Budget project ID:** 175785  
**Tender value:** not present  
**Tender title:** None  
**Procurement method details:** None  
**Tags:** ['planning']  

**OCID:** `ocds-gyl66f-521003001-000712`  
**Release ID:** `40450`  
**Buyer:** NATIONAL PRIMARY HEALTH CARE DEVELOPMENT AGENCY (`NG-BPP-BPP-NOC-521003001`)  
**Budget amount (NGN):** 3,023,863,387,467.00  
**Budget description:** Procurement of Hajj Vaccines  
**Budget project:** Supply of Hajj Influenza Vaccines for Kaduna  
**Budget project ID:** 175786  
**Tender value:** not present  
**Tender title:** None  
**Procurement method details:** None  
**Tags:** ['planning']  

**OCID:** `ocds-gyl66f-521003001-000713`  
**Release ID:** `40451`  
**Buyer:** NATIONAL PRIMARY HEALTH CARE DEVELOPMENT AGENCY (`NG-BPP-BPP-NOC-521003001`)  
**Budget amount (NGN):** 3,023,863,387,467.00  
**Budget description:** Procurement of Hajj Vaccines  
**Budget project:** Supply of Hajj Influenza Vaccines for Enugu State  
**Budget project ID:** 175787  
**Tender value:** not present  
**Tender title:** None  
**Procurement method details:** None  
**Tags:** ['planning']  

**OCID:** `ocds-gyl66f-521003001-000714`  
**Release ID:** `40452`  
**Buyer:** NATIONAL PRIMARY HEALTH CARE DEVELOPMENT AGENCY (`NG-BPP-BPP-NOC-521003001`)  
**Budget amount (NGN):** 3,023,863,387,467.00  
**Budget description:** Procurement of Hajj Vaccines  
**Budget project:** Supply of Hajj Influenza Vaccines for Edo State  
**Budget project ID:** 175790  
**Tender value:** not present  
**Tender title:** None  
**Procurement method details:** None  
**Tags:** ['planning']  

**OCID:** `ocds-gyl66f-521003001-000715`  
**Release ID:** `40453`  
**Buyer:** NATIONAL PRIMARY HEALTH CARE DEVELOPMENT AGENCY (`NG-BPP-BPP-NOC-521003001`)  
**Budget amount (NGN):** 3,023,863,387,467.00  
**Budget description:** Procurement of Hajj Vaccines  
**Budget project:** Supply of Hajj Influenza Vaccines for Lagos State  
**Budget project ID:** 175791  
**Tender value:** not present  
**Tender title:** None  
**Procurement method details:** None  
**Tags:** ['planning']  

**OCID:** `ocds-gyl66f-231001001-004529`  
**Release ID:** `87917`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Budget amount (NGN):** 5,000,000,000,000.00  
**Budget description:** FEDERATION ACCOUNT  
**Budget project:** CONSTRUCTION OF LAGOS – CALABAR COASTAL ROAD CORRIDOR (PHASE 1; SECTION 1: AHMADU BELLO TO ELEKO VILLAGE AREA IN THE LEKKI PENINSULA (CH.0+000 – CH.47+474; 47.474KM))  
**Budget project ID:** 212956  
**Tender value:** not present  
**Tender title:** None  
**Procurement method details:** None  
**Tags:** ['planning']  

**OCID:** `ocds-gyl66f-231001001-004530`  
**Release ID:** `87922`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Budget amount (NGN):** 5,000,000,000,000.00  
**Budget description:** FEDERATION ACCOUNT  
**Budget project:** CONSTRUCTION OF LAGOS - CALABAR COASTAL HIGHWAY, PHASE 1; SECTION 2 (CH.47+474 - CH.103+308; 55.778KM)  
**Budget project ID:** 212957  
**Tender value:** not present  
**Tender title:** None  
**Procurement method details:** None  
**Tags:** ['planning']  

**OCID:** `ocds-gyl66f-231001001-004154`  
**Release ID:** `88415`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Budget amount (NGN):** 1,969,700,168,910.78  
**Budget description:** Tax Credit investment of the NNPCL and its subsidiaries, NNPC Exploration and Production Limited and  
**Budget project:** Construction of Nembe-Brass Road Phase II B (Ch. 55+900 - Ch.65+900) 10.0km  
**Budget project ID:** 176234  
**Tender value:** not present  
**Tender title:** None  
**Procurement method details:** None  
**Tags:** ['planning']  

**OCID:** `ocds-gyl66f-231001001-004152`  
**Release ID:** `88420`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Budget amount (NGN):** 1,969,700,168,910.78  
**Budget description:** Tax Credit investment of the NNPCL and its subsidiaries, NNPC Exploration and Production Limited and  
**Budget project:** Dualization of Bida - Minna  Road (Section II): Ch.39+500 - Ch.66+328 (26.828km)  
**Budget project ID:** 176232  
**Tender value:** not present  
**Tender title:** None  
**Procurement method details:** None  
**Tags:** ['planning']  

**OCID:** `ocds-gyl66f-231001001-004153`  
**Release ID:** `88422`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Budget amount (NGN):** 1,969,700,168,910.78  
**Budget description:** Tax Credit investment of the NNPCL and its subsidiaries, NNPC Exploration and Production Limited and  
**Budget project:** Construction of Nembe-Brass Road Phase IIA (Ch. 45+900 -Ch.55+900) 10.0km  
**Budget project ID:** 176233  
**Tender value:** not present  
**Tender title:** None  
**Procurement method details:** None  
**Tags:** ['planning']  

**OCID:** `ocds-gyl66f-231001001-004151`  
**Release ID:** `88423`  
**Buyer:** FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS (`NG-BPP-BPP-NOC-231001001`)  
**Budget amount (NGN):** 1,969,700,168,910.78  
**Budget description:** Tax Credit investment of the NNPCL and its subsidiaries, NNPC Exploration and Production Limited and  
**Budget project:** Dualization of Minna- Bida Road (Section I): Ch.0+000 -Ch.39+500 (39.5km)  
**Budget project ID:** 176231  
**Tender value:** not present  
**Tender title:** None  
**Procurement method details:** None  
**Tags:** ['planning']  

**OCID:** `ocds-gyl66f-2-004320`  
**Release ID:** `117395`  
**Buyer:** FEDERAL CAPITAL TERRITORY ADMINISTRATION (`NG-BPP-BPP-NOC-2`)  
**Budget amount (NGN):** 2,034,024,754,474.58  
**Budget description:** Road networks  
**Budget project:** FCTA/STDD/Rehabilitation of Road Networks in Kubwa Extension IIIB FCDA, Owner Occupier  
**Budget project ID:** 168583  
**Tender value:** not present  
**Tender title:** None  
**Procurement method details:** None  
**Tags:** ['planning']  

**OCID:** `ocds-gyl66f-2-005430`  
**Release ID:** `118083`  
**Buyer:** FEDERAL CAPITAL TERRITORY ADMINISTRATION (`NG-BPP-BPP-NOC-2`)  
**Budget amount (NGN):** 2,080,000,000,000.00  
**Budget description:** PROVISION OF SIXTEEN AMBULANCES FOR EIGHT FCTA HOSPITALS  
**Budget project:** HHSS/PROVISION OF SIXTEEN AMBULANCES FOR EIGHT FCTA HOSPITALS  
**Budget project ID:** 287034  
**Tender value:** not present  
**Tender title:** None  
**Procurement method details:** None  
**Tags:** ['planning']  



---

## 4. Extreme Tender/Award Values (₦1.004 Trillion)

### 4.1 Award Distribution Context

| Statistic | Value (NGN) |
|-----------|-------------|
| Count | 17,417 |
| Minimum | 0.00 |
| Median | 33,518,175.23 |
| 95th percentile | 350,000,000.00 |
| 99th percentile | 1,491,506,060.14 |
| Maximum | 1,004,166,666,735.23 |
| Count > ₦100 billion | 4 |
| Count > ₦500 billion | 1 |
| Count > ₦1 trillion | 1 |

**OCIDs with both extreme tender value (≥500B) AND extreme award value (≥500B):** 1

### 4.2 Records with Award ≥ ₦500 Billion

**OCID:** `ocds-gyl66f-2-004675`  
**Release ID:** `117730`  
**Buyer:** FEDERAL CAPITAL TERRITORY ADMINISTRATION (`NG-BPP-BPP-NOC-2`)  
**Tender value (NGN):** 1,004,166,666,735.23  
**Award value (NGN):** 1,004,166,666,735.23  
**Award status:** active  
**Award date:** 2022-08-09T00:00:00Z  
**Supplier(s):** ['M/S Turaki Trading Company Ltd']  
**Tender title:** CONSTRUCTION OF NEW SPECIALISED WAREHOUSEAND STORE IN GWAGWA (WARD3)  
**Procurement method details:** National Competitive Bidding  
**Tags:** ['planning', 'tender', 'award', 'contract']  



---

## 5. Internal Procurement Date Quality

### 5.1 Date Field Classification Summary

| Date field | Total | Valid | Null | Placeholder (2001-01-01 etc.) | Future (2026–2030) | Extreme future (>2030) | Extreme past |
|-----------|-------|-------|------|---------|--------|--------|------|
| `tender_start` | 18,408 | 9,593 | 8,786 | 24 | 5 | 0 | 0 |
| `tender_end` | 18,408 | 9,616 | 8,786 | 0 | 6 | 0 | 0 |
| `award_date` | 17,417 | 14,658 | 2,630 | 119 | 8 | 2 | 0 |
| `contract_signed` | 17,043 | 14,305 | 2,657 | 77 | 4 | 0 | 0 |
| `contract_period_start` | 17,043 | 7,168 | 9,872 | 3 | 0 | 0 | 0 |
| `contract_period_end` | 17,043 | 7,158 | 9,872 | 0 | 13 | 0 | 0 |
| `tender_award_period_end` | 18,408 | 7,158 | 11,237 | 0 | 13 | 0 | 0 |

### 5.2 Valid Date Ranges (excluding placeholders, nulls, extreme values)

| Date field | Earliest valid | Latest valid |
|-----------|---------------|-------------|
| `tender_start` | 2010-07-05 | 2025-10-24 |
| `tender_end` | 2010-08-15 | 2025-12-29 |
| `award_date` | 2001-05-22 | 2025-10-29 |
| `contract_signed` | 2003-07-07 | 2025-12-18 |
| `contract_period_start` | 2002-05-13 | 2025-12-18 |
| `contract_period_end` | 2010-09-30 | 2025-12-27 |
| `tender_award_period_end` | 2010-09-30 | 2025-12-27 |

### 5.3 Sample Extreme Future Dates

**tender_start:**
  - `2029-11-04T00:00:00Z` (year: 2029)
  - `2028-02-01T00:00:00Z` (year: 2028)
  - `2027-02-01T00:00:00Z` (year: 2027)
  - `2026-08-17T00:00:00Z` (year: 2026)
  - `2028-05-08T00:00:00Z` (year: 2028)

**tender_end:**
  - `2029-11-10T00:00:00Z` (year: 2029)
  - `2029-10-10T00:00:00Z` (year: 2029)
  - `2028-03-01T00:00:00Z` (year: 2028)
  - `2027-03-01T00:00:00Z` (year: 2027)
  - `2026-09-21T00:00:00Z` (year: 2026)

**award_date:**
  - `2922-08-26T00:00:00Z` (year: 2922)
  - `2029-10-12T00:00:00Z` (year: 2029)
  - `2033-08-04T00:00:00Z` (year: 2033)
  - `2028-06-05T00:00:00Z` (year: 2028)
  - `2027-06-05T00:00:00Z` (year: 2027)

**contract_signed:**
  - `2028-08-10T00:00:00Z` (year: 2028)
  - `2027-02-03T00:00:00Z` (year: 2027)
  - `2028-04-20T00:00:00Z` (year: 2028)
  - `2026-10-22T00:00:00Z` (year: 2026)

**contract_period_end:**
  - `2027-11-20T00:00:00Z` (year: 2027)
  - `2026-03-09T00:00:00Z` (year: 2026)
  - `2026-05-09T00:00:00Z` (year: 2026)
  - `2026-06-05T00:00:00Z` (year: 2026)
  - `2026-07-01T00:00:00Z` (year: 2026)

**tender_award_period_end:**
  - `2027-11-20T00:00:00Z` (year: 2027)
  - `2026-03-09T00:00:00Z` (year: 2026)
  - `2026-05-09T00:00:00Z` (year: 2026)
  - `2026-06-05T00:00:00Z` (year: 2026)
  - `2026-07-01T00:00:00Z` (year: 2026)

> **DATA-QUALITY ISSUE:** Award dates include at least one value in year 2922, which is almost certainly a data-entry error (likely 2022 miskeyed as 2922). Contract period dates also include extreme future values.

> **DATA-QUALITY ISSUE:** Placeholder dates (2001-01-01) appear in tender start dates and award dates, indicating a system default date used when the actual date was not recorded.

> **CONFIRMED FACT:** The release-level `date` field is the package publication date (2021-05-03) for all 108,277 releases. Internal event dates must be used for any temporal analysis. These are substantially available: tender start has 9,593 valid dates, award date has 14,658 valid dates.

> **RECOMMENDED FUTURE TREATMENT:** Exclude placeholder dates (2001-01-01, year 2922, any year > 2030) from timing metrics. Retain these records in the database; apply a date-quality flag column in staging. Do not delete or silently correct erroneous dates.

---

## 6. Implementation Section Structure

### 6.1 Location Confirmed

> **CONFIRMED FACT:** The `implementation` section does NOT exist as a top-level release key. Top-level implementation key count: 0. Implementation information is exclusively nested inside `contracts[].implementation`.

| Metric | Value |
|--------|-------|
| Releases with `implementation` tag | 14,894 |
| Contracts with `implementation` sub-object | 14,884 |
| Total transaction objects | 13,617 |
| Transactions with `date` field | 0 |
| Transactions with `amount`/`value` field | 13,617 |
| Total milestone objects inside implementation | 27,960 |
| Top-level `implementation` key in any release | 0 |

### 6.2 Structure Examples

**Example 1 — OCID:** `ocds-gyl66f-521049001-00065`, Contract ID: `1`  
- `implementation` keys: `['transactions', 'milestones']`  
- Transaction keys: `['id', 'value', 'payer', 'payee']`  
- Milestone keys: `['id', 'title', 'description', 'code', 'dueDate', 'dateMet', 'status']`  
- Sample transaction: `id=1`, `amount=None`, `value={'amount': 37161805.0, 'currency': 'NGN'}`, `date=None`  
- Sample milestone: `title=Approval milestones for Contract for Construction of Medical Gas Plant`, `status=met`, `dueDate=2017-02-20T00:00:00Z`  

**Example 2 — OCID:** `ocds-gyl66f-231001001-04209`, Contract ID: `4`  
- `implementation` keys: `['transactions', 'milestones']`  
- Transaction keys: `['id', 'value', 'payer', 'payee']`  
- Milestone keys: `['id', 'title', 'description', 'code', 'dueDate', 'dateMet', 'status']`  
- Sample transaction: `id=2`, `amount=None`, `value={'amount': 600000000.0, 'currency': 'NGN'}`, `date=None`  
- Sample milestone: `title=Approval milestones for AWARD OF CONTRACT FOR `, `status=met`, `dueDate=2019-06-10T00:00:00Z`  

**Example 3 — OCID:** `ocds-gyl66f-19-000003`, Contract ID: `7`  
- `implementation` keys: `['transactions', 'milestones']`  
- Transaction keys: `['id', 'value', 'payer', 'payee']`  
- Milestone keys: `['id', 'title', 'description', 'code', 'dueDate', 'dateMet', 'status']`  
- Sample transaction: `id=3`, `amount=None`, `value={'amount': 4480000.0, 'currency': 'NGN'}`, `date=None`  
- Sample milestone: `title=Approval milestones for AWARD OF CONTRACT FOR CONSTRUCTION OF CALABAR-OBAN EKANG/CAMEROUN BORDER ROAD INCLUDING BRIDGES IN CROSS RIVERS STATE`, `status=met`, `dueDate=2019-06-04T00:00:00Z`  

> **DATA-QUALITY ISSUE:** **CRITICAL:** None of the 13,617 transaction objects contain a `date` field. Payment timing analysis based on transaction dates is not feasible with the current data.
> **UNRESOLVED QUESTION:** Are there other date signals within the implementation structure (e.g., milestone `dueDate` or `dateMet`) that could serve as a payment-timing proxy? Milestone dates are present but require further quality assessment.

> **CONFIRMED FACT:** 13,617 transactions have a populated `amount`/`value` field.

> **RECOMMENDED FUTURE TREATMENT:** Frame the implementation/reporting analysis as a reporting-coverage metric, not a payment-performance metric. Count contracts with `implementation` sub-objects as an indicator of reporting completeness. Do not attempt to compute payment amounts or timelines from transaction data unless further inspection confirms sufficient coverage of amount and date fields.

---

## 7. Supplier ID / Name Investigation

### 7.1 Core Metrics

| Metric | Value |
|--------|-------|
| Total supplier party objects | 16,280 |
| Supplier IDs null | 0 (0.0%) |
| Unique supplier IDs (non-null) | 10,296 |
| Unique supplier names (non-null) | 12,717 |
| Supplier IDs mapping to >1 name | 1,483 |
| Supplier names mapping to >1 ID | 571 |

### 7.2 Sample: Supplier IDs with Multiple Distinct Names

(Same supplier ID appearing under different names — possible name variation for same entity)

| Supplier ID | Names observed |
|-------------|----------------|
| `NG-BPP-BPP-CI-1` | `AIR SEPARATION NIGERIA LIMITED` / `Air Separation limited` |
| `NG-BPP-BPP-CI-394` | `Messrs Setraco Nigeria Ltd` / `SETRACO NIGERIA LIMITED` |
| `NG-BPP-BPP-CI-237` | `ALHAJI BELLO MAIKUSA & SONS LTD` / `Alhaji Bello Maikusa & Sons Ltd` |
| `NG-BPP-BPP-CI-75` | `SLOBAJ ENGINEERING CONSTRUCTION CO. LTD` / `Slobaj Engineering Construction Company` |
| `NG-BPP-BPP-CI-331` | `WIDE BEAM INTERNATIONAL LTD` / `Widebeam International Limited` |
| `NG-BPP-BPP-CI-334` | `GYLAM NIGERIA LIMITED` / `GYLAM NIGERIA LTD` / `Gylam Nigeria Ltd` / `M/S Gylam Nig Ltd` / `Messrs. Gylam Nigeria Limited` |
| `NG-BPP-BPP-CI-138` | `M/S Perazim Development & Planning Ltd` / `PERAZIM DEVELOPMENT & PLANNING LTD` / `Perazim Development & Planning Ltd` |
| `NG-BPP-BPP-CI-154` | `MESSRS SIMEON & GEE ENGINEERING LIMITED` / `SIMEON & GEE ENGINEERING LIMITED` |
| `NG-BPP-BPP-CI-139` | `TROIS ASSOCIATES LIMITED` / `TROIS ASSOCIATES LTD.` |
| `NG-BPP-BPP-CI-4231` | `ASAKA SERVICES LIMITED` / `Asaka Services Ltd` |

### 7.3 Sample: Supplier Names with Multiple Distinct IDs

(Same name appearing under different IDs — possible same entity with inconsistent identifier)

| Supplier name | IDs observed |
|--------------|--------------|
| `M/s Masokano Investment Nig Ltd.` | `NG-BPP-` / `NG-BPP-15699` |
| `PROGRESSIVE EDUCATIONAL SERVICES LTD` | `NG-BPP-BPP-CI-6308` / `NG-BPP-RC469486` |
| `Idrileemah Global Concept Ltd` | `NG-BPP-` / `NG-BPP-15712` |
| `M. S Baraya Ventures` | `NG-BPP-` / `NG-BPP-15714` |
| `COSCHARIS MOTORS LTD` | `NG-BPP-` / `NG-BPP-BPP-CI-2071` |
| `ELIZADE NIGERIA LTD` | `NG-BPP-` / `NG-BPP-BPP-CI-425` |
| `ZUAM IMPEX CONCEPT LTD` | `NG-BPP-` / `NG-BPP-BPP-CI-2069` |
| `Agribiz Projects Limited` | `NG-BPP-` / `NG-BPP-BPP-CI-9728` |
| `AFRIBASED PROJECTS LIMITED` | `NG-BPP-` / `NG-BPP-BPP-CI-2125` |
| `M/s Macay Construction Nig Ltd.` | `NG-BPP-` / `NG-BPP-15722` |

> **CONFIRMED FACT:** 1,483 supplier IDs are associated with more than one supplier name. 571 supplier names are associated with more than one supplier ID.

> **DATA-QUALITY ISSUE:** Supplier entity resolution is non-trivial. Both ID-to-multiple-names and name-to-multiple-IDs patterns are confirmed. This affects the reliability of supplier concentration analysis.

> **PRELIMINARY INTERPRETATION:** Some ID-to-multiple-names cases may be legitimate (e.g., trading name vs. legal name). Some name-to-multiple-IDs cases may reflect data-entry inconsistencies in the identifier field. Neither pattern can be safely resolved by name-similarity alone.

> **UNRESOLVED QUESTION:** What proportion of the 'same name, multiple IDs' cases represent genuinely different entities versus the same entity registered with different identifiers? This requires either source documentation or manual spot-checking.

> **RECOMMENDED FUTURE TREATMENT:** Phase 3 must define an entity-resolution strategy. At minimum: (1) preserve original source values, (2) use supplier ID as the primary grouping key, (3) document cases where ID-to-name mapping is ambiguous, (4) create an auditable mapping table if canonical entity keys are introduced. Do not merge suppliers on name similarity alone.

---

## 8. Phase 3 Decision-Readiness Summary

The following decisions are required before Phase 3 can be completed and schema design can begin.

| # | Decision required | Evidence now available | Urgency |
|---|---|---|---|
| 1 | Release/version modelling strategy for 6,280 multi-release OCIDs | Yes — distribution confirmed, max=74 | **Critical** |
| 2 | Treatment of extreme `numberOfTenderers` outlier | Yes — record identified | High |
| 3 | Treatment of extreme budget value (₦6.5 trillion) | Yes — record identified | High |
| 4 | Treatment of extreme award values (₦1.004 trillion) | Yes — record identified, same OCID as extreme tender | High |
| 5 | Date-validity exclusion rules (placeholders, year 2922, future dates) | Yes — confirmed and quantified | High |
| 6 | Supplier entity-resolution strategy | Partially — scope of problem confirmed | Medium |
| 7 | Implementation / payment coverage framing | Yes — transaction dates and amounts absent | Medium |
| 8 | Zero monetary value treatment (561 budget zeros, 268 award zeros) | Not yet investigated | Medium |

### 8.1 Decisions Requiring Human Approval (per project rules)

Per the project implementation plan, the following require your explicit decision:

1. **Release/version modelling strategy** — this is the most consequential single decision.
   Options include: (a) latest-release snapshot per OCID, (b) union of lifecycle stages,
   (c) full history with a derived analytical snapshot. Each has trade-offs for schema design.

2. **Extreme-value treatment** — which records should be flagged vs. excluded from which metrics?
   (The ₦6.5T budget, the ₦1.004T award, the 90,865-tenderer record.)

3. **Supplier entity-resolution depth** — should the project produce a canonical supplier mapping
   table, or is it sufficient to group by supplier ID with documented caveats?

---

*Report generated by `python/profiling/02_targeted_validation.py`.*  
*Raw dataset was not modified. File size confirmed: 219,816,927 bytes. Run date: 2026-08-16 10:24:14.*