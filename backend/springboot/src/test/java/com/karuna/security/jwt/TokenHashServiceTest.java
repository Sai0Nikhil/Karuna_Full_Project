package com.karuna.security.jwt;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import com.karuna.config.KarunaProperties;

class TokenHashServiceTest {

	private TokenHashService tokenHashService;

	@BeforeEach
	void setUp() {
		KarunaProperties properties = new KarunaProperties();
		properties.getJwt().setSecret("01234567890123456789012345678901");
		tokenHashService = new TokenHashService(properties);
	}

	@Test
	void producesStableHashForSameToken() {
		String first = tokenHashService.hash("refresh-token-value");
		String second = tokenHashService.hash("refresh-token-value");
		assertEquals(first, second);
	}

	@Test
	void producesDifferentHashesForDifferentTokens() {
		String first = tokenHashService.hash("refresh-token-a");
		String second = tokenHashService.hash("refresh-token-b");
		assertNotEquals(first, second);
	}
}
