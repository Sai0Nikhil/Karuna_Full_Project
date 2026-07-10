package com.karuna.security.jwt;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.Duration;
import java.util.Map;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import com.karuna.config.KarunaProperties;

class JwtServiceTest {

	private JwtService jwtService;

	@BeforeEach
	void setUp() {
		KarunaProperties properties = new KarunaProperties();
		KarunaProperties.Jwt jwt = properties.getJwt();
		jwt.setSecret("01234567890123456789012345678901");
		jwt.setAccessTokenExpiration(Duration.ofMinutes(15));
		jwt.setRefreshTokenExpiration(Duration.ofDays(7));
		jwt.setIssuer("karuna-api-test");
		jwt.setAudience("karuna-clients-test");
		jwtService = new JwtService(properties);
	}

	@Test
	void generatesAndValidatesAccessToken() {
		String token = jwtService.generateAccessToken("42", Map.of(JwtService.CLAIM_USERNAME, "user@example.com"));

		assertTrue(jwtService.validateToken(token));
		assertTrue(jwtService.isAccessToken(token));
		assertFalse(jwtService.isRefreshToken(token));
		assertEquals("42", jwtService.extractSubject(token));
		assertEquals("user@example.com", jwtService.extractUsername(token).orElseThrow());
		assertFalse(jwtService.isTokenExpired(token));
	}

	@Test
	void generatesAndValidatesRefreshToken() {
		String token = jwtService.generateRefreshToken("42", Map.of());

		assertTrue(jwtService.validateToken(token));
		assertTrue(jwtService.isRefreshToken(token));
		assertFalse(jwtService.isAccessToken(token));
		assertEquals("42", jwtService.extractSubject(token));
	}

	@Test
	void resolvesBearerTokenFromAuthorizationHeader() {
		assertEquals("abc.def.ghi", jwtService.resolveBearerToken("Bearer abc.def.ghi").orElseThrow());
		assertTrue(jwtService.resolveBearerToken("Basic abc").isEmpty());
	}

	@Test
	void rejectsTamperedToken() {
		String token = jwtService.generateAccessToken("42", Map.of());
		String tamperedToken = token.substring(0, 10) + (token.charAt(10) == 'a' ? 'b' : 'a') + token.substring(11);

		assertFalse(jwtService.validateSignature(tamperedToken));
		assertFalse(jwtService.validateToken(tamperedToken));
	}
}
