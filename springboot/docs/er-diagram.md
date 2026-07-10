# Karuna Backend ER Diagram

This document reflects the Milestone 2 PostgreSQL domain model and Flyway migrations `V1` through `V5`.

```mermaid
erDiagram
    USERS {
        BIGINT id PK
        VARCHAR name
        VARCHAR email UK
        VARCHAR phone_number UK
        VARCHAR password_hash
        VARCHAR role
        BIGINT location_id FK
        BOOLEAN active
        TIMESTAMP deleted_at
    }

    ROLES {
        BIGINT id PK
        VARCHAR name UK
        VARCHAR description
    }

    USER_ROLES {
        BIGINT user_id FK
        BIGINT role_id FK
    }

    LOCATIONS {
        BIGINT id PK
        VARCHAR label
        VARCHAR city
        VARCHAR state
        NUMERIC latitude
        NUMERIC longitude
    }

    ANIMALS {
        BIGINT id PK
        VARCHAR name
        VARCHAR species
        VARCHAR condition
        BIGINT last_known_location_id FK
        BOOLEAN active
        TIMESTAMP deleted_at
    }

    NGOS {
        BIGINT id PK
        VARCHAR name
        VARCHAR registration_number UK
        VARCHAR email UK
        BIGINT headquarters_location_id FK
        BOOLEAN verified
        BOOLEAN active
        TIMESTAMP deleted_at
    }

    VOLUNTEERS {
        BIGINT id PK
        BIGINT user_id FK
        VARCHAR status
        BIGINT service_location_id FK
        BOOLEAN active
        TIMESTAMP deleted_at
    }

    VETERINARIANS {
        BIGINT id PK
        BIGINT user_id FK
        VARCHAR license_number UK
        VARCHAR clinic_name
        BIGINT clinic_location_id FK
        BOOLEAN active
        TIMESTAMP deleted_at
    }

    CASES {
        BIGINT id PK
        VARCHAR title
        VARCHAR status
        VARCHAR severity
        BIGINT reporter_id FK
        BIGINT animal_id FK
        BIGINT ngo_id FK
        BIGINT primary_volunteer_id FK
        BIGINT location_id FK
        BOOLEAN active
        TIMESTAMP deleted_at
    }

    CASE_VOLUNTEERS {
        BIGINT case_id FK
        BIGINT volunteer_id FK
    }

    NGO_VOLUNTEERS {
        BIGINT ngo_id FK
        BIGINT volunteer_id FK
    }

    DONATIONS {
        BIGINT id PK
        BIGINT donor_id FK
        BIGINT case_id FK
        NUMERIC amount
        VARCHAR currency
        VARCHAR status
        VARCHAR payment_reference UK
    }

    ADOPTION_APPLICATIONS {
        BIGINT id PK
        BIGINT case_id FK
        BIGINT animal_id FK
        BIGINT applicant_id FK
        VARCHAR status
        BIGINT decided_by_id FK
    }

    TREATMENTS {
        BIGINT id PK
        BIGINT animal_id FK
        BIGINT case_id FK
        BIGINT veterinarian_id FK
        VARCHAR status
        NUMERIC cost_amount
    }

    NOTIFICATIONS {
        BIGINT id PK
        BIGINT recipient_id FK
        VARCHAR type
        VARCHAR status
        VARCHAR title
    }

    AUDIT_LOGS {
        BIGINT id PK
        BIGINT actor_user_id FK
        VARCHAR action
        VARCHAR entity_type
        VARCHAR entity_id
    }

    REFRESH_TOKENS {
        BIGINT id PK
        BIGINT user_id FK
        VARCHAR token_hash UK
        TIMESTAMP expires_at
        TIMESTAMP revoked_at
    }

    USERS ||--o{ USER_ROLES : has
    ROLES ||--o{ USER_ROLES : grants
    LOCATIONS ||--o{ USERS : locates
    LOCATIONS ||--o{ ANIMALS : last_seen_at
    LOCATIONS ||--o{ NGOS : headquartered_at
    LOCATIONS ||--o{ VOLUNTEERS : serves
    LOCATIONS ||--o{ VETERINARIANS : clinic_at
    LOCATIONS ||--o{ CASES : reported_at
    USERS ||--o{ CASES : reports
    USERS ||--o{ DONATIONS : makes
    USERS ||--o{ ADOPTION_APPLICATIONS : submits
    USERS ||--o{ NOTIFICATIONS : receives
    USERS ||--o{ AUDIT_LOGS : performs
    USERS ||--o{ REFRESH_TOKENS : owns
    USERS ||--o| VOLUNTEERS : profile
    USERS ||--o| VETERINARIANS : profile
    ANIMALS ||--o{ CASES : involved_in
    ANIMALS ||--o{ TREATMENTS : receives
    ANIMALS ||--o{ ADOPTION_APPLICATIONS : applied_for
    NGOS ||--o{ CASES : coordinates
    NGOS ||--o{ NGO_VOLUNTEERS : includes
    VOLUNTEERS ||--o{ NGO_VOLUNTEERS : joins
    VOLUNTEERS ||--o{ CASES : primary_assignment
    VOLUNTEERS ||--o{ CASE_VOLUNTEERS : assigned_to
    CASES ||--o{ CASE_VOLUNTEERS : has
    CASES ||--o{ DONATIONS : funded_by
    CASES ||--o{ ADOPTION_APPLICATIONS : receives
    CASES ||--o{ TREATMENTS : treated_under
    VETERINARIANS ||--o{ TREATMENTS : provides
```

## MongoDB Documents

MongoDB is used for document-style data that should not drive PostgreSQL relational integrity:

| Document | Collection | Purpose |
| --- | --- | --- |
| `AiPrediction` | `ai_predictions` | Stores model/provider prediction output and metadata. |
| `ImageMetadata` | `image_metadata` | Stores image file metadata and labels. |
| `ChatLog` | `chat_logs` | Stores user/case chat transcripts and metadata. |
| `ApplicationLog` | `application_logs` | Stores structured application log events. |

