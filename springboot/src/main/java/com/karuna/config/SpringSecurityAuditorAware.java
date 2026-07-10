package com.karuna.config;

import java.util.Optional;

import org.springframework.data.domain.AuditorAware;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.User;
import org.springframework.stereotype.Component;

import com.karuna.security.auth.KarunaUserDetails;

@Component
public class SpringSecurityAuditorAware implements AuditorAware<String> {

	private static final String SYSTEM = "system";

	@Override
	public Optional<String> getCurrentAuditor() {
		Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
		if (authentication == null || !authentication.isAuthenticated()) {
			return Optional.of(SYSTEM);
		}
		Object principal = authentication.getPrincipal();
		if (principal instanceof KarunaUserDetails karunaUserDetails) {
			return Optional.of(karunaUserDetails.getUsername());
		}
		if (principal instanceof User springUser) {
			return Optional.of(springUser.getUsername());
		}
		if (principal instanceof String str) {
			return Optional.of(str);
		}
		return Optional.of(SYSTEM);
	}
}
