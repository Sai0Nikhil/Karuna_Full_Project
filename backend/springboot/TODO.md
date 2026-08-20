# Milestone 3 - Authentication & Authorization (JWT + Spring Security)

## Plan checkpoints
- [x] Create focused auth architecture (Controller -> AuthenticationService -> JwtService/RefreshTokenService/PasswordService/VerificationTokenService/Audit)

- [x] Update configuration properties for JWT expirations, issuer/audience, password policy
- [x] Add `VerificationToken` entity + `VerificationTokenType` + repository
- [x] Add missing `RefreshTokenRepository` + any needed audit repository
- [x] Implement `PasswordService` using BCrypt + configurable password policy + confirm password validation
- [x] Implement `JwtService` with access/refresh JWTs (real JWT via jjwt)
- [x] Implement Spring Security integration:
  - [x] `CustomUserDetailsService`
  - [x] `JwtAuthenticationFilter`
  - [x] `JwtAuthenticationEntryPoint` + access denied handling
  - [x] Update `SecurityConfiguration` (permit only /api/auth/** + docs/health; deny others; stateless; no httpBasic)
  - [x] Enable method-level security
- [x] Implement refresh token rotation + revocation + logout behavior
- [x] Implement password recovery (forgot/reset) + verification token flow (verify-email)
- [x] Add/extend auth endpoints in `AuthController` for all required routes
- [x] Add audit logging for authentication events using `AuditLog`
- [x] Standardize errors using existing `GlobalExceptionHandler`
- [x] OpenAPI documentation for every auth endpoint (requests/responses + bearer config)

## Build verification
- [x] Run `mvn clean compile`
- [x] Run `mvn test`

## Technical debt to track
- [ ] Remaining auth hardening items (rate limiting hooks integration, etc.)

