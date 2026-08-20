package com.karuna.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

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
import com.karuna.dto.GoogleAuthRequestDTO;
import com.karuna.entity.User;
import com.karuna.repository.UserRepository;
import com.karuna.security.auth.SecurityUtils;
import com.karuna.service.auth.AuthenticationService;
import com.karuna.service.auth.ClientContext;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.security.SecurityRequirements;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/auth")
@Tag(name = "Authentication", description = "Registration, login, token refresh, logout, and account recovery")
public class AuthController {

	private final AuthenticationService authenticationService;
	private final UserRepository userRepository;

	public AuthController(AuthenticationService authenticationService, UserRepository userRepository) {
		this.authenticationService = authenticationService;
		this.userRepository = userRepository;
	}

	@PostMapping("/register")
	@SecurityRequirements
	@Operation(summary = "Register a new user account")
	@io.swagger.v3.oas.annotations.parameters.RequestBody(description = "Account registration details",
			content = @Content(schema = @Schema(implementation = RegisterRequestDTO.class),
					examples = @ExampleObject(value = """
							{
							  "name": "Ravi Kumar",
							  "email": "ravi@example.com",
							  "password": "Str0ngP@ssw0rd",
							  "confirmPassword": "Str0ngP@ssw0rd",
							  "role": "CITIZEN"
							}""")))
	@ApiResponse(responseCode = "200", description = "Registration successful",
			content = @Content(schema = @Schema(implementation = AuthResponseDTO.class),
					examples = @ExampleObject(value = """
							{
							  "access_token": "eyJhbGciOiJIUzI1NiJ9...",
							  "refresh_token": "eyJhbGciOiJIUzI1NiJ9...",
							  "token_type": "Bearer",
							  "expires_in": 900,
							  "role": "CITIZEN",
							  "userId": 1,
							  "name": "Ravi Kumar",
							  "email": "ravi@example.com",
							  "user": {
								"id": 1,
								"name": "Ravi Kumar",
								"email": "ravi@example.com",
								"role": "CITIZEN",
								"emailVerified": false
							  }
							}""")))
	public ResponseEntity<AuthResponseDTO> register(
			@Valid @RequestBody RegisterRequestDTO request,
			HttpServletRequest servletRequest) {
		return ResponseEntity.ok(authenticationService.register(request, clientContext(servletRequest)));
	}

	@PostMapping("/login")
	@SecurityRequirements
	@Operation(summary = "Authenticate with email and password")
	@io.swagger.v3.oas.annotations.parameters.RequestBody(description = "Login credentials",
			content = @Content(schema = @Schema(implementation = LoginRequestDTO.class),
					examples = @ExampleObject(value = """
							{
							  "email": "ravi@example.com",
							  "password": "Str0ngP@ssw0rd",
							  "role": "CITIZEN"
							}""")))
	@ApiResponse(responseCode = "200", description = "Login successful",
			content = @Content(schema = @Schema(implementation = AuthResponseDTO.class),
					examples = @ExampleObject(value = """
							{
							  "access_token": "eyJhbGciOiJIUzI1NiJ9...",
							  "refresh_token": "eyJhbGciOiJIUzI1NiJ9...",
							  "token_type": "Bearer",
							  "expires_in": 900,
							  "role": "CITIZEN",
							  "userId": 1,
							  "name": "Ravi Kumar",
							  "email": "ravi@example.com"
							}""")))
	public ResponseEntity<AuthResponseDTO> login(
			@Valid @RequestBody LoginRequestDTO request,
			HttpServletRequest servletRequest) {
		return ResponseEntity.ok(authenticationService.login(request, clientContext(servletRequest)));
	}

	@PostMapping("/google")
	@SecurityRequirements
	@Operation(summary = "Authenticate with Google ID token")
	public ResponseEntity<AuthResponseDTO> googleLogin(
			@Valid @RequestBody GoogleAuthRequestDTO request,
			HttpServletRequest servletRequest) {
		return ResponseEntity.ok(authenticationService.googleLogin(request, clientContext(servletRequest)));
	}

	@PostMapping("/refresh")
	@SecurityRequirements
	@Operation(summary = "Rotate refresh token and issue a new access token")
	@io.swagger.v3.oas.annotations.parameters.RequestBody(description = "Refresh token to rotate",
			content = @Content(schema = @Schema(implementation = AuthRefreshRequestDTO.class),
					examples = @ExampleObject(value = """
							{
							  "refreshToken": "eyJhbGciOiJIUzI1NiJ9..."
							}""")))
	@ApiResponse(responseCode = "200", description = "Token refresh successful",
			content = @Content(schema = @Schema(implementation = AuthResponseDTO.class),
					examples = @ExampleObject(value = """
							{
							  "access_token": "eyJhbGciOiJIUzI1NiJ9...",
							  "refresh_token": "eyJhbGciOiJIUzI1NiJ9...",
							  "token_type": "Bearer",
							  "expires_in": 900,
							  "role": "CITIZEN",
							  "userId": 1
							}""")))
	public ResponseEntity<AuthResponseDTO> refresh(
			@Valid @RequestBody AuthRefreshRequestDTO request,
			HttpServletRequest servletRequest) {
		return ResponseEntity.ok(authenticationService.refresh(request, clientContext(servletRequest)));
	}

	@PostMapping("/logout")
	@SecurityRequirements
	@Operation(summary = "Revoke the current refresh token")
	@io.swagger.v3.oas.annotations.parameters.RequestBody(description = "Refresh token to revoke",
			content = @Content(schema = @Schema(implementation = AuthLogoutRequestDTO.class),
					examples = @ExampleObject(value = """
							{
							  "refreshToken": "eyJhbGciOiJIUzI1NiJ9..."
							}""")))
	@ApiResponse(responseCode = "200", description = "Logout successful",
			content = @Content(schema = @Schema(implementation = MessageResponseDTO.class),
					examples = @ExampleObject(value = """
							{
							  "message": "Logged out successfully"
							}""")))
	public ResponseEntity<MessageResponseDTO> logout(
			@Valid @RequestBody AuthLogoutRequestDTO request,
			HttpServletRequest servletRequest) {
		return ResponseEntity.ok(authenticationService.logout(request, clientContext(servletRequest)));
	}

	@PostMapping("/forgot-password")
	@SecurityRequirements
	@Operation(summary = "Request a password reset token")
	@io.swagger.v3.oas.annotations.parameters.RequestBody(description = "Email to send the reset link to",
			content = @Content(schema = @Schema(implementation = ForgotPasswordRequestDTO.class),
					examples = @ExampleObject(value = """
							{
							  "email": "ravi@example.com"
							}""")))
	@ApiResponse(responseCode = "200", description = "Password reset request accepted",
			content = @Content(schema = @Schema(implementation = MessageResponseDTO.class),
					examples = @ExampleObject(value = """
							{
							  "message": "If an account exists for this email, password reset instructions have been sent."
							}""")))
	public ResponseEntity<MessageResponseDTO> forgotPassword(
			@Valid @RequestBody ForgotPasswordRequestDTO request,
			HttpServletRequest servletRequest) {
		return ResponseEntity.ok(authenticationService.forgotPassword(request, clientContext(servletRequest)));
	}

	@PostMapping("/reset-password")
	@SecurityRequirements
	@Operation(summary = "Reset password using a verification token")
	@io.swagger.v3.oas.annotations.parameters.RequestBody(description = "Reset token and new password",
			content = @Content(schema = @Schema(implementation = ResetPasswordRequestDTO.class),
					examples = @ExampleObject(value = """
							{
							  "token": "a1b2c3d4-...-e5f6g7h8",
							  "newPassword": "N3wStr0ngP@ss",
							  "confirmPassword": "N3wStr0ngP@ss"
							}""")))
	@ApiResponse(responseCode = "200", description = "Password reset successful",
			content = @Content(schema = @Schema(implementation = MessageResponseDTO.class),
					examples = @ExampleObject(value = """
							{
							  "message": "Password has been reset successfully"
							}""")))
	public ResponseEntity<MessageResponseDTO> resetPassword(
			@Valid @RequestBody ResetPasswordRequestDTO request,
			HttpServletRequest servletRequest) {
		return ResponseEntity.ok(authenticationService.resetPassword(request, clientContext(servletRequest)));
	}

	@PostMapping("/change-password")
	@Operation(
			summary = "Change password for the authenticated user",
			security = @SecurityRequirement(name = "bearerAuth"))
	@io.swagger.v3.oas.annotations.parameters.RequestBody(description = "Current and new password",
			content = @Content(schema = @Schema(implementation = ChangePasswordRequestDTO.class),
					examples = @ExampleObject(value = """
							{
							  "currentPassword": "Str0ngP@ssw0rd",
							  "newPassword": "N3wStr0ngP@ss",
							  "confirmPassword": "N3wStr0ngP@ss"
							}""")))
	@ApiResponse(responseCode = "200", description = "Password changed successfully",
			content = @Content(schema = @Schema(implementation = MessageResponseDTO.class),
					examples = @ExampleObject(value = """
							{
							  "message": "Password changed successfully"
							}""")))
	public ResponseEntity<MessageResponseDTO> changePassword(
			@Valid @RequestBody ChangePasswordRequestDTO request,
			HttpServletRequest servletRequest) {
		User currentUser = SecurityUtils.requireCurrentUser(userRepository);
		return ResponseEntity.ok(authenticationService.changePassword(request, currentUser, clientContext(servletRequest)));
	}

	@PostMapping("/verify-email")
	@SecurityRequirements
	@Operation(summary = "Verify email address using a verification token")
	@io.swagger.v3.oas.annotations.parameters.RequestBody(description = "Email verification token",
			content = @Content(schema = @Schema(implementation = VerifyEmailRequestDTO.class),
					examples = @ExampleObject(value = """
							{
							  "token": "a1b2c3d4-...-e5f6g7h8"
							}""")))
	@ApiResponse(responseCode = "200", description = "Email verified successfully",
			content = @Content(schema = @Schema(implementation = MessageResponseDTO.class),
					examples = @ExampleObject(value = """
							{
							  "message": "Email verified successfully"
							}""")))
	public ResponseEntity<MessageResponseDTO> verifyEmail(
			@Valid @RequestBody VerifyEmailRequestDTO request,
			HttpServletRequest servletRequest) {
		return ResponseEntity.ok(authenticationService.verifyEmail(request, clientContext(servletRequest)));
	}

	private ClientContext clientContext(HttpServletRequest request) {
		String forwardedFor = request.getHeader("X-Forwarded-For");
		String ipAddress = forwardedFor != null && !forwardedFor.isBlank()
				? forwardedFor.split(",")[0].trim()
				: request.getRemoteAddr();
		return new ClientContext(ipAddress, request.getHeader("User-Agent"));
	}
}
