package com.karuna.service.auth;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.karuna.config.KarunaProperties;
import com.karuna.entity.User;
import com.karuna.entity.VerificationToken;
import com.karuna.entity.VerificationTokenType;
import com.karuna.exception.InvalidTokenException;
import com.karuna.repository.VerificationTokenRepository;
import com.karuna.security.jwt.TokenHashService;

@Service
public class VerificationTokenService {

	private final VerificationTokenRepository verificationTokenRepository;
	private final TokenHashService tokenHashService;
	private final KarunaProperties.Security.Verification verificationSettings;

	public VerificationTokenService(
			VerificationTokenRepository verificationTokenRepository,
			TokenHashService tokenHashService,
			KarunaProperties karunaProperties) {
		this.verificationTokenRepository = verificationTokenRepository;
		this.tokenHashService = tokenHashService;
		this.verificationSettings = karunaProperties.getSecurity().getVerification();
	}

	@Transactional
	public void issueEmailVerificationToken(User user, ClientContext clientContext) {
		revokeActiveTokens(user.getId(), VerificationTokenType.EMAIL_VERIFICATION);
		persistToken(user, VerificationTokenType.EMAIL_VERIFICATION,
				verificationSettings.getEmailVerificationExpiration(), clientContext);
	}

	@Transactional
	public void issuePasswordResetToken(User user, ClientContext clientContext) {
		revokeActiveTokens(user.getId(), VerificationTokenType.PASSWORD_RESET);
		persistToken(user, VerificationTokenType.PASSWORD_RESET,
				verificationSettings.getPasswordResetExpiration(), clientContext);
	}

	@Transactional
	public User consumeEmailVerificationToken(String rawToken) {
		VerificationToken token = validateActiveToken(rawToken, VerificationTokenType.EMAIL_VERIFICATION);
		token.setUsedAt(LocalDateTime.now());
		verificationTokenRepository.save(token);
		return token.getUser();
	}

	@Transactional
	public User consumePasswordResetToken(String rawToken) {
		VerificationToken token = validateActiveToken(rawToken, VerificationTokenType.PASSWORD_RESET);
		token.setUsedAt(LocalDateTime.now());
		verificationTokenRepository.save(token);
		return token.getUser();
	}

	private void persistToken(
			User user,
			VerificationTokenType type,
			java.time.Duration expiration,
			ClientContext clientContext) {
		String rawToken = generateRawToken();
		VerificationToken token = new VerificationToken();
		token.setUser(user);
		token.setType(type);
		token.setTokenHash(tokenHashService.hash(rawToken));
		token.setExpiresAt(LocalDateTime.now().plus(expiration));
		token.setCreatedByIp(clientContext.ipAddress());
		verificationTokenRepository.save(token);
	}

	private VerificationToken validateActiveToken(String rawToken, VerificationTokenType expectedType) {
		if (rawToken == null || rawToken.isBlank()) {
			throw new InvalidTokenException("Verification token is required");
		}

		VerificationToken token = verificationTokenRepository.findByTokenHash(tokenHashService.hash(rawToken))
				.orElseThrow(() -> new InvalidTokenException("Invalid verification token"));

		if (token.getType() != expectedType) {
			throw new InvalidTokenException("Invalid verification token type");
		}
		if (token.getUsedAt() != null) {
			throw new InvalidTokenException("Verification token has already been used");
		}
		if (token.getRevokedAt() != null) {
			throw new InvalidTokenException("Verification token has been revoked");
		}
		if (token.getExpiresAt().isBefore(LocalDateTime.now())) {
			throw new InvalidTokenException("Verification token has expired");
		}

		return token;
	}

	private void revokeActiveTokens(Long userId, VerificationTokenType type) {
		List<VerificationToken> activeTokens = verificationTokenRepository
				.findByUserIdAndTypeAndUsedAtIsNullAndRevokedAtIsNull(userId, type);
		LocalDateTime now = LocalDateTime.now();
		for (VerificationToken token : activeTokens) {
			token.setRevokedAt(now);
		}
		verificationTokenRepository.saveAll(activeTokens);
	}

	private String generateRawToken() {
		return UUID.randomUUID() + "." + UUID.randomUUID();
	}
}
