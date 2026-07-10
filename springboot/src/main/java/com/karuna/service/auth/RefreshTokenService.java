package com.karuna.service.auth;

import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.karuna.entity.RefreshToken;
import com.karuna.entity.User;
import com.karuna.exception.InvalidTokenException;
import com.karuna.repository.RefreshTokenRepository;
import com.karuna.security.jwt.JwtService;
import com.karuna.security.jwt.TokenHashService;

@Service
public class RefreshTokenService {

	private final RefreshTokenRepository refreshTokenRepository;
	private final JwtService jwtService;
	private final TokenHashService tokenHashService;

	public RefreshTokenService(
			RefreshTokenRepository refreshTokenRepository,
			JwtService jwtService,
			TokenHashService tokenHashService) {
		this.refreshTokenRepository = refreshTokenRepository;
		this.jwtService = jwtService;
		this.tokenHashService = tokenHashService;
	}

	@Transactional
	public String createRefreshToken(User user, ClientContext clientContext) {
		String refreshToken = jwtService.generateRefreshToken(
				String.valueOf(user.getId()),
				Map.of(JwtService.CLAIM_USERNAME, user.getEmail(), JwtService.CLAIM_ROLE, user.getRole()));

		RefreshToken entity = new RefreshToken();
		entity.setUser(user);
		entity.setTokenHash(tokenHashService.hash(refreshToken));
		entity.setExpiresAt(LocalDateTime.ofInstant(jwtService.extractExpiration(refreshToken), ZoneOffset.UTC));
		entity.setCreatedByIp(clientContext.ipAddress());
		refreshTokenRepository.save(entity);

		return refreshToken;
	}

	@Transactional(readOnly = true)
	public RefreshToken validateAndGet(String rawRefreshToken) {
		if (!jwtService.isRefreshToken(rawRefreshToken) || !jwtService.validateToken(rawRefreshToken)) {
			throw new InvalidTokenException("Invalid or expired refresh token");
		}

		RefreshToken storedToken = refreshTokenRepository.findByTokenHash(tokenHashService.hash(rawRefreshToken))
				.orElseThrow(() -> new InvalidTokenException("Refresh token not found"));

		if (storedToken.getRevokedAt() != null) {
			throw new InvalidTokenException("Refresh token has been revoked");
		}
		if (storedToken.getExpiresAt().isBefore(LocalDateTime.now())) {
			throw new InvalidTokenException("Refresh token has expired");
		}

		return storedToken;
	}

	@Transactional
	public void revoke(RefreshToken refreshToken) {
		if (refreshToken.getRevokedAt() == null) {
			refreshToken.setRevokedAt(LocalDateTime.now());
			refreshTokenRepository.save(refreshToken);
		}
	}

	@Transactional
	public void revokeByRawToken(String rawRefreshToken) {
		if (rawRefreshToken == null || rawRefreshToken.isBlank()) {
			return;
		}
		refreshTokenRepository.findByTokenHash(tokenHashService.hash(rawRefreshToken)).ifPresent(this::revoke);
	}

	@Transactional
	public void revokeAllForUser(Long userId) {
		List<RefreshToken> activeTokens = refreshTokenRepository.findByUserIdAndRevokedAtIsNull(userId);
		LocalDateTime now = LocalDateTime.now();
		for (RefreshToken token : activeTokens) {
			token.setRevokedAt(now);
		}
		refreshTokenRepository.saveAll(activeTokens);
	}
}
