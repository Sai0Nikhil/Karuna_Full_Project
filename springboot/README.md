# Karuna Backend

[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.3.13-brightgreen.svg)](https://spring.io/projects/spring-boot)
[![Java](https://img.shields.io/badge/Java-21-orange.svg)](https://www.oracle.com/java/)
[![License](https://img.shields.io/badge/license-Internal-blue.svg)](#license)

**Karuna** is a backend platform that coordinates animal rescue operations. It connects
citizens, NGOs, volunteers, and veterinarians around a single workflow: report a case,
triage and assign it, treat the animal, and (when appropriate) move it into adoption. The
backend also provides donations, analytics, and real-time notification infrastructure.

> The current codebase is the **infrastructure foundation** for the Karuna API. Domain
> services, persistence, security, and operations tooling are implemented; higher-level
> features such as the AI triage provider remain stubbed (see [Known Limitations](#known-limitations)).

---

## Table of Contents

- [Project Overview](#project-overview)
- [Key Features](#key-features)
- [Architecture Overview](#architecture-overview)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Module Breakdown](#module-breakdown)
- [Authentication Architecture](#authentication-architecture)
- [Repository Layer](#repository-layer)
- [Service Layer](#service-layer)
- [Controller Layer](#controller-layer)
- [DTO Layer](#dto-layer)
- [MapStruct Usage](#mapstruct-usage)
- [Spring Security](#spring-security)
- [JWT Authentication](#jwt-authentication)
- [Analytics Module](#analytics-module)
- [OpenAPI Integration](#openapi-integration)
- [Database Architecture](#database-architecture)
- [Flyway Migrations](#flyway-migrations)
- [MongoDB Usage](#mongodb-usage)
- [Configuration Profiles](#configuration-profiles)
- [Environment Variables](#environment-variables)
- [Running Locally](#running-locally)
- [Build Instructions](#build-instructions)
- [Testing Instructions](#testing-instructions)
- [API Documentation](#api-documentation)
- [Deployment Guide](#deployment-guide)
- [Known Limitations](#known-limitations)
- [Future Roadmap](#future-roadmap)
- [License](#license)
- [Contributors](#contributors)

---

## Project Overview

Karuna streamlines the lifecycle of an animal-rescue operation. A citizen reports a case,
an NGO or veterinarian picks it up, volunteers are assigned, treatments are recorded, and
the animal can eventually be adopted. Donations fund the work, and an analytics module
surfaces operational metrics to administrators.

The backend is a single Spring Boot application (`com.karuna`) organized around a classic
layered architecture: **controllers → services → repositories → database**, with a dedicated
security and configuration layer. The JPA domain model lives in PostgreSQL; document-shaped
metadata (images, chat logs, audit trails, AI predictions) lives in MongoDB.

### Design goals

- **Stateless, token-based security** — JWT access/refresh tokens, no server-side sessions.
- **Explicit, auditable operations** — every write is audited (`created_by`/`updated_by`,
  timestamps, optimistic locking, and soft deletes).
- **Type-safe DTO mapping** — MapStruct generates mappers at compile time; entities never
  leak directly into the API contract.
- **Testable business logic** — services are plain Spring beans with constructor injection,
  covered by unit tests.

---

## Key Features

| Area | Capability |
| --- | --- |
| Rescue cases | Create, search, filter, assign NGOs/volunteers, and transition case status through a guarded state machine. |
| Animals | Register and track animals (species, breed, condition) and their relationships to cases, treatments, and adoptions. |
| NGOs | Manage NGO records that own and coordinate rescue cases. |
| Volunteers | Manage volunteer profiles, availability, and per-case assignment. |
| Veterinarians | Manage veterinarian profiles, specializations, and case workloads. |
| Donations | Record donations with currency, status, and a pluggable payment provider abstraction. |
| Adoptions | Manage adoption applications through a status machine (pending → approved → completed). |
| Analytics | Aggregate dashboards for cases, animals, donations, adoptions, volunteers, and veterinarians. |
| Authentication | Registration, login, refresh, logout, email verification, and password reset with lockout policy. |
| Security | Role-based authorization (`@PreAuthorize`), stateless JWT filter, BCrypt password hashing. |
| Operations | Actuator health/probes, Prometheus metrics, CORS, request logging, OpenAPI/Swagger docs. |
| Realtime | WebSocket endpoint infrastructure for pushing updates to clients. |

---

## Architecture Overview

Karuna follows a **layered (n-tier) architecture** with clear separation of concerns:

```
HTTP client
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  Controller layer  (com.karuna.controller)                   │  REST endpoints, @Valid, OpenAPI annotations
└─────────────────────────────────────────────────────────────┘
    │  DTOs in / out
    ▼
┌─────────────────────────────────────────────────────────────┐
│  Service layer  (com.karuna.service, service.auth)           │  business rules, transactions, state machines
└─────────────────────────────────────────────────────────────┘
    │  entities ↔ DTOs via MapStruct mappers
    ▼
┌─────────────────────────────────────────────────────────────┐
│  Repository layer (com.karuna.repository, .specification)    │  Spring Data JPA + Specifications, Mongo repos
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  Persistence:  PostgreSQL (JPA)  +  MongoDB (documents)      │
└─────────────────────────────────────────────────────────────┘

Cross-cutting: com.karuna.config, com.karuna.security, com.karuna.exception
```

A full packet-level description (request flow, auth flow, entity relationships, service and
repository interactions) is available in [`docs/architecture.md`](docs/architecture.md).

---

## Technology Stack

| Concern | Technology |
| --- | --- |
| Language | Java 21 |
| Framework | Spring Boot 3.3.13 (Web, Security, Data JPA, Data MongoDB, Validation, Actuator, Cache, WebSocket) |
| Persistence (relational) | PostgreSQL + Spring Data JPA + Hibernate 6 |
| Persistence (document) | MongoDB + Spring Data MongoDB |
| Querying | Spring Data JPA Specifications, derived queries, JPQL `@Query` |
| Migrations | Flyway 10 (PostgreSQL) |
| Security | Spring Security 6, JWT (`jjwt` 0.12.6), BCrypt |
| Mapping | MapStruct 1.6.3 |
| API docs | springdoc-openapi 2.6.0 (Swagger UI, `/v3/api-docs`) |
| Metrics | Micrometer + Prometheus registry |
| Build | Maven (spring-boot-starter-parent) |
| Utilities | Lombok, `spring-boot-configuration-processor` |

---

## Project Structure

```
springboot/
├── pom.xml
├── .env.example
├── src/main/java/com/karuna/
│   ├── KarunaApplication.java
│   ├── config/            # Spring beans: security, CORS, OpenAPI, Mongo, caching, WebSocket
│   ├── controller/        # REST controllers (one per domain module)
│   ├── service/           # business logic + service/auth (auth flows, tokens, verification)
│   ├── repository/        # JPA repositories + specification/ (query filters)
│   ├── mapper/            # MapStruct DTO↔entity mappers
│   ├── dto/               # request/response DTOs + dto/domain (record DTOs)
│   ├── entity/            # JPA entities + entity/enums
│   ├── document/          # MongoDB documents
│   ├── security/          # auth (UserDetails) + jwt (filter, service, handlers)
│   ├── exception/         # domain exceptions + GlobalExceptionHandler
│   ├── payment/           # PaymentProvider abstraction + DummyPaymentProvider
│   └── config/KarunaProperties.java  # @ConfigurationProperties binding
├── src/main/resources/
│   ├── application.yml            # base config (env-var driven)
│   ├── application-dev.yml        # dev profile overrides
│   ├── application-prod.yml       # prod profile overrides
│   ├── application.properties     # imports optional .env file
│   └── db/migration/              # Flyway SQL migrations (V1..V7)
└── src/test/java/com/karuna/      # unit tests (service, security)
```

---

## Module Breakdown

Each backend module is a vertical slice consisting of a controller, one or more services,
JPA entities, repositories, and a MapStruct mapper. See [`docs/module-overview.md`](docs/module-overview.md)
for a per-module summary. The public REST base paths are:

| Module | Base path | Primary entity |
| --- | --- | --- |
| Authentication | `/api/auth` | `User`, `RefreshToken`, `VerificationToken` |
| Rescue Cases | `/api/cases` | `RescueCase` |
| Animals | `/api/animals` | `Animal` |
| NGOs | `/api/ngos` | `NGO` |
| Volunteers | `/api/volunteers` | `Volunteer` |
| Veterinarians | `/api/veterinarians` | `Veterinarian` |
| Donations | `/api/donations` | `Donation` |
| Adoptions | `/api/adoptions` | `AdoptionApplication` |
| Analytics | `/api/analytics` | aggregates (read-only) |
| Users | `/api/users` | `User` |
| AI (stub) | `/api/ai` | n/a |
| Health/Index | `/actuator`, `/` | n/a |

---

## Authentication Architecture

Authentication is handled by the `service.auth` package and the `security` package.

- **`AuthenticationService`** — orchestrates register, login, refresh, logout, email
  verification, and password reset. It composes `PasswordService`, `JwtService`,
  `RefreshTokenService`, `VerificationTokenService`, and `AuthenticationAuditService`.
- **`PasswordService`** — enforces the configurable password policy and wraps BCrypt encoding.
- **`RefreshTokenService`** — issues, validates, and revokes refresh tokens (stored in
  PostgreSQL, with a hash kept client-side).
- **`VerificationTokenService`** — issues and consumes email-verification and
  password-reset tokens with expiry.
- **`KarunaUserDetailsService`** — loads a `UserDetails` (`KarunaUserDetails`) from the
  `UserRepository`.
- **`AuthenticationAuditService`** — records authentication events to `AuditLog`.

The flow is **stateless**: after login the client receives an access token (short-lived) and
a refresh token (long-lived). Access is validated on every request by the JWT filter; refresh
rotates the token pair. Account protection includes failed-attempt counting and temporary
lockout (configurable via `karuna.security.login.*`).

---

## Repository Layer

Repositories are Spring Data JPA interfaces in `com.karuna.repository`. Most domain
repositories extend both `JpaRepository<T, ID>` and `JpaSpecificationExecutor<T>` so they
support derived queries **and** dynamic `Specification` filtering.

```java
@Repository
public interface CaseRepository extends JpaRepository<RescueCase, Long>,
                                         JpaSpecificationExecutor<RescueCase> {
    @EntityGraph(attributePaths = {"reporter", "animal", "ngo", "primaryVolunteer"})
    Page<RescueCase> findByStatus(CaseStatus status, Pageable pageable);

    @Query("select c.ngo.id as ngoId, c.ngo.name as ngoName, count(c) as count " +
           "from RescueCase c where c.ngo is not null group by c.ngo.id, c.ngo.name")
    List<CaseNgoCount> findCaseCountsByNgo();
}
```

Projection interfaces (e.g. `CaseNgoCount`, `DonationMonthCount`, `VolunteerCaseCount`) are
used for analytics queries to avoid loading full entities. Dynamic search/filter combos
(e.g. status, priority, reporter, NGO, volunteer, free-text) are encapsulated in the
`repository/specification` package as static `Specification` builders.

MongoDB documents use Spring Data MongoDB repositories (e.g. `ImageMetadataRepository`
style access) and are modeled in `com.karuna.document`.

---

## Service Layer

Services (`com.karuna.service`) contain business logic and own transaction boundaries via
`@Transactional`. They are constructor-injected (`@RequiredArgsConstructor`) and depend on
repositories and mappers — never on controllers.

- **Domain services** (`RescueCaseService`, `AnimalService`, `NGOService`,
  `VolunteerService`, `VeterinarianService`, `DonationService`, `AdoptionService`,
  `AnalyticsService`) implement CRUD, search, and domain-specific operations.
- **State machines** (`RescueCaseStatusMachine`, `DonationStatusMachine`,
  `AdoptionStatusMachine`) validate allowed status transitions.
- **Auth services** (`service.auth`) implement the authentication/authorization flows.

Example: `RescueCaseService.create(...)` maps the request to an entity, resolves referenced
associations (animal/NGO/volunteer/location), defaults the status, and persists within a
transaction, returning a mapped `RescueCaseDto.Response`.

---

## Controller Layer

Controllers (`com.karuna.controller`) are thin REST adapters. They:

- Map HTTP verbs to service calls (`@GetMapping`, `@PostMapping`, `@PutMapping`,
  `@PatchMapping`, `@DeleteMapping`).
- Validate input with `@Valid` and Bean Validation annotations on DTOs.
- Resolve the current principal via `SecurityUtils.requireCurrentUser(...)`.
- Enforce authorization with `@PreAuthorize("hasAnyRole('ADMIN','NGO','VET')")`.
- Document operations with `io.swagger.v3.oas.annotations` (`@Tag`, `@Operation`).

```java
@RestController
@RequestMapping("/api/cases")
@Tag(name = "Rescue Cases", description = "Rescue case management, search, assignment, and status workflow")
public class RescueCaseController {
    @PostMapping
    @Operation(summary = "Create a new rescue case")
    public ResponseEntity<RescueCaseDto.Response> create(@Valid @RequestBody RescueCaseDto.Request request) {
        User reporter = SecurityUtils.requireCurrentUser(userRepository);
        return ResponseEntity.ok(rescueCaseService.create(request, reporter));
    }
}
```

---

## DTO Layer

DTOs separate the API contract from persistence entities. They live in `com.karuna.dto`
(request/response command objects such as `LoginRequestDTO`, `CaseAssignmentDTO`) and
`com.karuna.dto.domain` (record-style projection DTOs such as `RescueCaseDto.Request`,
`RescueCaseDto.Response`, `RescueCaseDto.Update`, `AnalyticsDto.*`).

Conventions:

- `*.Request` — inbound payload for create.
- `*.Update` — inbound payload for full/partial update (mapped with `@MappingTarget`).
- `*.Response` / `*.Summary` — outbound projections.
- Command DTOs (e.g. `CaseStatusChangeDTO`) carry single-purpose action payloads.

Entities are never serialized directly; all responses pass through a MapStruct mapper.

---

## MapStruct Usage

Entity↔DTO conversion is handled by MapStruct mappers in `com.karuna.mapper`. Mappers are
interfaces annotated with `@Mapper(config = DomainMapperConfig.class)`; the implementation
is generated at compile time by the `mapstruct-processor` (wired in `pom.xml` as an
annotation processor along with `lombok-mapstruct-binding`).

```java
@Mapper(config = DomainMapperConfig.class)
public interface RescueCaseMapper {
    @Mapping(source = "caseStatus", target = "status")
    @Mapping(source = "reporter.id", target = "reporterId")
    RescueCaseDto.Response toResponse(RescueCase rescueCase);

    @Mapping(source = "status", target = "caseStatus")
    void updateEntity(RescueCaseDto.Update request, @MappingTarget RescueCase rescueCase);
}
```

This keeps the service layer free of manual mapping boilerplate and guarantees that nested
entity references are flattened to IDs in API responses.

---

## Spring Security

Security is configured in `com.karuna.config.SecurityConfiguration` (`@EnableWebSecurity`,
`@EnableMethodSecurity`). Key characteristics:

- **Stateless** — `SessionCreationPolicy.STATELESS`, CSRF disabled (no cookies), no
  form login / basic auth / logout endpoints (token-based instead).
- **CORS** — applied via `CorsConfigurationSource` built from `karuna.cors.*`.
- **Auth provider** — `DaoAuthenticationProvider` with `KarunaUserDetailsService` and a
  `BCryptPasswordEncoder`.
- **Filter order** — `JwtAuthenticationFilter` is registered before
  `UsernamePasswordAuthenticationFilter`.
- **Method security** — `@PreAuthorize` annotations enforce role checks on controllers.
- **Error handling** — `JwtAuthenticationEntryPoint` (401) and `JwtAccessDeniedHandler`
  (403) produce consistent JSON errors.

Public (permit-all) routes: `OPTIONS /**`, `/api/auth/**`, Swagger UI and `/v3/api-docs/**`,
and `actuator/health*`, `actuator/info`. All other requests require authentication;
`/actuator/**` requires the `ACTUATOR` role.

---

## JWT Authentication

JWT handling lives in `com.karuna.security.jwt` and uses `jjwt` 0.12.6.

- **`JwtService`** — builds HS256-signed tokens with configurable issuer/audience, access
  (default 15 min) and refresh (default 7 days) expirations, and claims
  (`username`, `role`, `token_type`). It validates signatures and expiry, distinguishes
  access vs. refresh tokens, and resolves bearer tokens from the `Authorization` header.
  The signing secret (`karuna.jwt.secret`) must be ≥ 256 bits (32 bytes); otherwise startup
  fails fast.
- **`JwtAuthenticationFilter`** — extracts the bearer token, validates it is an access
  token, loads `UserDetails`, and populates `SecurityContextHolder`.
- **`TokenHashService`** — stores a hash of refresh tokens rather than the raw token.

Token pair issued on login/refresh:

```json
{
  "token": "<access-jwt>",
  "accessToken": "<access-jwt>",
  "refreshToken": "<opaque-refresh-token>",
  "tokenType": "Bearer",
  "expiresIn": 900,
  "role": "CITIZEN",
  "userId": 1,
  "email": "user@example.com"
}
```

---

## Analytics Module

`AnalyticsService` (exposed via `/api/analytics`) computes read-only aggregates directly
from JPA repositories using derived count queries and JPQL group-by projections
(`CaseNgoCount`, `DonationMonthCount`, etc.). It exposes:

- **Dashboard** — totals (cases, animals, NGOs, volunteers, vets, donations, adoptions) plus
  distributions by status/priority/species/condition and donation amounts.
- **Case analytics** — monthly trends, NGO/volunteer/location breakdowns, average resolution
  time, and open vs. closed counts.
- **Animal analytics** — species/condition distributions and counts by rescue case / location.
- **Donation analytics** — totals, averages, currency and monthly breakdowns, per-NGO sums.
- **Adoption analytics** — status distribution and approval/rejection/completion rates.
- **Volunteer / Veterinarian analytics** — availability, average caseloads, and
  specialization distribution.

All methods are `@Transactional(readOnly = true)` and never mutate state.

---

## OpenAPI Integration

OpenAPI is provided by `springdoc-openapi` (springdoc 2.6.0) and configured in
`com.karuna.config.OpenApiConfiguration` from `karuna.open-api.*` properties. It produces a
programmatic `OpenAPI` bean with title, version, description, contact, license, and an
HTTP-bearer JWT security scheme (`bearerAuth`). Every controller and operation is annotated
with Swagger `@Tag`/`@Operation` metadata, so the generated spec reflects the real API.

---

## Database Architecture

Two datastores are used:

1. **PostgreSQL (primary relational store)** — all domain entities (`User`, `RescueCase`,
   `Animal`, `NGO`, `Volunteer`, `Veterinarian`, `Donation`, `AdoptionApplication`,
   `Treatment`, `Location`, `Role`, `RefreshToken`, `VerificationToken`, `AuditLog`,
   `Notification`) and their relationships.
2. **MongoDB (document store)** — schema-flexible documents such as `ImageMetadata`,
   `ChatLog`, `ApplicationLog`, and `AiPrediction`.

All JPA entities extend `BaseEntity`, which provides:

- `id` (auto-increment `Long`)
- `createdAt` / `updatedAt` (JPA auditing via `AuditingEntityListener`)
- `createdBy` / `updatedBy` (`@CreatedBy` / `@LastModifiedBy`)
- `version` (optimistic locking via `@Version`)
- `deletedAt` and a `@SQLRestriction("deleted_at IS NULL")` + `@SQLDelete` for **soft deletes**

`SpringSecurityAuditorAware` supplies the current principal for auditing fields.

---

## Flyway Migrations

Schema is versioned with Flyway (PostgreSQL). Migrations live in
`src/main/resources/db/migration`:

| Version | Purpose |
| --- | --- |
| `V1__initial_schema.sql` | Base tables |
| `V2__create_core_tables.sql` | Core domain tables |
| `V3__relationships.sql` | Foreign keys / join tables |
| `V4__indexes.sql` | Performance indexes |
| `V5__constraints.sql` | Additional constraints |
| `V6__verification_tokens.sql` | Email/reset token tables |
| `V7__user_account_security.sql` | Login lockout / security columns |

Flyway runs on startup (`flyway.enabled=true`, `classpath:db/migration`), with
`baseline-on-migrate=true`. `ddl-auto` is set to `validate` so Hibernate never mutates the
schema — Flyway is the single source of truth. `flyway.clean-disabled` is `true` in both
dev and prod.

---

## MongoDB Usage

MongoDB stores document-shaped, non-relational data modeled in `com.karuna.document`
(`@Document` classes). `MongoConfiguration` enables Mongo auditing and standardizes UUID
representation. Documents include:

- **`ImageMetadata`** — image references linked to `caseId`/`animalId` (indexed), with
  checksum, dimensions, storage key, and ML `labels`.
- **`ChatLog`** — conversation transcripts.
- **`ApplicationLog`** — application-level event logs.
- **`AiPrediction`** — triage/prediction outputs (placeholder for future AI features).

MongoDB is configured via `spring.data.mongodb.uri` and is intentionally decoupled from the
relational domain model.

---

## Configuration Profiles

The application is environment-driven through Spring profiles.

- **`dev`** (default in `.env.example`) — verbose SQL logging, `flyway.clean-disabled=true`,
  full health details, DEBUG Karuna logs. Activates the `dev` Maven profile (adds DevTools)
  and `application-dev.yml`.
- **`prod`** — conservative logging (`WARN` for SQL/security), no Swagger UI
  (`PROD_SPRINGDOC_SWAGGER_UI_ENABLED=false`), restricted health details. Uses
  `application-prod.yml`.
- **Default `/` (API index, health)** — always available.

Activate a profile with `SPRING_PROFILES_ACTIVE=dev|prod`. Config values are injected from
environment variables (see `.env.example`); `application.properties` imports an optional
`.env` file via `spring.config.import`.

---

## Environment Variables

All configuration is supplied through environment variables (see `.env.example`). Key groups:

| Variable | Description | Example |
| --- | --- | --- |
| `SPRING_PROFILES_ACTIVE` | Active profile | `dev` |
| `SPRING_APPLICATION_NAME` | App name / metric tag | `karuna-backend` |
| `SERVER_PORT` | HTTP port | `8081` |
| `POSTGRES_URL` / `POSTGRES_USERNAME` / `POSTGRES_PASSWORD` / `POSTGRES_DRIVER` | PostgreSQL datasource | `jdbc:postgresql://localhost:5432/karuna` |
| `MONGODB_URI` | MongoDB connection | `mongodb://localhost:27017/karuna` |
| `JPA_HIBERNATE_DDL_AUTO` | Schema mode (use `validate`) | `validate` |
| `FLYWAY_ENABLED` / `FLYWAY_LOCATIONS` / `FLYWAY_BASELINE_ON_MIGRATE` | Flyway control | `true` / `classpath:db/migration` / `true` |
| `ACTUATOR_USERNAME` / `ACTUATOR_PASSWORD` / `ACTUATOR_ROLES` | Actuator basic-auth user | `actuator` / `ACTUATOR` |
| `MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE` | Exposed actuator endpoints | `health,info,metrics,prometheus` |
| `KARUNA_CORS_ALLOWED_ORIGINS` / `*_METHODS` / `*_HEADERS` / `ALLOW_CREDENTIALS` | CORS policy | `http://localhost:3001` |
| `KARUNA_CACHE_NAMES` / `SPRING_CACHE_TYPE` | Caching | `health,openapi` / `simple` |
| `KARUNA_OPENAPI_*` | OpenAPI metadata & bearer auth | `Karuna API` / `true` |
| `KARUNA_WEBSOCKET_ENDPOINT` | WebSocket path | `/ws` |
| `KARUNA_JWT_SECRET` | HS256 secret (≥ 32 chars) | `replace-with-...` |
| `KARUNA_JWT_ACCESS_TOKEN_EXPIRATION` / `REFRESH_TOKEN_EXPIRATION` | Token lifetimes | `15m` / `7d` |
| `KARUNA_JWT_ISSUER` / `KARUNA_JWT_AUDIENCE` | JWT issuer / audience | `karuna-api` / `karuna-clients` |
| `KARUNA_PASSWORD_MIN_LENGTH` / `*_REQUIRE_*` | Password policy | `8` |
| `KARUNA_LOGIN_MAX_FAILED_ATTEMPTS` / `LOCK_DURATION` | Lockout policy | `5` / `15m` |
| `KARUNA_EMAIL_VERIFICATION_EXPIRATION` / `PASSWORD_RESET_EXPIRATION` | Token TTLs | `24h` / `1h` |
| `AI_PROVIDER` / `GEMINI_API_KEY` / `CLAUDE_API_KEY` | Optional AI keys (unused stubs) | `gemini` |

> Secrets are never committed. Copy `.env.example` to `.env` and fill in real values before
> running. The JWT secret and actuator password are mandatory.

---

## Running Locally

Prerequisites: **Java 21+**, **Maven 3.9+**, **PostgreSQL 15+**, **MongoDB 6+**.

```bash
# 1. Start datastores (example using Docker)
docker run -d --name karuna-pg -p 5432:5432 \
  -e POSTGRES_DB=karuna -e POSTGRES_USER=karuna -e POSTGRES_PASSWORD=karuna postgres:15
docker run -d --name karuna-mongo -p 27017:27017 mongo:6

# 2. Configure environment
cp .env.example .env
# edit .env and set KARUNA_JWT_SECRET and the passwords

# 3. Run the application (Spring Boot reads .env via spring.config.import)
./mvnw spring-boot:run
# or, on Windows:
mvnw.cmd spring-boot:run
```

The server starts on `SERVER_PORT` (default `8081`). Flyway applies migrations
automatically on startup.

---

## Build Instructions

```bash
# Package a runnable jar
./mvnw clean package

# Run the built artifact
java -jar target/karuna-backend-0.0.1-SNAPSHOT.jar

# Skip tests
./mvnw package -DskipTests
```

The build uses the `spring-boot-maven-plugin` and compiles MapStruct/Lombok via
annotation processors configured in `pom.xml`.

---

## Testing Instructions

Unit tests live in `src/test/java/com/karuna` and cover services and JWT/security
components (e.g. `JwtServiceTest`, `TokenHashServiceTest`, `AdoptionServiceTest`,
`AnalyticsServiceTest`, `AuthenticationServiceTest`, `PasswordServiceTest`).

```bash
# Run all tests
./mvnw test

# Run a single test class
./mvnw test -Dtest=JwtServiceTest

# Run with a specific profile
SPRING_PROFILES_ACTIVE=dev ./mvnw test
```

Tests use Mockito (with a `mockito-extensions` configuration present under
`src/test/resources`).

---

## API Documentation

The API is self-documenting through springdoc-openapi:

- **Swagger UI:** `http://localhost:8081/swagger-ui.html`
- **OpenAPI spec (JSON):** `http://localhost:8081/v3/api-docs`
- **OpenAPI spec (YAML):** `http://localhost:8081/v3/api-docs.yaml`

The spec reflects controllers, DTO schemas, and the `bearerAuth` security scheme. In
production the Swagger UI is disabled (`PROD_SPRINGDOC_SWAGGER_UI_ENABLED=false`) while the
JSON spec remains available.

### Swagger URL

```
http://localhost:8081/swagger-ui.html
```

### OpenAPI URL

```
http://localhost:8081/v3/api-docs
```

---

## Deployment Guide

Karuna is a standard 12-factor Spring Boot application suitable for container/orchestration
deployments.

1. **Build** the artifact: `./mvnw clean package` → `target/karuna-backend-*.jar`.
2. **Provision datastores** — PostgreSQL and MongoDB reachable via `POSTGRES_URL` /
   `MONGODB_URI`. Run Flyway migrations (they execute on startup; `ddl-auto=validate`).
3. **Inject environment** — set all required variables from [Environment Variables](#environment-variables),
   especially `KARUNA_JWT_SECRET`, `ACTUATOR_PASSWORD`, and DB credentials.
4. **Choose profile** — `SPRING_PROFILES_ACTIVE=prod`.
5. **Run** — `java -jar karuna-backend-*.jar`.
6. **Health & metrics** — expose `/actuator/health` (liveness/readiness probes) and
   `/actuator/prometheus` to your monitoring system. Restrict `/actuator/**` behind the
   `ACTUATOR` role / network policy.
7. **TLS & CORS** — terminate TLS at the ingress and set `karuna.cors.allowed-origins` to
   your frontend origins.

Because the app is stateless, it scales horizontally behind a load balancer with no
sticky-session requirement.

---

## Known Limitations

- **AI integration is not implemented.** The `AIController` (`/api/ai`) and related
  `AIService`, `GeminiService`, `ClaudeProvider`, `GeminiProvider`, and `KarunaMemoryStore`
  classes are placeholders only. The `ai.*` config and `GEMINI_API_KEY`/`CLAUDE_API_KEY`
  environment variables exist for future use but are not yet wired into any workflow. Do not
  advertise AI triage as available.
- **Real-time WebSocket** — the `/ws` endpoint and `RealtimeBroadcaster` provide
  infrastructure but are not yet consumed by a domain workflow.
- **Payments** — `PaymentProvider` is abstracted but only `DummyPaymentProvider` is present;
  no real payment gateway is integrated.
- **Email delivery** — verification/reset token issuance is implemented, but the outbound
  email transport is not yet wired.
- **No Rate limiting / MFA** — additional account-protection measures are not yet present.

---

## Future Roadmap

- Implement the AI triage provider (Gemini/Claude) and wire `AiPrediction` documents into the
  case workflow.
- Real payment gateway integration behind the `PaymentProvider` abstraction.
- Outbound email/SMS notification transport.
- Consume the WebSocket broadcaster for live case/assignment updates.
- Rate limiting, MFA, and enhanced audit reporting.
- Multi-tenancy / regional partitioning for NGOs.
- GraphQL alternative to REST for analytics dashboards.

---

## License

This project is currently licensed as an **Internal project** (see
`KARUNA_OPENAPI_LICENSE_NAME` in `.env.example`). A formal open-source license has not yet
been selected. The contents are not licensed for external redistribution at this time.

---

## Contributors

Maintained by the **Karuna Team**. Contributions follow standard GitHub flow (fork → branch
→ pull request). See `KARUNA_OPENAPI_CONTACT_NAME` for the contact of record.

To add yourself here, submit a pull request updating this section.
