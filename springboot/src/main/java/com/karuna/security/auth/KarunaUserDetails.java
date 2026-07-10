package com.karuna.security.auth;

import java.time.LocalDateTime;
import java.util.Collection;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.User;

public class KarunaUserDetails extends User {

	private final Long userId;
	private final String displayName;
	private final String role;

	public KarunaUserDetails(com.karuna.entity.User user, Collection<? extends GrantedAuthority> authorities) {
		super(
				user.getEmail(),
				user.getPasswordHash(),
				user.isActive() && user.getDeletedAt() == null,
				true,
				true,
				isAccountNonLocked(user),
				authorities);
		this.userId = user.getId();
		this.displayName = user.getName();
		this.role = user.getRole();
	}

	public Long getUserId() {
		return userId;
	}

	public String getDisplayName() {
		return displayName;
	}

	public String getRole() {
		return role;
	}

	private static boolean isAccountNonLocked(com.karuna.entity.User user) {
		if (user.isAccountLocked()) {
			return false;
		}
		return user.getLockedUntil() == null || !user.getLockedUntil().isAfter(LocalDateTime.now());
	}
}
