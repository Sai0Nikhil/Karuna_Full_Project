# Karuna Backend — Module Overview

This document summarizes every backend module in the Karuna Spring Boot application
(`com.karuna`). Each module is a vertical slice (controller + service + repository + entity +
mapper). For the cross-cutting architecture, see [architecture.md](architecture.md).

Base path convention: `/api/<module>`. All endpoints (except `/api/auth/**`) require a valid
JWT access token; method-level roles are noted per module.

---

## 1. Authentication Module

**Package:** `controller.AuthController`, `service.auth.*`, `security.*`
**Base path:** `/api/auth` (public)
**Entities:** `User`, `RefreshToken`, `VerificationToken`, `Role`

The foundation of the platform. Handles identity and session management without server-side
sessions.

Endpoints:

- `POST /api/auth/register` — create a user (default role `CITIZEN`), issue email-verification token, return token pair.
- `POST /api/auth/login` — authenticate, enforce lockout/verification, issue token pair.
- `POST /api/auth/refresh` — rotate refresh token, issue new pair.
- `POST /api/auth/logout` — revoke refresh token.
- `POST /api/auth/verify-email` — consume verification token.
- `POST /api/auth/forgot-password` — issue password-reset token (opaque response).
- `POST /api/auth/reset-password` — set new password, revoke all refresh tokens.
- `POST /api/auth/change-password` — change password for authenticated user (role: any authenticated).

Key components: `AuthenticationService` (orchestration), `PasswordService` (BCrypt +
policy), `JwtService` (HS256 tokens), `RefreshTokenService` (hashed storage + rotation),
`VerificationTokenService` (TTL tokens), `AuthenticationAuditService` (audit events),
`KarunaUserDetailsService` / `KarunaUserDetails` (Spring Security integration).

---

## 2. Rescue Cases Module

**Package:** `controller.RescueCaseController`, `service.RescueCaseService`,
`service.RescueCaseStatusMachine`
**Base path:** `/api/cases`
**Entity:** `RescueCase` (table `cases`)
**Repository:** `CaseRepository` + `repository.specification.RescueCaseSpecification`

Manages the central workflow object. Supports creation, filtered listing, assignment, and a
guarded status transition machine.

Endpoints:

- `POST /api/cases` — create (reporter = current user).
- `GET /api/cases` — paginated/filtered list (status, priority, reporterId, ngoId, volunteerId, search).
- `GET /api/cases/{id}` — get one.
- `PUT` / `PATCH /api/cases/{id}` — update.
- `DELETE /api/cases/{id}` — soft delete (roles: `ADMIN`, `NGO`, `VET`).
- `POST /api/cases/{id}/assign` — assign NGO/primary volunteer (roles: `ADMIN`, `NGO`, `VET`).
- `POST /api/cases/{id}/status` — transition status via `RescueCaseStatusMachine`.

Status values: `REPORTED`, `ASSIGNED`, `COLLECTED`, `AT_CLINIC`, `IN_TREATMENT`,
`DISCHARGED`, `ADOPTED`, `RELEASED`, `CANCELLED`. Priority: `ROUTINE`, `MEDIUM`, `HIGH`,
`CRITICAL`.

---

## 3. Animals Module

**Package:** `controller.AnimalController`, `service.AnimalService`
**Base path:** `/api/animals`
**Entity:** `Animal` (table `animals`)

Tracks individual animals and their attributes.

Endpoints: CRUD over animals (`GET`, `POST`, `PUT`/`PATCH`, `DELETE`) plus filtered search.
Fields include `species` (`AnimalSpecies`), `breed`, `condition` (`AnimalCondition`), `color`,
`sex`, `estimatedAge`, and `lastKnownLocation` (`Location`). Related to `RescueCase`,
`Treatment`, and `AdoptionApplication` (one-to-many).

---

## 4. NGOs Module

**Package:** `controller.NGOController`, `service.NGOService`
**Base path:** `/api/ngos`
**Entity:** `NGO` (table `ngos`)

Manages non-governmental organizations that own and coordinate rescue cases.

Endpoints: CRUD plus search. NGOs are referenced by `RescueCase.ngo` and appear in analytics
aggregations (`CaseNgoCount`, `DonationNgoCount`, `AdoptionNgoCount`).

---

## 5. Volunteers Module

**Package:** `controller.VolunteerController`, `service.VolunteerService`
**Base path:** `/api/volunteers`
**Entity:** `Volunteer` (table `volunteers`); linked one-to-one from `User.volunteerProfile`

Manages volunteer profiles, availability, and case assignment.

Endpoints: CRUD plus search. A volunteer can be a `primaryVolunteer` on a case and a member
of `case_volunteers` (many-to-many). Status: `AVAILABLE`, `BUSY`. Analytics report average
caseloads (`VolunteerCaseCount`).

---

## 6. Veterinarians Module

**Package:** `controller.VeterinarianController`, `service.VeterinarianService`
**Base path:** `/api/veterinarians`
**Entity:** `Veterinarian` (table `veterinarians`); linked one-to-one from `User.veterinarianProfile`

Manages veterinarian profiles and specializations.

Endpoints: CRUD plus search. Veterinarians own `Treatment` records and are analyzed by
active count, average caseload, and specialization distribution
(`VeterinarianSpecializationCount`, `VeterinarianCaseCount`).

---

## 7. Donations Module

**Package:** `controller.DonationController`, `service.DonationService`,
`service.DonationStatusMachine`, `payment.*`
**Base path:** `/api/donations`
**Entity:** `Donation` (table `donations`)

Records financial contributions tied to rescue cases.

Endpoints: CRUD plus status transitions via `DonationStatusMachine` and filtering. Supports
currency, amount, and a pluggable `PaymentProvider` abstraction (currently only
`DummyPaymentProvider`). Status: `PENDING`, `COMPLETED`, `FAILED`, `CANCELLED`. Analytics
aggregate totals, averages, currency, and monthly breakdowns
(`DonationCurrencyStat`, `DonationMonthCount`, `DonationNgoCount`).

---

## 8. Adoptions Module

**Package:** `controller.AdoptionController`, `service.AdoptionService`,
`service.AdoptionStatusMachine`
**Base path:** `/api/adoptions`
**Entity:** `AdoptionApplication` (table `adoption_applications`)

Manages adoption applications for animals.

Endpoints: CRUD plus status transitions via `AdoptionStatusMachine` and filtering. Each
application references an `Animal`, an `applicant` (`User`), and optionally an `NGO`/`RescueCase`.
Status: `PENDING`, `APPROVED`, `REJECTED`, `COMPLETED`, `WITHDRAWN`. Analytics compute
approval/rejection/completion rates and per-animal/per-NGO counts (`AdoptionAnimalCount`,
`AdoptionNgoCount`).

---

## 9. Analytics Module

**Package:** `controller.AnalyticsController`, `service.AnalyticsService`
**Base path:** `/api/analytics`
**Read-only:** yes (all methods `@Transactional(readOnly = true)`)

Aggregates operational metrics across all domains. No write side; it queries existing
repositories through count queries and JPQL group-by projections.

Endpoints:

- `GET /api/analytics/dashboard` — totals + distributions (cases, animals, donations, adoptions).
- `GET /api/analytics/cases` — monthly/NGO/volunteer/location breakdowns, resolution time, open vs. closed.
- `GET /api/analytics/animals` — species/condition distributions, by case/location.
- `GET /api/analytics/donations` — totals, currency, monthly, per-NGO.
- `GET /api/analytics/adoptions` — status distribution, approval/rejection/completion rates.
- `GET /api/analytics/volunteers` — availability, average caseload.
- `GET /api/analytics/veterinarians` — active count, average caseload, specialization mix.

DTOs: `AnalyticsDto.DashboardResponse`, `CaseAnalyticsResponse`, `AnimalAnalyticsResponse`,
`DonationAnalyticsResponse`, `AdoptionAnalyticsResponse`, `VolunteerAnalyticsResponse`,
`VeterinarianAnalyticsResponse`.

---

## 10. Users Module

**Package:** `controller.UserController`, `service` (user lookups)
**Base path:** `/api/users`
**Entity:** `User`

Exposes the authenticated user's profile and (for privileged roles) user administration.
Resolves the current principal via `SecurityUtils`. Closely tied to the Authentication module
which owns credential management.

---

## 11. AI Module (Placeholder)

**Package:** `controller.AIController`, `service.AIService`, `service.GeminiService`,
`service.ClaudeProvider`, `service.GeminiProvider`, `service.KarunaMemoryStore`
**Base path:** `/api/ai`

> **Not implemented.** These classes are scaffolding only. `AIController` exposes
> `GET /api/ai/health` (returns a health snapshot plus whether `GEMINI_API_KEY`/`CLAUDE_API_KEY`
> are configured) and `POST /api/ai/triage` (delegates to `KarunaMemoryStore`, a stub). No
> real model integration, persistence of predictions into workflow, or external calls are
> wired. Do not present AI triage as a working feature.

---

## 12. Cross-Cutting / Infrastructure Modules

These are not domain modules but underpin every request.

| Module | Package | Purpose |
| --- | --- | --- |
| Security | `security.auth`, `security.jwt`, `config.SecurityConfiguration` | Stateless JWT auth, BCrypt, method security, CORS, 401/403 handlers. |
| Configuration | `config` | Beans for security, CORS, OpenAPI, Mongo, cache, WebSocket, auditing, request logging, `KarunaProperties`. |
| Exceptions | `exception` | `GlobalExceptionHandler` → unified `ApiErrorResponse` for `BusinessException`, `ResourceNotFoundException`, `ConflictException`, `AccountLockedException`, `InvalidTokenException`. |
| Mapping | `mapper` | MapStruct mappers per entity + `DomainMapperConfig`. |
| DTOs | `dto`, `dto.domain` | API contract objects. |
| Payments | `payment` | `PaymentProvider` abstraction + `DummyPaymentProvider`. |
| Realtime | `config.RealtimeWebSocketHandler`, `service.RealtimeBroadcaster`, `WebSocketConfiguration` | WebSocket `/ws` infrastructure (not yet consumed by a workflow). |
| Actuator / Metrics | `config` + `spring-boot-actuator` + Micrometer/Prometheus | `/actuator/health`, `/actuator/prometheus`, `/actuator/info`. |
| OpenAPI | `config.OpenApiConfiguration` + springdoc | Swagger UI + `/v3/api-docs`. |
| Documents | `document` | MongoDB models: `ImageMetadata`, `ChatLog`, `ApplicationLog`, `AiPrediction`. |

---

## Module Dependency Summary

```
Auth ──▶ User, RefreshToken, VerificationToken, Role
Cases ──▶ Animal, NGO, Volunteer, Location, User, Donation, AdoptionApplication, Treatment
Animals ──▶ Location, RescueCase, Treatment, AdoptionApplication
NGOs ──▶ RescueCase, Donation, AdoptionApplication
Volunteers ──▶ User, RescueCase
Veterinarians ──▶ User, Treatment
Donations ──▶ User, RescueCase, NGO, PaymentProvider
Adoptions ──▶ User, Animal, NGO, RescueCase
Analytics ──▶ (read-only) Cases, Animals, NGOs, Volunteers, Veterinarians, Donations, Adoptions
Users ──▶ User (+ Volunteer/Veterinarian profiles)
AI ──▶ (placeholder; no real dependencies)
```
