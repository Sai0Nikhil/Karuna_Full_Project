package com.karuna.security.jwt;

import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.Collections;
import java.util.Date;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

import javax.crypto.SecretKey;

import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import com.karuna.config.KarunaProperties;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;

@Service
public class JwtService {

	public static final String CLAIM_USERNAME = "username";
	public static final String CLAIM_ROLE = "role";
	public static final String CLAIM_TOKEN_TYPE = "token_type";
	public static final String TOKEN_TYPE_ACCESS = "access";
	public static final String TOKEN_TYPE_REFRESH = "refresh";
	public static final String BEARER_PREFIX = "Bearer ";

	private static final int MIN_SECRET_BYTES = 32;

	private final KarunaProperties.Jwt jwtProperties;
	private final SecretKey signingKey;

	public JwtService(KarunaProperties karunaProperties) {
		this.jwtProperties = karunaProperties.getJwt();
		this.signingKey = buildSigningKey(jwtProperties.getSecret());
	}

	public String generateAccessToken(String subject, Map<String, Object> claims) {
		return buildToken(subject, claims, jwtProperties.getAccessTokenExpiration(), TOKEN_TYPE_ACCESS);
	}

	public String generateRefreshToken(String subject, Map<String, Object> claims) {
		return buildToken(subject, claims, jwtProperties.getRefreshTokenExpiration(), TOKEN_TYPE_REFRESH);
	}

	public Claims extractClaims(String token) {
		return parseClaims(token);
	}

	public String extractSubject(String token) {
		return parseClaims(token).getSubject();
	}

	public Optional<String> extractUsername(String token) {
		Claims claims = parseClaims(token);
		Object username = claims.get(CLAIM_USERNAME);
		if (username instanceof String value && StringUtils.hasText(value)) {
			return Optional.of(value);
		}
		return Optional.empty();
	}

	public Instant extractExpiration(String token) {
		Date expiration = parseClaims(token).getExpiration();
		return expiration == null ? null : expiration.toInstant();
	}

	/**
	 * Signature-only validation. Must return false for any tampered token.
	 */
	public boolean validateSignature(String token) {
		try {
			Jwts.parser().verifyWith(signingKey).build().parseSignedClaims(token);
			return true;
		} catch (JwtException ex) {
			return false;
		}
	}

	public boolean isTokenExpired(String token) {
		try {
			Instant expiration = extractExpiration(token);
			return expiration == null || expiration.isBefore(Instant.now());
		} catch (ExpiredJwtException ex) {
			return true;
		} catch (JwtException ex) {
			return true;
		}
	}

	public boolean validateToken(String token) {
		try {
			Claims claims = parseClaims(token);
			return hasValidExpiration(claims) && hasValidAudience(claims);
		} catch (JwtException ex) {
			return false;
		}
	}

	public boolean isAccessToken(String token) {
		return hasTokenType(token, TOKEN_TYPE_ACCESS);
	}

	public boolean isRefreshToken(String token) {
		return hasTokenType(token, TOKEN_TYPE_REFRESH);
	}

	public Optional<String> resolveBearerToken(String authorizationHeader) {
		if (!StringUtils.hasText(authorizationHeader) || !authorizationHeader.startsWith(BEARER_PREFIX)) {
			return Optional.empty();
		}
		String token = authorizationHeader.substring(BEARER_PREFIX.length()).trim();
		return StringUtils.hasText(token) ? Optional.of(token) : Optional.empty();
	}

	public Duration getAccessTokenExpiration() {
		return jwtProperties.getAccessTokenExpiration();
	}

	public Duration getRefreshTokenExpiration() {
		return jwtProperties.getRefreshTokenExpiration();
	}

	private String buildToken(
			String subject,
			Map<String, Object> claims,
			Duration expiration,
			String tokenType) {
		Instant issuedAt = Instant.now();
		Instant expiresAt = issuedAt.plus(expiration);

		var builder = Jwts.builder()
				.subject(subject)
				.issuedAt(Date.from(issuedAt))
				.expiration(Date.from(expiresAt))
				.claim(CLAIM_TOKEN_TYPE, tokenType);

		if (StringUtils.hasText(jwtProperties.getIssuer())) {
			builder.issuer(jwtProperties.getIssuer());
		}
		if (StringUtils.hasText(jwtProperties.getAudience())) {
			builder.audience().add(jwtProperties.getAudience()).and();
		}

		Map<String, Object> safeClaims = claims == null ? Collections.emptyMap() : claims;
		safeClaims.forEach((key, value) -> {
			if (!CLAIM_TOKEN_TYPE.equals(key)) {
				builder.claim(key, value);
			}
		});
		builder.claim(CLAIM_TOKEN_TYPE, tokenType);

		return builder.signWith(signingKey).compact();
	}

	private Claims parseClaims(String token) {
		var parserBuilder = Jwts.parser().verifyWith(signingKey);
		if (StringUtils.hasText(jwtProperties.getIssuer())) {
			parserBuilder.requireIssuer(jwtProperties.getIssuer());
		}
		return parserBuilder.build().parseSignedClaims(token).getPayload();
	}

	private boolean hasValidExpiration(Claims claims) {
		Date expiration = claims.getExpiration();
		return expiration != null && expiration.toInstant().isAfter(Instant.now());
	}

	private boolean hasValidAudience(Claims claims) {
		if (!StringUtils.hasText(jwtProperties.getAudience())) {
			return true;
		}
		Set<String> audiences = claims.getAudience();
		return audiences != null && audiences.contains(jwtProperties.getAudience());
	}

	private boolean hasTokenType(String token, String expectedType) {
		try {
			Claims claims = parseClaims(token);
			return expectedType.equals(claims.get(CLAIM_TOKEN_TYPE, String.class));
		} catch (JwtException ex) {
			return false;
		}
	}

	private static SecretKey buildSigningKey(String secret) {
		if (!StringUtils.hasText(secret)) {
			throw new IllegalStateException("karuna.jwt.secret must be configured");
		}
		byte[] secretBytes = secret.getBytes(StandardCharsets.UTF_8);
		if (secretBytes.length < MIN_SECRET_BYTES) {
			throw new IllegalStateException("karuna.jwt.secret must be at least 256 bits (32 bytes)");
		}
		return Keys.hmacShaKeyFor(secretBytes);
	}
}

