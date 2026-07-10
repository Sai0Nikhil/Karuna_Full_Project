# Milestone 3 - Authentication & Authorization (JWT + Spring Security)

## Plan checkpoints
- [x] Create focused auth architecture (Controller -> AuthenticationService -> JwtService/RefreshTokenService/PasswordService/VerificationTokenService/Audit)

- [ ] Update configuration properties for JWT expirations, issuer/audience, password policy
- [ ] Add `VerificationToken` entity + `VerificationTokenType` + repository
- [ ] Add missing `RefreshTokenRepository` + any needed audit repository
- [ ] Implement `PasswordService` using BCrypt + configurable password policy + confirm password validation
- [ ] Implement `JwtService` with access/refresh JWTs (real JWT via jjwt)
- [ ] Implement Spring Security integration:
  - [ ] `CustomUserDetailsService`
  - [ ] `JwtAuthenticationFilter`
  - [ ] `JwtAuthenticationEntryPoint` + access denied handling
  - [ ] Update `SecurityConfiguration` (permit only /api/auth/** + docs/health; deny others; stateless; no httpBasic)
  - [ ] Enable method-level security
- [ ] Implement refresh token rotation + revocation + logout behavior
- [ ] Implement password recovery (forgot/reset) + verification token flow (verify-email)
- [ ] Add/extend auth endpoints in `AuthController` for all required routes
- [ ] Add audit logging for authentication events using `AuditLog`
- [ ] Standardize errors using existing `GlobalExceptionHandler`
- [ ] OpenAPI documentation for every auth endpoint (requests/responses + bearer config)

## Build verification
- [x] Run `mvn clean compile`
- [x] Run `mvn test`

## Technical debt to track
- [ ] Remaining auth hardening items (rate limiting hooks integration, etc.)

