package com.karuna.service.auth;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import com.karuna.config.KarunaProperties;
import com.karuna.exception.BusinessException;

@Service
public class PasswordService {

	private final PasswordEncoder passwordEncoder;
	private final KarunaProperties.Security.Password policy;

	public PasswordService(PasswordEncoder passwordEncoder, KarunaProperties karunaProperties) {
		this.passwordEncoder = passwordEncoder;
		this.policy = karunaProperties.getSecurity().getPassword();
	}

	public void validatePasswordPolicy(String password) {
		if (!StringUtils.hasText(password)) {
			throw new BusinessException("Password is required");
		}
		if (password.length() < policy.getMinLength()) {
			throw new BusinessException("Password must be at least " + policy.getMinLength() + " characters");
		}
		if (password.length() > policy.getMaxLength()) {
			throw new BusinessException("Password must be at most " + policy.getMaxLength() + " characters");
		}
		if (policy.isRequireUppercase() && password.chars().noneMatch(Character::isUpperCase)) {
			throw new BusinessException("Password must contain an uppercase letter");
		}
		if (policy.isRequireLowercase() && password.chars().noneMatch(Character::isLowerCase)) {
			throw new BusinessException("Password must contain a lowercase letter");
		}
		if (policy.isRequireDigit() && password.chars().noneMatch(Character::isDigit)) {
			throw new BusinessException("Password must contain a digit");
		}
		if (policy.isRequireSpecialCharacter() && password.chars().noneMatch(ch -> !Character.isLetterOrDigit(ch))) {
			throw new BusinessException("Password must contain a special character");
		}
	}

	public String encode(String rawPassword) {
		return passwordEncoder.encode(rawPassword);
	}

	public boolean matches(String rawPassword, String encodedPassword) {
		return passwordEncoder.matches(rawPassword, encodedPassword);
	}
}
