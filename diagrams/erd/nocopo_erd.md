# NOCOPO Entity-Relationship Diagram

This document contains the Entity-Relationship Diagram for the NOCOPO relational model, including both staging (`stg`) and core dimension (`core`) tables.

## Diagram

```mermaid
erDiagram
    %% Core Dimension Tables
    dim_buyer {
        VARCHAR buyer_id PK
        VARCHAR buyer_name
        VARCHAR buyer_name_raw
    }
    
    dim_supplier {
        VARCHAR supplier_id PK
        VARCHAR supplier_name
        VARCHAR supplier_name_raw
        BOOLEAN supplier_id_flag
    }

    %% Staging Tables
    releases {
        VARCHAR release_id PK
        VARCHAR ocid
        DATE release_date
        VARCHAR tag
        VARCHAR buyer_id FK
        VARCHAR buyer_name
        BOOLEAN party_flag
    }

    planning {
        VARCHAR release_id PK, FK
        DECIMAL budget_amount
        VARCHAR budget_currency
        BOOLEAN budget_amount_flag
        BOOLEAN budget_monetary_flag
    }

    tender {
        VARCHAR release_id PK, FK
        VARCHAR tender_id
        INT number_of_tenderers
        DECIMAL tender_value_amount
        DATE tender_start_date
        DATE tender_end_date
        BOOLEAN tenderer_count_flag
        BOOLEAN tender_start_date_flag
        BOOLEAN tender_end_date_flag
    }

    awards {
        VARCHAR award_id PK
        VARCHAR release_id FK
        DECIMAL award_value_amount
        DATE award_date
        VARCHAR status
        BOOLEAN award_value_flag
        BOOLEAN award_monetary_flag
        BOOLEAN award_date_flag
    }

    award_suppliers {
        SERIAL award_supplier_pk PK
        VARCHAR award_id FK
        VARCHAR supplier_id FK
        VARCHAR supplier_name
    }

    contracts {
        VARCHAR contract_id PK
        VARCHAR release_id FK
        VARCHAR award_id FK
        DECIMAL contract_value_amount
        DATE date_signed
        DATE period_start_date
        DATE period_end_date
        VARCHAR status
        BOOLEAN has_implementation
        BOOLEAN contract_monetary_flag
        BOOLEAN date_signed_flag
    }

    transactions {
        SERIAL transaction_pk PK
        VARCHAR contract_id FK
        VARCHAR transaction_id
        DECIMAL transaction_value
        VARCHAR payer_id
        VARCHAR payee_id
    }

    milestones {
        SERIAL milestone_pk PK
        VARCHAR contract_id FK
        VARCHAR milestone_source
        VARCHAR milestone_id
        DATE due_date
        DATE date_met
        VARCHAR status
    }

    parties {
        SERIAL party_pk PK
        VARCHAR release_id FK
        VARCHAR party_id
        VARCHAR party_name
        VARCHAR roles
        BOOLEAN supplier_id_flag
    }

    %% Relationships
    dim_buyer ||--o{ releases : "1..N"
    dim_supplier ||--o{ award_suppliers : "1..N"
    
    releases ||--|| planning : "1..1"
    releases ||--o| tender : "1..0-1"
    releases ||--o| awards : "1..0-1"
    releases ||--o| contracts : "1..0-1"
    releases ||--o{ parties : "1..0-N"
    
    awards ||--|{ award_suppliers : "1..1-N"
    contracts }o--|| awards : "N..1"
    contracts ||--o{ transactions : "1..0-N"
    contracts ||--o{ milestones : "1..0-N"
```

## Legend
- **PK**: Primary Key
- **FK**: Foreign Key
- **1..N**: One-to-Many
- **1..1**: One-to-One
- **1..0-1**: One-to-Zero-or-One
- **1..0-N**: One-to-Zero-or-Many
