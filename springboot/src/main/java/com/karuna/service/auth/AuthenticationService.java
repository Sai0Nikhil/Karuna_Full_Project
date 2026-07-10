package com.karuna.service.auth;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.Optional;

import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.AuthenticationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import com.karuna.config.KarunaProperties;
import com.karuna.dto.AuthLogoutRequestDTO;
import com.karuna.dto.AuthRefreshRequestDTO;
import com.karuna.dto.AuthResponseDTO;
import com.karuna.dto.ChangePasswordRequestDTO;
import com.karuna.dto.ForgotPasswordRequestDTO;
import com.karuna.dto.LoginRequestDTO;
import com.karuna.dto.MessageResponseDTO;
import com.karuna.dto.RegisterRequestDTO;
import com.karuna.dto.ResetPasswordRequestDTO;
import com.karuna.dto.VerifyEmailRequestDTO;
import com.karuna.entity.RefreshToken;
import com.karuna.entity.User;
import com.karuna.exception.AccountLockedException;
import com.karuna.exception.BusinessException;
import com.karuna.exception.ConflictException;
import com.karuna.exception.InvalidTokenException;
import com.karuna.repository.UserRepository;
import com.karuna.security.jwt.JwtService;

@Service
public class AuthenticationService {

	private final UserRepository userRepository;
	private final PasswordService passwordService;
	private final JwtService jwtService;
	private final RefreshTokenService refreshTokenService;
	private final VerificationTokenService verificationTokenService;
	private final AuthenticationAuditService authenticationAuditService;
	private final AuthenticationManager authenticationManager;
	private final KarunaProperties.Security.Login loginSettings;

	public AuthenticationService(
			UserRepository userRepository,
			PasswordService passwordService,
			JwtService jwtService,
			RefreshTokenService refreshTokenService,
			VerificationTokenService verificationTokenService,
			AuthenticationAuditService authenticationAuditService,
			AuthenticationManager authenticationManager,
			KarunaProperties karunaProperties) {
		this.userRepository = userRepository;
		this.passwordService = passwordService;
		this.jwtService = jwtService;
		this.refreshTokenService = refreshTokenService;
		this.verificationTokenService = verificationTokenService;
		this.authenticationAuditService = authenticationAuditService;
		this.authenticationManager = authenticationManager;
		this.loginSettings = karunaProperties.getSecurity().getLogin();
	}

	@Transactional
	public AuthResponseDTO register(RegisterRequestDTO request, ClientContext clientContext) {
		passwordService.validatePasswordPolicy(request.getPassword());

		if (userRepository.findByEmail(request.getEmail()).isPresent()) {
			throw new ConflictException("Email already registered");
		}

		User user = new User();
		user.setName(request.getName());
		user.setEmail(request.getEmail());
		user.setPasswordHash(passwordService.encode(request.getPassword()));
		user.setRole(StringUtils.hasText(request.getRole()) ? request.getRole() : "CITIZEN");
		user.setEmailVerified(false);
		user.setActive(true);
		userRepository.save(user);

		verificationTokenService.issueEmailVerificationToken(user, clientContext);
		authenticationAuditService.registration(user, clientContext);

		return issueTokenPair(user, clientContext);
	}

	@Transactional
	public AuthResponseDTO login(LoginRequestDTO request, ClientContext clientContext) {
		Optional<User> userOptional = userRepository.findByEmail(request.getEmail());
		User user = userOptional.orElse(null);

		if (user != null) {
			assertAccountAccessible(user);
		}

		try {
			authenticationManager.authenticate(
					new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword()));
		} catch (AuthenticationException ex) {
			if (user != null) {
				recordFailedLogin(user);
				authenticationAuditService.loginFailure(user, clientContext, ex.getMessage());
			}
			throw new BadCredentialsException("Invalid credentials");
		}

		user = userRepository.findByEmail(request.getEmail())
				.orElseThrow(() -> new BadCredentialsException("Invalid credentials"));

		assertAccountAccessible(user);
		assertEmailVerified(user);

		if (StringUtils.hasText(request.getRole()) && !user.getRole().equalsIgnoreCase(request.getRole())) {
			throw new BusinessException("This account is registered as " + user.getRole());
		}

		resetFailedLoginAttempts(user);
		authenticationAuditService.loginSuccess(user, clientContext);

		return issueTokenPair(user, clientContext);
	}

	@Transactional
	public AuthResponseDTO refresh(AuthRefreshRequestDTO request, ClientContext clientContext) {
		RefreshToken storedToken = refreshTokenService.validateAndGet(request.getRefreshToken());
		User user = storedToken.getUser();

		assertAccountAccessible(user);
		assertEmailVerified(user);

		refreshTokenService.revoke(storedToken);
		authenticationAuditService.refresh(user, clientContext);

		return issueTokenPair(user, clientContext);
	}

	@Transactional
	public MessageResponseDTO logout(AuthLogoutRequestDTO request, ClientContext clientContext) {
		try {
			RefreshToken storedToken = refreshTokenService.validateAndGet(request.getRefreshToken());
			refreshTokenService.revoke(storedToken);
			authenticationAuditService.logout(storedToken.getUser(), clientContext);
		} catch (InvalidTokenException ex) {
			refreshTokenService.revokeByRawToken(request.getRefreshToken());
		}

		return new MessageResponseDTO("Logged out successfully");
	}

	@Transactional
	public MessageResponseDTO forgotPassword(ForgotPasswordRequestDTO request, ClientContext clientContext) {
		userRepository.findByEmail(request.getEmail()).ifPresent(user -> {
			verificationTokenService.issuePasswordResetToken(user, clientContext);
			authenticationAuditService.passwordResetRequested(user, clientContext);
		});

		return new MessageResponseDTO("If an account exists for this email, password reset instructions have been sent.");
	}

	@Transactional
	public MessageResponseDTO resetPassword(ResetPasswordRequestDTO request, ClientContext clientContext) {
		passwordService.validatePasswordPolicy(request.getNewPassword());

		User user = verificationTokenService.consumePasswordResetToken(request.getToken());
		user.setPasswordHash(passwordService.encode(request.getNewPassword()));
		resetFailedLoginAttempts(user);
		userRepository.save(user);

		refreshTokenService.revokeAllForUser(user.getId());
		authenticationAuditService.passwordReset(user, clientContext);

		return new MessageResponseDTO("Password has been reset successfully");
	}

	@Transactional
	public MessageResponseDTO changePassword(
			ChangePasswordRequestDTO request,
			User currentUser,
			ClientContext clientContext) {
		if (!passwordService.matches(request.getCurrentPassword(), currentUser.getPasswordHash())) {
			throw new BadCredentialsException("Current password is incorrect");
		}

		passwordService.validatePasswordPolicy(request.getNewPassword());
		currentUser.setPasswordHash(passwordService.encode(request.getNewPassword()));
		userRepository.save(currentUser);

		refreshTokenService.revokeAllForUser(currentUser.getId());
		authenticationAuditService.passwordChange(currentUser, clientContext);

		return new MessageResponseDTO("Password changed successfully");
	}

	@Transactional
	public MessageResponseDTO verifyEmail(VerifyEmailRequestDTO request, ClientContext clientContext) {
		User user = verificationTokenService.consumeEmailVerificationToken(request.getToken());
		user.setEmailVerified(true);
		userRepository.save(user);
		authenticationAuditService.emailVerification(user, clientContext);

		return new MessageResponseDTO("Email verified successfully");
	}

	private AuthResponseDTO issueTokenPair(User user, ClientContext clientContext) {
		Map<String, Object> claims = Map.of(
				JwtService.CLAIM_USERNAME, user.getEmail(),
				JwtService.CLAIM_ROLE, user.getRole());

		String accessToken = jwtService.generateAccessToken(String.valueOf(user.getId()), claims);
		String refreshToken = refreshTokenService.createRefreshToken(user, clientContext);

		AuthResponseDTO response = new AuthResponseDTO();
		response.setToken(accessToken);
		response.setAccessToken(accessToken);
		response.setRefreshToken(refreshToken);
		response.setTokenType("Bearer");
		response.setExpiresIn(jwtService.getAccessTokenExpiration().toSeconds());
		response.setRole(user.getRole());
		response.setUserId(user.getId());
		response.setName(user.getName());
		response.setEmail(user.getEmail());
		response.setUser(Map.of(
				"id", user.getId(),
				"name", user.getName(),
				"email", user.getEmail(),
				"role", user.getRole(),
				"emailVerified", user.isEmailVerified()));
		return response;
	}

	private void assertAccountAccessible(User user) {
		if (user.getDeletedAt() != null || !user.isActive()) {
			throw new BusinessException(HttpStatus.FORBIDDEN, "ACCOUNT_DISABLED", "Account is disabled");
		}
		if (isTemporarilyLocked(user)) {
			throw new AccountLockedException("Account is temporarily locked. Try again later.");
		}
		if (user.isAccountLocked()) {
			throw new AccountLockedException("Account is locked");
		}
	}

	private void assertEmailVerified(User user) {
		if (!user.isEmailVerified()) {
			throw new BusinessException(HttpStatus.FORBIDDEN, "EMAIL_NOT_VERIFIED", "Email address is not verified");
		}
	}

	private boolean isTemporarilyLocked(User user) {
		return user.getLockedUntil() != null && user.getLockedUntil().isAfter(LocalDateTime.now());
	}

	private void recordFailedLogin(User user) {
		int attempts = user.getFailedLoginAttempts() + 1;
		user.setFailedLoginAttempts(attempts);
		if (attempts >= loginSettings.getMaxFailedAttempts()) {
			user.setLockedUntil(LocalDateTime.now().plus(loginSettings.getLockDuration()));
			user.setFailedLoginAttempts(0);
		}
		userRepository.save(user);
	}

	private void resetFailedLoginAttempts(User user) {
		user.setFailedLoginAttempts(0);
		user.setLockedUntil(null);
		userRepository.save(user);
	}
}
