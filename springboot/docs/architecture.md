# Karuna Backend — Architecture

This document describes the internal architecture of the Karuna Spring Boot backend
(`com.karuna`). It complements the [README](../README.md) and the
[module overview](module-overview.md).

- **Base package:** `com.karuna`
- **Entry point:** `KarunaApplication` (`@SpringBootApplication`, `@ConfigurationPropertiesScan`)
- **Runtime:** Spring Boot 3.3.13, Java 21
- **Datastores:** PostgreSQL (JPA) + MongoDB (documents)

---

## 1. Layered Architecture

Karuna uses a classic **layered (n-tier)** architecture. Dependencies point downward; the
presentation layer never touches persistence directly.

```
┌───────────────────────────────────────────────────────────────┐
│  Presentation / API        com.karuna.controller               │
│  - REST mapping, @Valid, @PreAuthorize, OpenAPI annotations    │
└───────────────────────────────────────────────────────────────┘
                              │  (DTOs in / out)
                              ▼
┌───────────────────────────────────────────────────────────────┐
│  Application / Service     com.karuna.service (+ service.auth) │
│  - business rules, @Transactional boundaries, state machines   │
└───────────────────────────────────────────────────────────────┘
                              │  (entities ↔ DTOs via mappers)
                              ▼
┌───────────────────────────────────────────────────────────────┐
│  Persistence / Repository  com.karuna.repository (+specification)│
│  - Spring Data JPA, Specifications, Mongo repositories          │
└───────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴────────────────┐
              ▼                                 ▼
      ┌───────────────┐                 ┌───────────────┐
      │  PostgreSQL   │                 │    MongoDB    │
      │  (JPA/Hibernate)                │ (Spring Data) │
      └───────────────┘                 └───────────────┘

Cross-cutting concerns:
      com.karuna.config      — beans: security, CORS, OpenAPI, Mongo, cache, WebSocket
      com.karuna.security    — auth (UserDetails) + jwt (filter, service, handlers)
      com.karuna.exception   — domain exceptions + GlobalExceptionHandler
      com.karuna.mapper      — MapStruct entity↔DTO mapping
      com.karuna.dto         — API contract objects
```

### Layer responsibilities

| Layer | Package | Responsibility | Allowed dependencies |
| --- | --- | --- | --- |
| Controller | `controller` | HTTP handling, validation, authorization guards, response shaping | Service, DTO, `SecurityUtils` |
| Service | `service`, `service.auth` | Business logic, transactions, state machines, auth flows | Repository, Mapper, DTO, Security |
| Repository | `repository`, `repository.specification` | Data access, querying, projections | Entity, Specification |
| Mapping | `mapper` | Compile-time entity↔DTO conversion | Entity, DTO |
| Config | `config` | Wiring of security, OpenAPI, Mongo, CORS, cache, WebSocket | Infrastructure beans |
| Security | `security` | Authentication/authorization primitives | Jwt, UserDetails, Repo |
| Exception | `exception` | Unified error model + handler | None (cross-cutting) |

---

## 2. Package Responsibilities

| Package | Responsibility |
| --- | --- |
| `com.karuna` | `KarunaApplication` entry point. |
| `config` | Spring beans: `SecurityConfiguration`, `CorsConfiguration`, `OpenApiConfiguration`, `MongoConfiguration`, `CacheConfiguration`, `WebSocketConfiguration`, `DatabaseConfiguration`, `RequestLoggingFilter`, `RealtimeWebSocketHandler`, `SpringSecurityAuditorAware`, and `KarunaProperties` (`@ConfigurationProperties`). |
| `controller` | REST endpoints per module plus `AuthController`, `UserController`, `AnalyticsController`, `HealthController`, `APIIndexController`, and the placeholder `AIController`. |
| `service` | Domain services and state machines. `service.auth` holds authentication orchestration (`AuthenticationService`, `PasswordService`, `RefreshTokenService`, `VerificationTokenService`, `AuthenticationAuditService`, `ClientContext`). |
| `repository` | JPA repositories and analytics projection interfaces; `repository.specification` holds `Specification` builders for dynamic filtering. |
| `mapper` | MapStruct mappers (`*Mapper`) and `DomainMapperConfig`. |
| `dto` | Command/response DTOs (`LoginRequestDTO`, `CaseAssignmentDTO`, …) and `dto.domain` record-DTOs (`RescueCaseDto`, `AnalyticsDto`, …). |
| `entity` | JPA entities and `entity.enums` (status/priority/role enums). All extend `BaseEntity`. |
| `document` | MongoDB `@Document` models (`ImageMetadata`, `ChatLog`, `ApplicationLog`, `AiPrediction`). |
| `security.auth` | `KarunaUserDetails`, `KarunaUserDetailsService`, `SecurityUtils`. |
| `security.jwt` | `JwtService`, `JwtAuthenticationFilter`, `JwtAuthenticationEntryPoint`, `JwtAccessDeniedHandler`, `TokenHashService`. |
| `exception` | `BusinessException`, `ResourceNotFoundException`, `ConflictException`, `AccountLockedException`, `InvalidTokenException`, `ApiErrorResponse`, `GlobalExceptionHandler`. |
| `payment` | `PaymentProvider` interface, `DummyPaymentProvider`, `PaymentRequest`/`PaymentResponse`. |

---

## 3. Request Flow

A typical read/write request flows as follows:

```
Client
  │  HTTP request + "Authorization: Bearer <access-jwt>"
  ▼
[Servlet container]
  │
  ├─ CORS filter (CorsConfigurationSource)            ── applies karuna.cors.*
  ├─ RequestLoggingFilter                             ── logs inbound request
  ├─ JwtAuthenticationFilter (once-per-request)       ── validates token, sets SecurityContext
  │
  ▼
SecurityFilterChain (SecurityConfiguration)
  │  authorizeHttpRequests: permitAll for /api/auth, swagger, actuator/health*
  │  anyRequest().authenticated(); method security via @PreAuthorize
  ▼
Controller  (e.g. RescueCaseController.create)
  │  @Valid @RequestBody  →  SecurityUtils.requireCurrentUser(repo)
  ▼
Service  (e.g. RescueCaseService.create)  @Transactional
  │  mapper.toEntity(request) → resolve associations → repository.save(entity)
  ▼
Repository (Spring Data JPA)  →  PostgreSQL
  │
  ▼
Mapper (MapStruct)  →  DTO.Response
  ▼
Controller ResponseEntity.ok(dto)  →  Client (JSON)
```

Notes:

- The JWT filter only populates the `SecurityContext` when a valid **access** token is
  present; otherwise the request proceeds unauthenticated and is rejected by
  `authorizeHttpRequests` unless the route is public.
- `SecurityUtils.requireCurrentUser(UserRepository)` is the standard way controllers resolve
  the authenticated `User` entity.
- All write paths are `@Transactional`; read paths use `@Transactional(readOnly = true)`.

---

## 4. Authentication Flow

Authentication is fully stateless and token-based. The flow is implemented across
`service.auth.AuthenticationService`, `security.jwt.JwtService`, `RefreshTokenService`, and
`JwtAuthenticationFilter`.

### 4.1 Login

```
POST /api/auth/login  { email, password, role? }
        │
        ▼
AuthenticationService.login
  ├─ lookup user by email
  ├─ assertAccountAccessible (active, not deleted, not locked)
  ├─ authenticationManager.authenticate(UserDetails/BCrypt)
  │     └─ on failure: recordFailedLogin → lock after threshold → 401
  ├─ assertEmailVerified
  ├─ resetFailedLoginAttempts
  ├─ AuthenticationAuditService.loginSuccess
  └─ issueTokenPair:
        access  = JwtService.generateAccessToken(subject=userId, claims{username,role})
        refresh = RefreshTokenService.createRefreshToken (stored hashed in PostgreSQL)
        ▼
201 → { accessToken, refreshToken, tokenType:"Bearer", expiresIn, role, userId, email }
```

### 4.2 Per-request authentication (filter)

```
Inbound request
  └─ JwtAuthenticationFilter.doFilterInternal
        resolveBearerToken(header)
        ├─ validateToken (signature + expiry + audience)
        ├─ isAccessToken
        ├─ extractUsername (email) → userDetailsService.loadUserByUsername
        └─ SecurityContextHolder.setAuthentication(UsernamePasswordAuthenticationToken)
```

### 4.3 Refresh / logout

- **Refresh:** `POST /api/auth/refresh` validates the opaque refresh token
  (`RefreshTokenService.validateAndGet`), revokes it, and issues a **new** token pair
  (rotation).
- **Logout:** `POST /api/auth/logout` revokes the presented refresh token
  (`refreshTokenService.revoke`).

### 4.4 Account protection

`AuthenticationService` enforces a configurable lockout: after
`karuna.security.login.max-failed-attempts` failures the account is temporarily locked for
`karuna.security.login.lock-duration`. Email verification (`/api/auth/verify-email`) and
password reset (`/api/auth/forgot-password`, `/reset-password`) use
`VerificationTokenService` with TTLs from `karuna.security.verification.*`.

---

## 5. Authorization Flow

Authorization has two layers:

1. **URL-level** — `SecurityConfiguration.authorizeHttpRequests`:
   - `OPTIONS /**`, `/api/auth/**`, Swagger UI, `/v3/api-docs/**`, `actuator/health*`,
     `actuator/info` → `permitAll`.
   - `/actuator/**` → `hasRole("ACTUATOR")`.
   - Everything else → `authenticated`.
2. **Method-level** — `@EnableMethodSecurity` + `@PreAuthorize` on controllers, e.g.:
   - `RescueCaseController.delete` / `.assign` → `hasAnyRole('ADMIN','NGO','VET')`.

Roles are stored as the `UserRole` enum (`CITIZEN`, `NGO`, `VOLUNTEER`, `VET`, `ADMIN`) and
surfaced to Spring Security as `ROLE_<NAME>` authorities via `KarunaUserDetails`. The role
claim is also embedded in the JWT for convenience.

---

## 6. Entity Relationships

All JPA entities extend `BaseEntity` (id, timestamps, auditing fields, `@Version`, soft
delete via `deleted_at`). Cardinalities below are the core domain relationships.

```
User (1) ──< (N) RescueCase            (reporter)
User (1) ──< (N) Donation              (donor)
User (1) ──< (N) AdoptionApplication   (applicant)
User (1) ──1 (1) Volunteer             (volunteerProfile, cascade)
User (1) ──1 (1) Veterinarian          (veterinarianProfile, cascade)
User (N) ──< (N) Role                  (join table user_roles)
User (N) ──1 (1) Location              (location)

RescueCase (N) ──1 Animal              (animal)
RescueCase (N) ──1 NGO                 (ngo)
RescueCase (N) ──1 Volunteer           (primaryVolunteer)
RescueCase (N) ──< (N) Volunteer       (assignedVolunteers, join table case_volunteers)
RescueCase (N) ──1 Location            (geoLocation)
RescueCase (1) ──< (N) Donation
RescueCase (1) ──< (N) AdoptionApplication
RescueCase (1) ──< (N) Treatment

Animal (1) ──< (N) RescueCase
Animal (1) ──< (N) Treatment
Animal (1) ──< (N) AdoptionApplication
Animal (N) ──1 Location                (lastKnownLocation)

NGO (1) ──< (N) RescueCase
Volunteer (1) ──< (N) RescueCase       (primary/assigned)
Veterinarian (1) ──< (N) Treatment

RefreshToken (N) ──1 User
VerificationToken (N) ──1 User
AuditLog (records auth/domain events)
Notification (N) ──1 User               (recipient)
```

Key enumerations (`entity.enums`): `UserRole`, `CaseStatus`, `PriorityLevel`,
`AnimalSpecies`, `AnimalCondition`, `DonationStatus`, `AdoptionStatus`, `TreatmentStatus`,
`VolunteerStatus`, `NotificationStatus`, `NotificationType`, plus `VerificationTokenType`.

---

## 7. Service Interactions

- **Domain services** depend on repositories and mappers only. Example:
  `RescueCaseService` uses `CaseRepository`, `AnimalRepository`, `NGORepository`,
  `VolunteerRepository`, `LocationRepository`, and `RescueCaseMapper`.
- **Cross-module reads** are最常见的 in analytics: `AnalyticsService` aggregates across
  `CaseRepository`, `AnimalRepository`, `DonationRepository`,
  `AdoptionApplicationRepository`, `VolunteerRepository`, `VeterinarianRepository`, and
  `NGORepository`.
- **Auth services** collaborate tightly: `AuthenticationService` → `PasswordService`,
  `JwtService`, `RefreshTokenService`, `VerificationTokenService`,
  `AuthenticationAuditService`, and `AuthenticationManager`.
- **State machines** (`*StatusMachine`) are invoked by services before persisting a status
  change (e.g. `RescueCaseService.changeStatus` calls
  `RescueCaseStatusMachine.validate(...)`).
- **Mappers** are injected into services to convert between entities and
  `dto.domain` records; services never serialize entities directly.

---

## 8. Repository Interactions

- Most repositories extend `JpaRepository<T, Long>` **and**
  `JpaSpecificationExecutor<T>`, enabling both derived queries and dynamic
  `Specification` filtering (e.g. `RescueCaseSpecification.withFilters(...)`).
- **Derived queries** handle common lookups (`findByStatus`, `findByNgoId`,
  `countByPriority`).
- **JPQL `@Query` projections** power analytics via lightweight interfaces
  (`CaseNgoCount`, `CaseMonthCount`, `CaseLocationCount`, `DonationMonthCount`,
  `DonationCurrencyStat`, `VolunteerCaseCount`, `VeterinarianSpecializationCount`,
  `AdoptionAnimalCount`, `AdoptionNgoCount`, `AnimalRescueCaseCount`,
  `AnimalLocationCount`). These avoid loading full entities for aggregates.
- **`@EntityGraph`** is used on read paths that need associations eagerly loaded
  (e.g. `CaseRepository.findByStatus` fetches `reporter`, `animal`, `ngo`,
  `primaryVolunteer`) to prevent N+1 queries.
- **Specifications** build `Predicate` lists from optional filters (status, priority,
  reporter, NGO, volunteer, free-text search) and are combined with
  `repository.findAll(specification, pageable)`.
- **MongoDB** documents (`com.karuna.document`) are accessed through Spring Data MongoDB
  repositories and are not part of the JPA transaction graph.
