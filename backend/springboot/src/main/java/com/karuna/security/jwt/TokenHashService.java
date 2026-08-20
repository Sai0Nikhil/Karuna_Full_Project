package com.karuna.security.jwt;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;

import org.springframework.stereotype.Service;

import com.karuna.config.KarunaProperties;

@Service
public class TokenHashService {

	private final String pepper;

	public TokenHashService(KarunaProperties karunaProperties) {
		this.pepper = karunaProperties.getJwt().getSecret();
	}

	public String hash(String rawToken) {
		try {
			MessageDigest digest = MessageDigest.getInstance("SHA-256");
			digest.update(pepper.getBytes(StandardCharsets.UTF_8));
			digest.update(rawToken.getBytes(StandardCharsets.UTF_8));
			return HexFormat.of().formatHex(digest.digest());
		} catch (NoSuchAlgorithmException ex) {
			throw new IllegalStateException("SHA-256 is not available", ex);
		}
	}
}
