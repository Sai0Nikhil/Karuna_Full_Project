package com.karuna.service.auth;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import com.karuna.config.KarunaProperties;
import com.karuna.exception.BusinessException;

class PasswordServiceTest {

	private PasswordService passwordService;

	@BeforeEach
	void setUp() {
		KarunaProperties properties = new KarunaProperties();
		properties.getSecurity().getPassword().setMinLength(8);
		properties.getSecurity().getPassword().setMaxLength(128);
		passwordService = new PasswordService(new BCryptPasswordEncoder(), properties);
	}

	@Test
	void encodesAndMatchesPassword() {
		String encoded = passwordService.encode("password123");
		assertTrue(passwordService.matches("password123", encoded));
		assertFalse(passwordService.matches("wrong-password", encoded));
	}

	@Test
	void rejectsPasswordBelowMinimumLength() {
		assertThrows(BusinessException.class, () -> passwordService.validatePasswordPolicy("short"));
	}
}
