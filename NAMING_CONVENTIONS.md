# KARUNA Naming Conventions

This document defines the strict naming conventions for the KARUNA repository to ensure consistency, maintainability, and clarity across all languages and frameworks used in the project.

## General Rules
- Use English only.
- Avoid abbreviations unless they are standard (JWT, DTO, API, UUID, HTTP).
- Avoid vague names such as Temp, Test, Data, Store, Manager, Helper, Utils (unless truly generic).
- Use descriptive and meaningful names.

## Java (Spring Boot)
- **Packages**: `lowercase` (e.g., `com.karuna.auth`, `com.karuna.notification`).
- **Classes**: `PascalCase` (e.g., `UserController`, `AuthenticationService`, `JwtAuthenticationFilter`). Avoid camelCase acronyms like `AiController`; use `AIController`.
- **Interfaces**: Do NOT prefix with "I" (e.g., `NotificationService`).
- **Methods**: `camelCase`. Must start with verbs (e.g., `createCase()`, `assignVolunteer()`). Avoid vague verbs like `process()` or `handle()` unless obvious.
- **Variables**: `camelCase` with meaningful names (e.g., `animalImage`, `donationAmount`). Avoid `img`, `obj`, `tmp`, `val`.
- **Constants**: `UPPER_SNAKE_CASE` (e.g., `JWT_SECRET`).
- **DTOs**: Must be suffixed with `DTO` (e.g., `CreateCaseRequestDTO`).
- **Entities**: Clean names without suffixes unless required by convention (e.g., `User`, `Animal`, `RescueCase`).
- **Repositories**: Must be suffixed with `Repository` (e.g., `UserRepository`).
- **Services**: Must be suffixed with `Service` (e.g., `AuthenticationService`).
- **Controllers**: Must be suffixed with `Controller` (e.g., `AuthenticationController`).
- **Configurations**: Must be suffixed with `Configuration` (e.g., `SecurityConfiguration`).
- **Exceptions**: Must be suffixed with `Exception` (e.g., `InvalidTokenException`).
- **Enums**: `PascalCase` for the enum name, `UPPER_SNAKE_CASE` for values.

## REST API Endpoints
- **Paths**: `lowercase kebab-case` (e.g., `/api/rescue-cases`, `/api/donation-history`). Do not use verbs or camelCase in paths.

## Database (SQL)
- **Tables**: `snake_case` (e.g., `users`, `animal_reports`, `rescue_cases`).
- **Columns**: `snake_case` (e.g., `created_at`, `assigned_volunteer_id`).
- **Scripts**: Descriptive versioned names (e.g., `V1__initial_schema.sql`).

## File & Folder Naming
- **Markdown**: `UPPERCASE.md` for standard docs (e.g., `README.md`, `ARCHITECTURE.md`).
- **Environment Variables**: `UPPER_SNAKE_CASE` (e.g., `POSTGRES_URL`).
- **Folders**: `lowercase-kebab-case` (e.g., `springboot`, `case-management`). Avoid camelCase or PascalCase.

## Frontend (React)
- **Components**: `PascalCase.tsx`.
- **Hooks**: `useSomething.ts`.
- **Contexts**: `SomethingContext.tsx`.
- **Utilities**: Descriptive `camelCase.ts` (e.g., `dateFormatter.ts`).
- **Constants**: `apiEndpoints.ts`.

## Mobile (Flutter)
- **Files**: `snake_case.dart`.
- **Classes**: `PascalCase`.
- **Variables**: `camelCase`.
