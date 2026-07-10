package com.karuna.security.auth;

import java.util.Optional;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import com.karuna.entity.User;
import com.karuna.exception.BusinessException;
import com.karuna.repository.UserRepository;

public final class SecurityUtils {

	private SecurityUtils() {
	}

	public static Optional<KarunaUserDetails> getCurrentUserDetails() {
		Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
		if (authentication == null || !authentication.isAuthenticated()) {
			return Optional.empty();
		}
		Object principal = authentication.getPrincipal();
		if (principal instanceof KarunaUserDetails userDetails) {
			return Optional.of(userDetails);
		}
		return Optional.empty();
	}

	public static User requireCurrentUser(UserRepository userRepository) {
		KarunaUserDetails userDetails = getCurrentUserDetails()
				.orElseThrow(() -> new BusinessException(
						org.springframework.http.HttpStatus.UNAUTHORIZED,
						"AUTHENTICATION_REQUIRED",
						"Authentication is required"));
		return userRepository.findById(userDetails.getUserId())
				.orElseThrow(() -> new BusinessException(
						org.springframework.http.HttpStatus.UNAUTHORIZED,
						"AUTHENTICATION_REQUIRED",
						"Authenticated user could not be loaded"));
	}
}
