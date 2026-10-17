# Architecture
# Nigeria Public Procurement Intelligence

The logical architecture follows `docs/00_project_planning/NOCOPO_SQL_Project_Technology_Architecture.docx` §4:
SQL-first, with Python for ingestion and checks and Power BI for presentation only. Diagrams are Mermaid so they
render on GitHub and stay in version control with the code.

## Data flow and responsibilities

```mermaid
flowchart TD
    subgraph Source["Source (immutable, not in Git)"]
        RAW["NOCOPO OCDS export<br/>all07010.json, SHA-256 pinned"]
    end
    subgraph Python["Python (ingestion and checks)"]
        PROF["profiling/<br/>Phase 2 audit"]
        LOAD["ingest/01_load_staging.py"]
        RUN["validation/ runners<br/>suites, analysis, trace check"]
    end
    subgraph PG["PostgreSQL (analytical engine)"]
        STG["stg.*<br/>one table per OCDS section,<br/>DQ flags as generated columns"]
        CORE["core.*<br/>dim_buyer, dim_supplier,<br/>materialised process snapshot"]
        AN["analytics.*<br/>16 views: metric eligibility,<br/>population register, DQ impact"]
        CHK["sql/03_data_quality<br/>validation suites"]
    end
    subgraph Present["Presentation"]
        PBI["Power BI (.pbit)<br/>role nocopo_bi, read-only"]
        FIND["Executive findings<br/>claim-traced"]
    end
    RAW --> PROF
    RAW --> LOAD --> STG --> CORE --> AN
    CHK -. checks .-> STG
    CHK -. checks .-> CORE
    CHK -. checks .-> AN
    RUN --> CHK
    AN --> PBI
    AN -->|"sql/06_analysis"| FIND
```

## Gates along the flow

```mermaid
flowchart LR
    A["Gate A<br/>audit complete"] --> S["Schema + staging<br/>64 load checks"]
    S --> B["Gate B<br/>core validated<br/>107 checks"]
    B --> V["Analytical views<br/>27 checks"]
    V --> C["Gate C<br/>analysis reconciled 31,<br/>BI read-only 16"]
    C --> D["Gate D<br/>findings traced<br/>236 trace rows"]
```

Gate counts are the GATE checks in the committed result logs; see `docs/methodology.md` §4 for the table and links.
The entity-relationship diagram is in [`../erd/nocopo_erd.md`](../erd/nocopo_erd.md).
