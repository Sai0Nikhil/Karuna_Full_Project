package com.karuna.service.auth;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;

import com.karuna.config.KarunaProperties;
import com.karuna.dto.ForgotPasswordRequestDTO;
import com.karuna.dto.MessageResponseDTO;
import com.karuna.entity.User;
import com.karuna.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class AuthenticationServiceTest {

	@Mock
	private UserRepository userRepository;
	@Mock
	private PasswordService passwordService;
	@Mock
	private com.karuna.security.jwt.JwtService jwtService;
	@Mock
	private RefreshTokenService refreshTokenService;
	@Mock
	private VerificationTokenService verificationTokenService;
	@Mock
	private AuthenticationAuditService authenticationAuditService;
	@Mock
	private AuthenticationManager authenticationManager;

	private AuthenticationService authenticationService;

	@BeforeEach
	void setUp() {
		KarunaProperties properties = new KarunaProperties();
		authenticationService = new AuthenticationService(
				userRepository,
				passwordService,
				jwtService,
				refreshTokenService,
				verificationTokenService,
				authenticationAuditService,
				authenticationManager,
				properties);
	}

	@Test
	void forgotPasswordReturnsGenericMessageWhenUserMissing() {
		ForgotPasswordRequestDTO request = new ForgotPasswordRequestDTO();
		request.setEmail("missing@example.com");
		when(userRepository.findByEmail("missing@example.com")).thenReturn(Optional.empty());

		MessageResponseDTO response = authenticationService.forgotPassword(request, new ClientContext("127.0.0.1", "JUnit"));

		assertEquals("If an account exists for this email, password reset instructions have been sent.", response.getMessage());
		verify(verificationTokenService, never()).issuePasswordResetToken(any(), any());
	}

	@Test
	void loginFailsWithInvalidCredentials() {
		com.karuna.dto.LoginRequestDTO request = new com.karuna.dto.LoginRequestDTO();
		request.setEmail("user@example.com");
		request.setPassword("wrong-password");

		when(userRepository.findByEmail("user@example.com")).thenReturn(Optional.of(activeUser()));
		when(authenticationManager.authenticate(any(UsernamePasswordAuthenticationToken.class)))
				.thenThrow(new BadCredentialsException("Bad credentials"));

		assertThrows(BadCredentialsException.class,
				() -> authenticationService.login(request, new ClientContext("127.0.0.1", "JUnit")));
		verify(authenticationAuditService).loginFailure(any(User.class), any(ClientContext.class), any());
	}

	private User activeUser() {
		User user = new User();
		user.setId(1L);
		user.setEmail("user@example.com");
		user.setName("User");
		user.setPasswordHash("hash");
		user.setActive(true);
		user.setEmailVerified(true);
		return user;
	}
}
