-- ============================================================
-- NOCOPO — Nigeria Public Procurement Intelligence
-- Phase 4: Draft Core Schema (PostgreSQL)
-- ============================================================
--
-- STATUS: DRAFT — NOT EXECUTED
-- This DDL has not been run against any PostgreSQL instance.
-- It will be reviewed before Phase 5 implementation.
--
-- Design basis:
--   docs/phase3_data_quality_decision_log.md (v1.1)
--   docs/phase3_metric_eligibility.md (v1.1)
--   docs/phase3_data_dictionary.md (v1.1)
--   docs/phase4_relational_model.md
--   Empirical dataset inspection (108,277 releases, 98,866 OCIDs)
--
-- Architecture: Three-layer model
--   stg.*         Staging layer (source-faithful, release-centric)
--   core.*        Core dimension tables (deduplicated entities)
--   analytics.*   Analytical views (Phase 5, not defined here)
--
-- Date: 2026-08-20
-- ============================================================

-- ============================================================
-- SCHEMAS
-- ============================================================

CREATE SCHEMA IF NOT EXISTS stg;
CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS analytics;

-- ============================================================
-- STAGING LAYER: stg.*
-- ============================================================
-- The staging layer preserves the source release-centric structure.
-- Each release is stored as a separate row with its nested data
-- decomposed into child tables linked by release_id or child PKs.
-- No analytical transformations are applied at this layer.
-- Data-quality flags ARE computed and stored at this layer
-- to support downstream filtering without re-parsing source data.
-- ============================================================

-- ------------------------------------------------------------
-- stg.releases
-- Grain: One row per OCDS release (108,277 expected)
-- PK: release_id (globally unique in source — verified)
-- DQ: party_flag (DQ-18)
-- Metrics: All metrics require join through this table for OCID grouping
-- ------------------------------------------------------------
CREATE TABLE stg.releases (
    release_id          VARCHAR(64)     NOT NULL,
    ocid                VARCHAR(64)     NOT NULL,
    release_date        TIMESTAMPTZ,                -- DQ-10: all = 2021-05-03T22:44:00Z (package pub date, NOT event date)
    tag                 TEXT[]          NOT NULL,    -- e.g. {planning}, {planning,tender,award,contract,implementation}
    initiation_type     VARCHAR(32),
    language            VARCHAR(8),
    buyer_id            VARCHAR(64),                -- FK to core.dim_buyer
    buyer_name          VARCHAR(512),               -- Denormalized for traceability
    party_flag          VARCHAR(16),                -- DQ-18: NULL | 'NO_PARTIES' (20 releases)

    CONSTRAINT pk_releases PRIMARY KEY (release_id),
    CONSTRAINT chk_releases_party_flag
        CHECK (party_flag IS NULL OR party_flag IN ('NO_PARTIES'))
);

COMMENT ON TABLE stg.releases IS
    'Source-faithful staging of all OCDS releases. One row per release. '
    'release_id is globally unique. ocid groups releases into procurement processes. '
    'DQ-10: release_date is package publication metadata, NOT an event date.';

COMMENT ON COLUMN stg.releases.party_flag IS
    'DQ-18: NULL = parties array present; NO_PARTIES = parties array absent (20 records).';


-- ------------------------------------------------------------
-- stg.planning
-- Grain: One row per release (all 108,277 releases have planning)
-- PK/FK: release_id
-- DQ: budget_amount_flag (DQ-06), monetary_flag (DQ-16)
-- Metrics: M-P01 (total planned budget by entity)
-- ------------------------------------------------------------
CREATE TABLE stg.planning (
    release_id              VARCHAR(64)     NOT NULL,
    budget_amount           NUMERIC(30,2),              -- NULL = not reported; 0 = reported as zero
    budget_currency         VARCHAR(3),                 -- Uniformly 'NGN' observed
    budget_description      TEXT,
    budget_project          TEXT,                        -- planning.budget.project (if present)
    budget_amount_flag      VARCHAR(16),                -- DQ-06: NULL | 'EXTREME'
    budget_monetary_flag    VARCHAR(16),                -- DQ-16: NULL | 'ZERO_VALUE'

    CONSTRAINT pk_planning PRIMARY KEY (release_id),
    CONSTRAINT fk_planning_release
        FOREIGN KEY (release_id) REFERENCES stg.releases(release_id),
    CONSTRAINT chk_planning_budget_flag
        CHECK (budget_amount_flag IS NULL OR budget_amount_flag IN ('EXTREME')),
    CONSTRAINT chk_planning_monetary_flag
        CHECK (budget_monetary_flag IS NULL OR budget_monetary_flag IN ('ZERO_VALUE'))
);

COMMENT ON TABLE stg.planning IS
    'Planning/budget data per release. All releases have a planning section. '
    'DQ-06: 32 records >= NGN 1T flagged EXTREME (NPHCDA vaccine, infrastructure). '
    'DQ-16: Zero values retained and flagged, never converted to NULL.';

COMMENT ON COLUMN stg.planning.budget_amount_flag IS
    'DQ-06: NULL = normal range; EXTREME = budget >= NGN 1 trillion. '
    'EXTREME records excluded from aggregate budget totals (M-P01).';


-- ------------------------------------------------------------
-- stg.tender
-- Grain: One row per release with tender data (18,408 expected)
-- PK/FK: release_id
-- DQ: tenderer_count_flag (DQ-03/04/05), date flags (DQ-08/09)
-- Metrics: M-C01, M-C02 (competition); M-E01 (tender duration); M-E02 (award lag)
-- ------------------------------------------------------------
CREATE TABLE stg.tender (
    release_id                  VARCHAR(64)     NOT NULL,
    tender_id                   VARCHAR(64),                -- Source: tender.id
    title                       TEXT,
    description                 TEXT,
    status                      VARCHAR(32),                -- e.g. 'complete', 'active'
    procurement_method          VARCHAR(32),                -- Uniformly 'open' observed
    procurement_method_details  VARCHAR(128),               -- e.g. 'National Competitive Bidding'
    procurement_method_rationale TEXT,
    number_of_tenderers         INTEGER,                    -- Source: tender.numberOfTenderers (0% null)
    tender_value_amount         NUMERIC(30,2),              -- Source: tender.value.amount
    tender_value_currency       VARCHAR(3),
    tender_start_date           DATE,                       -- Source: tender.tenderPeriod.startDate (47.7% null)
    tender_end_date             DATE,                       -- Source: tender.tenderPeriod.endDate (47.7% null)
    award_criteria              VARCHAR(64),
    award_criteria_details      TEXT,
    has_enquiries               BOOLEAN,
    submission_method           TEXT[],
    submission_method_details   TEXT,
    -- Data-quality flags
    tenderer_count_flag         VARCHAR(16)     NOT NULL,   -- DQ-03/04/05: NORMAL|ELEVATED|ANOMALOUS
    tender_value_monetary_flag  VARCHAR(16),                -- DQ-16: NULL|ZERO_VALUE
    tender_start_date_flag      VARCHAR(16),                -- DQ-08/09: VALID|PLACEHOLDER|FUTURE|IMPOSSIBLE
    tender_end_date_flag        VARCHAR(16),                -- DQ-08/09: same

    CONSTRAINT pk_tender PRIMARY KEY (release_id),
    CONSTRAINT fk_tender_release
        FOREIGN KEY (release_id) REFERENCES stg.releases(release_id),
    CONSTRAINT chk_tenderer_count_flag
        CHECK (tenderer_count_flag IN ('NORMAL', 'ELEVATED', 'ANOMALOUS')),
    CONSTRAINT chk_tender_value_monetary_flag
        CHECK (tender_value_monetary_flag IS NULL
               OR tender_value_monetary_flag IN ('ZERO_VALUE')),
    CONSTRAINT chk_tender_start_date_flag
        CHECK (tender_start_date_flag IS NULL
               OR tender_start_date_flag IN ('VALID', 'PLACEHOLDER', 'FUTURE', 'IMPOSSIBLE')),
    CONSTRAINT chk_tender_end_date_flag
        CHECK (tender_end_date_flag IS NULL
               OR tender_end_date_flag IN ('VALID', 'PLACEHOLDER', 'FUTURE', 'IMPOSSIBLE'))
);

COMMENT ON TABLE stg.tender IS
    'Tender-stage data per release. Source: releases[].tender (single object, not array). '
    'Only 18,408 of 108,277 releases contain tender data. '
    'DQ-05: 65 records with numberOfTenderers > 1000 (Federal Ministry of Works) flagged ANOMALOUS.';

COMMENT ON COLUMN stg.tender.tenderer_count_flag IS
    'DQ-03/04/05: NORMAL (1-100), ELEVATED (101-1000), ANOMALOUS (>1000). '
    'ANOMALOUS excluded from primary competition metrics (M-C01, M-C02). '
    'Cannot be NULL — every tender record gets a classification.';

COMMENT ON COLUMN stg.tender.tender_start_date_flag IS
    'DQ-08/09: VALID = plausible date; PLACEHOLDER = 2001-01-01; '
    'FUTURE = year 2026-2050; IMPOSSIBLE = year > 2050. '
    'NULL = tender_start_date is NULL (not assessed). '
    'Non-VALID dates excluded from duration metrics (M-E01, M-E02).';


-- ------------------------------------------------------------
-- stg.awards
-- Grain: One row per award (17,417 expected; max 1 per release)
-- PK: award_id (globally unique — empirically confirmed)
-- FK: release_id -> stg.releases
-- DQ: award_value_flag (DQ-07), monetary_flag (DQ-16), award_date_flag (DQ-08/09)
-- Metrics: M-S01 (supplier concentration), M-V01 (median award), M-E02 (award lag)
-- ------------------------------------------------------------
CREATE TABLE stg.awards (
    award_id                VARCHAR(64)     NOT NULL,
    release_id              VARCHAR(64)     NOT NULL,
    title                   TEXT,
    description             TEXT,
    status                  VARCHAR(32),                -- active|cancelled|pending|unsuccessful
    award_date              DATE,                       -- Source: awards[].date (15.1% null)
    award_value_amount      NUMERIC(30,2),              -- Source: awards[].value.amount (0% null, 268 zeros)
    award_value_currency    VARCHAR(3),                 -- Uniformly 'NGN'
    -- Data-quality flags
    award_value_flag        VARCHAR(16),                -- DQ-07: NULL | 'EXTREME'
    award_monetary_flag     VARCHAR(16),                -- DQ-16: NULL | 'ZERO_VALUE'
    award_date_flag         VARCHAR(16),                -- DQ-08/09: VALID|PLACEHOLDER|FUTURE|IMPOSSIBLE

    CONSTRAINT pk_awards PRIMARY KEY (award_id),
    CONSTRAINT fk_awards_release
        FOREIGN KEY (release_id) REFERENCES stg.releases(release_id),
    CONSTRAINT chk_award_value_flag
        CHECK (award_value_flag IS NULL OR award_value_flag IN ('EXTREME')),
    CONSTRAINT chk_award_monetary_flag
        CHECK (award_monetary_flag IS NULL OR award_monetary_flag IN ('ZERO_VALUE')),
    CONSTRAINT chk_award_date_flag
        CHECK (award_date_flag IS NULL
               OR award_date_flag IN ('VALID', 'PLACEHOLDER', 'FUTURE', 'IMPOSSIBLE')),
    CONSTRAINT chk_award_status
        CHECK (status IS NULL
               OR status IN ('active', 'cancelled', 'pending', 'unsuccessful'))
);

COMMENT ON TABLE stg.awards IS
    'Award records. Source: releases[].awards[] (max 1 per release). '
    'award_id is globally unique across all releases (empirically confirmed). '
    'DQ-07: FCTA warehouse award (NGN 1.004T) flagged EXTREME. '
    'DQ-16: 268 zero-value awards flagged ZERO_VALUE.';

COMMENT ON COLUMN stg.awards.award_value_flag IS
    'DQ-07: NULL = normal range; EXTREME = NGN 1.004 trillion warehouse award. '
    'EXTREME excluded from distribution benchmarks (M-V01) but available for per-OCID analysis.';


-- ------------------------------------------------------------
-- stg.award_suppliers
-- Grain: One row per (award, supplier) pair (~17,441 expected)
-- PK: Surrogate (SERIAL); natural key: (award_id, supplier_id)
-- FK: award_id -> stg.awards
-- DQ: supplier_id_flag (DQ-14) applied at party/dimension level
-- Metrics: M-S01 (supplier concentration)
-- Design note: Junction table required because 6 awards have 5 suppliers.
-- ------------------------------------------------------------
CREATE TABLE stg.award_suppliers (
    award_supplier_pk       SERIAL          NOT NULL,
    award_id                VARCHAR(64)     NOT NULL,
    supplier_id             VARCHAR(64),                -- Source: awards[].suppliers[].id
    supplier_name           VARCHAR(512),               -- Source: awards[].suppliers[].name
    supplier_name_raw       VARCHAR(512),               -- Original unmodified name for traceability

    CONSTRAINT pk_award_suppliers PRIMARY KEY (award_supplier_pk),
    CONSTRAINT fk_award_suppliers_award
        FOREIGN KEY (award_id) REFERENCES stg.awards(award_id),
    CONSTRAINT uq_award_supplier
        UNIQUE (award_id, supplier_id)
);

COMMENT ON TABLE stg.award_suppliers IS
    'Junction table linking awards to suppliers. Most awards have 1 supplier; '
    '6 awards have 5 suppliers. Source: awards[].suppliers[]. '
    'supplier_name_raw preserves the original source name before any standardization.';


-- ------------------------------------------------------------
-- stg.contracts
-- Grain: One row per contract (17,043 expected; max 1 per release)
-- PK: contract_id (globally unique — empirically confirmed)
-- FK: release_id -> stg.releases; award_id -> stg.awards
-- DQ: date quality flags (DQ-08/09), monetary flags (DQ-16)
-- Metrics: M-I01 (implementation coverage)
-- Design note: Every contract has an awardID linking to its award.
-- ------------------------------------------------------------
CREATE TABLE stg.contracts (
    contract_id                 VARCHAR(64)     NOT NULL,
    release_id                  VARCHAR(64)     NOT NULL,
    award_id                    VARCHAR(64),                -- Source: contracts[].awardID (100% present)
    title                       TEXT,
    description                 TEXT,
    status                      VARCHAR(32),                -- active|cancelled|pending|terminated
    contract_value_amount       NUMERIC(30,2),              -- Source: contracts[].value.amount
    contract_value_currency     VARCHAR(3),
    date_signed                 DATE,                       -- Source: contracts[].dateSigned (15.6% null)
    period_start_date           DATE,                       -- Source: contracts[].period.startDate (57.9% null)
    period_end_date             DATE,                       -- Source: contracts[].period.endDate (57.9% null)
    has_implementation          BOOLEAN         NOT NULL DEFAULT FALSE, -- Derived: TRUE if implementation section exists
    -- Data-quality flags
    contract_monetary_flag      VARCHAR(16),                -- DQ-16: NULL | 'ZERO_VALUE'
    date_signed_flag            VARCHAR(16),                -- DQ-08/09: VALID|PLACEHOLDER|FUTURE|IMPOSSIBLE
    period_start_date_flag      VARCHAR(16),                -- DQ-08/09: same
    period_end_date_flag        VARCHAR(16),                -- DQ-08/09: same

    CONSTRAINT pk_contracts PRIMARY KEY (contract_id),
    CONSTRAINT fk_contracts_release
        FOREIGN KEY (release_id) REFERENCES stg.releases(release_id),
    CONSTRAINT fk_contracts_award
        FOREIGN KEY (award_id) REFERENCES stg.awards(award_id),
    CONSTRAINT chk_contract_monetary_flag
        CHECK (contract_monetary_flag IS NULL OR contract_monetary_flag IN ('ZERO_VALUE')),
    CONSTRAINT chk_date_signed_flag
        CHECK (date_signed_flag IS NULL
               OR date_signed_flag IN ('VALID', 'PLACEHOLDER', 'FUTURE', 'IMPOSSIBLE')),
    CONSTRAINT chk_period_start_date_flag
        CHECK (period_start_date_flag IS NULL
               OR period_start_date_flag IN ('VALID', 'PLACEHOLDER', 'FUTURE', 'IMPOSSIBLE')),
    CONSTRAINT chk_period_end_date_flag
        CHECK (period_end_date_flag IS NULL
               OR period_end_date_flag IN ('VALID', 'PLACEHOLDER', 'FUTURE', 'IMPOSSIBLE')),
    CONSTRAINT chk_contract_status
        CHECK (status IS NULL
               OR status IN ('active', 'cancelled', 'pending', 'terminated'))
);

COMMENT ON TABLE stg.contracts IS
    'Contract records. Source: releases[].contracts[] (max 1 per release). '
    'contract_id is globally unique. Every contract links to its award via award_id. '
    'has_implementation is a derived boolean indicating whether the contract has '
    'an implementation section with transactions or milestones.';


-- ------------------------------------------------------------
-- stg.transactions
-- Grain: One row per implementation transaction (~13,617 expected; max 2 per contract)
-- PK: Surrogate (SERIAL); natural composite: (contract_id, transaction_id)
-- FK: contract_id -> stg.contracts
-- DQ: DQ-11 (no date field in source); DQ-12 (value semantics UNRESOLVED)
-- Metrics: M-I01 (implementation coverage — presence indicator)
-- Design note: Transactions have NO date field in the source data.
--              Transaction values must NOT be summed until DQ-12 is resolved.
-- ------------------------------------------------------------
CREATE TABLE stg.transactions (
    transaction_pk          SERIAL          NOT NULL,
    contract_id             VARCHAR(64)     NOT NULL,
    transaction_id          VARCHAR(64),                -- Source: transactions[].id (locality unclear)
    transaction_value       NUMERIC(30,2),              -- Source: transactions[].value.amount (0% null in source)
    transaction_currency    VARCHAR(3),                 -- Source: transactions[].value.currency
    payer_id                VARCHAR(64),                -- Source: transactions[].payer.id
    payer_name              VARCHAR(512),               -- Source: transactions[].payer.name (if present)
    payee_id                VARCHAR(64),                -- Source: transactions[].payee.id
    payee_name              VARCHAR(512),               -- Source: transactions[].payee.name (if present)
    transaction_monetary_flag VARCHAR(16),              -- DQ-16: NULL | 'ZERO_VALUE'
    -- NOTE: No transaction_date column. DQ-11 confirms this field
    --       is universally absent from the source dataset.
    -- NOTE: DQ-12 UNRESOLVED — do not aggregate transaction values
    --       until cumulative vs. incremental semantics are determined.

    CONSTRAINT pk_transactions PRIMARY KEY (transaction_pk),
    CONSTRAINT fk_transactions_contract
        FOREIGN KEY (contract_id) REFERENCES stg.contracts(contract_id),
    CONSTRAINT chk_transaction_monetary_flag
        CHECK (transaction_monetary_flag IS NULL OR transaction_monetary_flag IN ('ZERO_VALUE'))
);

COMMENT ON TABLE stg.transactions IS
    'Implementation transactions. Source: contracts[].implementation.transactions[]. '
    'Max 2 per contract. 13,617 total expected. '
    'CRITICAL: No date field exists (DQ-11). Payment timing cannot be computed. '
    'CRITICAL: Value semantics unresolved (DQ-12). Do NOT sum transaction values '
    'per contract until cumulative vs. incremental semantics are confirmed.';


-- ------------------------------------------------------------
-- stg.milestones
-- Grain: One row per milestone (from both contract-level and implementation-level)
-- PK: Surrogate (SERIAL)
-- FK: contract_id -> stg.contracts
-- DQ: Milestone date quality deferred to Phase 5 profiling
-- Design note: Milestones can come from two source locations:
--   (a) contracts[].milestones[] (contract-level)
--   (b) contracts[].implementation.milestones[] (implementation-level)
--   The milestone_source column distinguishes these.
-- ------------------------------------------------------------
CREATE TABLE stg.milestones (
    milestone_pk            SERIAL          NOT NULL,
    contract_id             VARCHAR(64)     NOT NULL,
    milestone_source        VARCHAR(16)     NOT NULL,   -- 'CONTRACT' | 'IMPLEMENTATION'
    milestone_id            VARCHAR(64),                -- Source: milestones[].id
    title                   TEXT,
    description             TEXT,
    code                    VARCHAR(64),
    due_date                DATE,                       -- Source: milestones[].dueDate
    date_met                DATE,                       -- Source: milestones[].dateMet
    status                  VARCHAR(32),                -- Observed: 'met'
    due_date_flag           VARCHAR(16),                -- Deferred: date quality TBD in Phase 5
    date_met_flag           VARCHAR(16),                -- Deferred: date quality TBD in Phase 5

    CONSTRAINT pk_milestones PRIMARY KEY (milestone_pk),
    CONSTRAINT fk_milestones_contract
        FOREIGN KEY (contract_id) REFERENCES stg.contracts(contract_id),
    CONSTRAINT chk_milestone_source
        CHECK (milestone_source IN ('CONTRACT', 'IMPLEMENTATION')),
    CONSTRAINT chk_due_date_flag
        CHECK (due_date_flag IS NULL
               OR due_date_flag IN ('VALID', 'PLACEHOLDER', 'FUTURE', 'IMPOSSIBLE')),
    CONSTRAINT chk_date_met_flag
        CHECK (date_met_flag IS NULL
               OR date_met_flag IN ('VALID', 'PLACEHOLDER', 'FUTURE', 'IMPOSSIBLE'))
);

COMMENT ON TABLE stg.milestones IS
    'Milestones from both contract-level and implementation-level sources. '
    'milestone_source discriminates origin: CONTRACT = contracts[].milestones[], '
    'IMPLEMENTATION = contracts[].implementation.milestones[]. '
    'Date quality assessment for dueDate/dateMet deferred to Phase 5 profiling.';


-- ------------------------------------------------------------
-- stg.parties
-- Grain: One row per (release, party) pair
-- PK: Surrogate (SERIAL); natural composite: (release_id, party_id)
-- FK: release_id -> stg.releases
-- DQ: supplier_id_flag (DQ-14) for supplier-role parties
-- Design note: A party can have multiple roles (stored as TEXT array).
-- Supplier identity analysis requires joining through this table.
-- Max 2 parties per release observed.
-- ------------------------------------------------------------
CREATE TABLE stg.parties (
    party_pk                SERIAL          NOT NULL,
    release_id              VARCHAR(64)     NOT NULL,
    party_id                VARCHAR(64),                -- Source: parties[].id (e.g. NG-BPP-BPP-NOC-NNNNNN)
    party_name              VARCHAR(512),               -- Source: parties[].name (standardized)
    party_name_raw          VARCHAR(512),               -- Original unmodified name
    identifier_scheme       VARCHAR(32),                -- Source: parties[].identifier.scheme (e.g. 'NG-BPP')
    identifier_id           VARCHAR(64),                -- Source: parties[].identifier.id
    roles                   TEXT[]          NOT NULL,    -- Source: parties[].roles (e.g. {buyer,payer,procuringEntity})
    supplier_id_flag        VARCHAR(16),                -- DQ-14: NULL | 'INCOMPLETE' (for supplier-role parties only)

    CONSTRAINT pk_parties PRIMARY KEY (party_pk),
    CONSTRAINT fk_parties_release
        FOREIGN KEY (release_id) REFERENCES stg.releases(release_id),
    CONSTRAINT uq_release_party
        UNIQUE (release_id, party_id),
    CONSTRAINT chk_supplier_id_flag
        CHECK (supplier_id_flag IS NULL OR supplier_id_flag IN ('INCOMPLETE'))
);

COMMENT ON TABLE stg.parties IS
    'All party records from all releases. Source: releases[].parties[]. '
    'Max 2 parties per release. One party can have multiple roles. '
    'DQ-14: Supplier-role parties with bare NG-BPP- prefix (no numeric suffix) '
    'receive supplier_id_flag = INCOMPLETE.';

COMMENT ON COLUMN stg.parties.supplier_id_flag IS
    'DQ-14: NULL = complete identifier or non-supplier party; '
    'INCOMPLETE = supplier-role party with bare NG-BPP- prefix lacking numeric suffix. '
    'INCOMPLETE suppliers excluded from primary concentration metrics (M-S01).';


-- ============================================================
-- CORE LAYER: core.*
-- ============================================================
-- Deduplicated dimension tables for entities that appear across
-- many releases. These are populated by extracting distinct
-- values from staging during Phase 6.
-- ============================================================

-- ------------------------------------------------------------
-- core.dim_buyer
-- Grain: One row per unique buyer_id (~666 expected)
-- PK: buyer_id (natural key from source)
-- Metrics: M-P01 (budget by entity), entity benchmarking
-- ------------------------------------------------------------
CREATE TABLE core.dim_buyer (
    buyer_id                VARCHAR(64)     NOT NULL,
    buyer_name              VARCHAR(512),               -- Standardized display name
    buyer_name_raw          VARCHAR(512),               -- Original source name preserved

    CONSTRAINT pk_dim_buyer PRIMARY KEY (buyer_id)
);

COMMENT ON TABLE core.dim_buyer IS
    'Distinct procuring entities (buyers). Source: releases[].buyer. '
    '666 unique buyer IDs observed. buyer_name_raw preserves original source '
    'name before whitespace/casing standardization.';


-- ------------------------------------------------------------
-- core.dim_supplier
-- Grain: One row per unique supplier_id (~10,296 expected)
-- PK: supplier_id (natural key from source)
-- DQ: supplier_id_flag (DQ-14)
-- Metrics: M-S01 (supplier concentration)
-- Design note: This is the source-identity table.
-- The dim_supplier_canonical mapping table (DQ-15)
-- is a future Phase 5+ addition requiring controlled
-- human-supervised entity resolution.
-- ------------------------------------------------------------
CREATE TABLE core.dim_supplier (
    supplier_id             VARCHAR(64)     NOT NULL,
    supplier_name           VARCHAR(512),               -- Most common standardized name
    supplier_name_raw       VARCHAR(512),               -- Original source name (first observed)
    supplier_id_flag        VARCHAR(16),                -- DQ-14: NULL | 'INCOMPLETE'

    CONSTRAINT pk_dim_supplier PRIMARY KEY (supplier_id),
    CONSTRAINT chk_dim_supplier_id_flag
        CHECK (supplier_id_flag IS NULL OR supplier_id_flag IN ('INCOMPLETE'))
);

COMMENT ON TABLE core.dim_supplier IS
    'Distinct suppliers by source supplier_id. 10,296 unique IDs observed. '
    'DQ-13: 1,483 IDs map to multiple name variations (casing, abbreviations). '
    'DQ-14: Incomplete NG-BPP- identifiers flagged. '
    'DQ-15: Canonical mapping table deferred to controlled Phase 5+ process. '
    'No fuzzy-name merging applied.';


-- ============================================================
-- FUTURE EXTENSION: core.dim_supplier_canonical (NOT CREATED)
-- ============================================================
-- This table is specified in Phase 3 (DQ-15) but NOT created
-- at this stage. It will support auditable entity resolution:
--
-- CREATE TABLE core.dim_supplier_canonical (
--     source_supplier_id      VARCHAR(64)     NOT NULL,
--     source_supplier_name    VARCHAR(512),
--     canonical_supplier_id   VARCHAR(64),
--     canonical_supplier_name VARCHAR(512),
--     resolution_status       VARCHAR(16),  -- CONFIRMED|PROBABLE|UNRESOLVED
--     resolution_method       VARCHAR(32),  -- MANUAL|ID_MATCH|FORMATTING_NORMALIZATION
--     confidence              VARCHAR(8),   -- HIGH|MEDIUM|LOW
--     notes                   TEXT,
--     CONSTRAINT pk_dim_supplier_canonical
--         PRIMARY KEY (source_supplier_id)
-- );
--
-- Requires human-supervised entity resolution.
-- No automated fuzzy-matching permitted.
-- ============================================================


-- ============================================================
-- INDEXES (proposed — to be created during Phase 5)
-- ============================================================
-- These indexes support the analytical queries defined in
-- Phase 3 metric eligibility. They are listed here for
-- design documentation but NOT created in this draft.
--
-- -- Process-snapshot rule: group releases by OCID
-- CREATE INDEX idx_releases_ocid ON stg.releases (ocid);
--
-- -- Budget analysis: filter by flag
-- CREATE INDEX idx_planning_budget_flag ON stg.planning (budget_amount_flag);
--
-- -- Competition metrics: filter by tenderer flag
-- CREATE INDEX idx_tender_count_flag ON stg.tender (tenderer_count_flag);
--
-- -- Award metrics: filter by value flag
-- CREATE INDEX idx_awards_value_flag ON stg.awards (award_value_flag);
--
-- -- Join awards back to releases for OCID context
-- CREATE INDEX idx_awards_release ON stg.awards (release_id);
--
-- -- Join contracts back to releases and awards
-- CREATE INDEX idx_contracts_release ON stg.contracts (release_id);
-- CREATE INDEX idx_contracts_award ON stg.contracts (award_id);
--
-- -- Supplier concentration joins
-- CREATE INDEX idx_award_suppliers_award ON stg.award_suppliers (award_id);
-- CREATE INDEX idx_award_suppliers_supplier ON stg.award_suppliers (supplier_id);
--
-- -- Party lookups
-- CREATE INDEX idx_parties_release ON stg.parties (release_id);
-- CREATE INDEX idx_parties_party_id ON stg.parties (party_id);
-- ============================================================


-- ============================================================
-- ANALYTICAL VIEWS (Phase 5 — specification only)
-- ============================================================
-- The following views will be created during Phase 5/7:
--
-- analytics.vw_process_snapshot
--     One row per OCID. Selects the release with the most
--     lifecycle tags per the process-snapshot rule.
--     If tied, prefers the highest release_id.
--     Grain: 98,866 rows (one per procurement process).
--
-- analytics.vw_budget_eligible
--     Eligible records for M-P01 (planned budget by entity).
--     Filters: budget_amount_flag IS NULL, monetary_flag IS NULL,
--              party_flag IS NULL, process-snapshot applied.
--
-- analytics.vw_competition_eligible
--     Eligible records for M-C01/M-C02.
--     Filters: tenderer_count_flag = 'NORMAL',
--              process-snapshot applied.
--
-- analytics.vw_supplier_concentration_eligible
--     Eligible records for M-S01.
--     Filters: award_status = 'active', award_value_flag IS NULL,
--              monetary_flag IS NULL, supplier_id_flag IS NULL,
--              process-snapshot applied.
--
-- analytics.vw_award_value_eligible
--     Eligible records for M-V01.
--     Filters: award_status = 'active', award_value_flag IS NULL,
--              monetary_flag IS NULL, process-snapshot applied.
--
-- analytics.vw_timing_eligible
--     Eligible records for M-E01/M-E02.
--     Filters: date flags = 'VALID', process-snapshot applied,
--              single-award OCIDs only for M-E02.
-- ============================================================


-- ============================================================
-- END OF DRAFT DDL
-- ============================================================
-- STATUS: DRAFT — NOT EXECUTED
-- This file will be reviewed during Phase 4 human approval.
-- Phase 5 implementation will execute a finalized version.
-- ============================================================
