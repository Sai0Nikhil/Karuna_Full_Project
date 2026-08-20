# Karuna Backend — Phase 1 Implementation

> **Status:** ✅ Complete  
> **Date:** July 2026  
> **Branch:** `phase-1/flutter-backend-alignment`

---

## Overview

Phase 1 aligns the Spring Boot backend with the Flutter mobile app's data model and introduces a rule-based AI triage engine to replace the earlier stub services. All endpoints required by the Flutter `CaseModel`, `AIService`, and `ImageService` are now implemented.

---

## What Phase 1 Accomplished

### 1. Entity Expansion (`RescueCase`)
Added 11 new database columns to the `cases` table to carry Flutter-aligned metadata:

| Column | Type | Purpose |
|---|---|---|
| `image_url` | VARCHAR(500) | Photo URL from image upload |
| `location_label` | VARCHAR(255) | Human-readable location name |
| `latitude` | DOUBLE PRECISION | GPS latitude |
| `longitude` | DOUBLE PRECISION | GPS longitude |
| `species` | VARCHAR(100) | e.g. "dog", "cat", "bird" |
| `injury_type` | VARCHAR(100) | e.g. "bleeding", "fracture" |
| `probable_condition` | TEXT | AI-generated probable diagnosis |
| `first_aid_steps` | TEXT | JSON-serialized first aid list |
| `estimated_cost_inr` | INTEGER | AI-estimated treatment cost |
| `donated_amount_inr` | INTEGER | Crowdfunding total |
| `notes` | TEXT | Free-text field notes |

### 2. Database Migration
Flyway migration `V999__add_rescue_case_extended_fields.sql` applies all 11 `ALTER TABLE` statements idempotently (`IF NOT EXISTS`).

### 3. DTO Expansion (`RescueCaseDto`)
- `Request` — now accepts all new fields for case creation from Flutter
- `Update` — supports partial updates of all new fields
- `Response` — Flutter-aligned response includes:
  - `status` (lowercase string: `"reported"`, `"assigned"`, ...)
  - `severity` (lowercase string: `"critical"`, `"urgent"`, `"routine"`)
  - `imageDataUrl` alias for `imageUrl`
  - `reporterName`, `reporterContact`, `assignedResponder`, `ngo` (name strings)

### 4. Mapper Update (`RescueCaseMapper`)
- Maps `reporter.name` → `reporterName`, `reporter.email` → `reporterContact`
- Maps `ngo.name` → `ngo`
- Maps `primaryVolunteer.user.name` → `assignedResponder`
- Maps `imageUrl` → both `imageUrl` and `imageDataUrl`
- Converts `PriorityLevel` enum → `"critical"/"urgent"/"routine"` string via `@Named` converter

### 5. New Case Controller Endpoints
| Method | Path | Description |
|---|---|---|
| GET | `/api/cases/my` | Cases reported by the logged-in user |
| GET | `/api/cases/open` | All cases with status = `REPORTED` |

### 6. AI Triage Service (`AIService`)
Rule-based keyword triage engine replacing empty stubs:
- `analyzeText()` — classifies severity, generates first-aid steps, estimates cost
- `analyzePhoto()` — placeholder for YOLOv8 Phase 3; falls back to text analysis
- `getFirstAid()` — returns `immediateSteps[]`, `doNotDo[]`, `whenToCallVet`, `estimatedWaitAdvice`
- `getCaseSummary()` — headline, summary, urgency note, progress note, recommended next step

### 7. New AI Endpoints (`AIController`)
| Method | Path | Description |
|---|---|---|
| GET | `/api/ai/health` | AI service health check |
| POST | `/api/ai/analyze` | Text-based triage → severity + first aid |
| POST | `/api/ai/analyze-photo` | Photo-based triage (YOLOv8 stub) |
| POST | `/api/ai/firstaid` | First aid guidance by species + injury |
| GET | `/api/ai/summary/{caseId}` | Case summary for NGO dashboard |
| POST | `/api/ai/triage` | Legacy endpoint (delegates to `/analyze`) |

### 8. Image Upload (`ImageUploadController` + `WebMvcConfig`)
| Method | Path | Description |
|---|---|---|
| POST | `/api/upload/image` | Upload case photo; returns `{ imageUrl, filename }` |
| GET | `/uploads/**` | Serve uploaded images as static resources |

### 9. Deleted Stub Files
- `GeminiProvider.java` (empty stub)
- `ClaudeProvider.java` (empty stub)
- `GeminiService.java` (empty stub)

---

## New API Endpoints Summary

```
GET  /api/cases/my               → Page<RescueCaseDto.Response> (reporter = current user)
GET  /api/cases/open             → Page<RescueCaseDto.Response> (status = REPORTED)

GET  /api/ai/health              → { status, provider, yolov8Ready, message }
POST /api/ai/analyze             → { severity, probableCondition, injuryType, firstAidSteps[], estimatedCostInr, aiSummary, confidence }
POST /api/ai/analyze-photo       → same shape as /analyze
POST /api/ai/firstaid            → { immediateSteps[], doNotDo[], whenToCallVet, estimatedWaitAdvice }
GET  /api/ai/summary/{caseId}   → { headline, summary, urgencyNote, progressNote, recommendedNextStep }
POST /api/ai/triage              → (legacy; same as /analyze)

POST /api/upload/image           → { imageUrl, filename }
GET  /uploads/**                 → Serves uploaded images
```

---

## DB Schema Changes (V999)

Applied via Flyway on startup. Safe to run on existing databases — uses `IF NOT EXISTS`.

```sql
ALTER TABLE cases ADD COLUMN IF NOT EXISTS image_url VARCHAR(500);
ALTER TABLE cases ADD COLUMN IF NOT EXISTS location_label VARCHAR(255);
ALTER TABLE cases ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;
ALTER TABLE cases ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;
ALTER TABLE cases ADD COLUMN IF NOT EXISTS species VARCHAR(100);
ALTER TABLE cases ADD COLUMN IF NOT EXISTS injury_type VARCHAR(100);
ALTER TABLE cases ADD COLUMN IF NOT EXISTS probable_condition TEXT;
ALTER TABLE cases ADD COLUMN IF NOT EXISTS first_aid_steps TEXT;
ALTER TABLE cases ADD COLUMN IF NOT EXISTS estimated_cost_inr INTEGER;
ALTER TABLE cases ADD COLUMN IF NOT EXISTS donated_amount_inr INTEGER DEFAULT 0;
ALTER TABLE cases ADD COLUMN IF NOT EXISTS notes TEXT;
```

---

## Configuration

New environment variables (with defaults):

| Variable | Default | Purpose |
|---|---|---|
| `KARUNA_UPLOAD_DIR` | `uploads` | Local directory to store uploaded images |
| `KARUNA_UPLOAD_BASE_URL` | `http://localhost:8081` | Base URL prepended to image filenames |

---

## How to Run

```bash
# From springboot/ directory
./mvnw spring-boot:run

# Or with Docker Compose
docker compose up --build
```

### Test the AI endpoints

```bash
# Health check
curl http://localhost:8081/api/ai/health

# Text triage
curl -X POST http://localhost:8081/api/ai/analyze \
  -H "Content-Type: application/json" \
  -d '{"species":"dog","injuryType":"bleeding","description":"Hit by car, heavy bleeding from front leg","locationLabel":"MG Road"}'

# First aid guidance
curl -X POST http://localhost:8081/api/ai/firstaid \
  -H "Content-Type: application/json" \
  -d '{"species":"dog","injuryDescription":"fracture in hind leg","language":"English"}'

# Open cases
curl -H "Authorization: Bearer <token>" \
  http://localhost:8081/api/cases/open

# My cases
curl -H "Authorization: Bearer <token>" \
  http://localhost:8081/api/cases/my

# Upload image
curl -X POST http://localhost:8081/api/upload/image \
  -F "file=@/path/to/photo.jpg"
```

---

## Flutter CaseModel Field Mapping

| Flutter Field | Backend Source |
|---|---|
| `id` | `RescueCase.id` |
| `reporterName` | `reporter.name` |
| `reporterContact` | `reporter.email` |
| `species` | `RescueCase.species` |
| `injuryType` | `RescueCase.injuryType` |
| `severity` | Derived from `priority` enum → `"critical"/"urgent"/"routine"` |
| `status` | `caseStatus.name().toLowerCase()` |
| `locationLabel` | `RescueCase.locationLabel` |
| `latitude` | `RescueCase.latitude` |
| `longitude` | `RescueCase.longitude` |
| `probableCondition` | `RescueCase.probableCondition` |
| `firstAidSteps` | `RescueCase.firstAidSteps` (JSON string) |
| `assignedResponder` | `primaryVolunteer.user.name` |
| `ngo` | `ngo.name` |
| `estimatedCostInr` | `RescueCase.estimatedCostInr` |
| `notes` | `RescueCase.notes` |
| `imageDataUrl` | `RescueCase.imageUrl` (alias) |
| `createdAt` | `BaseEntity.createdAt` |

---

## What's Next — Phase 2

- **Donation & Crowdfunding Flow** — Wire `donatedAmountInr` to the `Donation` aggregate; add `POST /api/cases/{id}/donate`
- **Notification Service** — Push FCM notifications to volunteers when cases are assigned
- **Volunteer Geolocation Matching** — Match nearest available volunteer by lat/lon using PostGIS or Haversine query
- **Real-time Status Updates** — Broadcast case status changes via WebSocket to the Flutter app
- **Treatment Record API** — CRUD for `Treatment` entities linked to a case

## What's Next — Phase 3

- **YOLOv8 Integration** — Python sidecar service for animal detection and injury classification from photos
- **Gradient Boost Model** — Replace keyword-based severity classification with trained ML model
- **Multilingual First Aid** — Hindi/Tamil/Telugu translation of first aid instructions
- **Sita AI Chatbot** — Conversational triage via `/api/chat/sita` using Gemini/Claude
