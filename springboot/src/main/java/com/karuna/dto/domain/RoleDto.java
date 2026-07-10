package com.karuna.dto.domain;

import com.karuna.entity.enums.UserRole;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public final class RoleDto {
	private RoleDto() {
	}

	public record Request(@NotNull UserRole name, @Size(max = 255) String description) {
	}

	public record Update(@Size(max = 255) String description) {
	}

	public record Response(Long id, UserRole name, String description, Long version) {
	}

	public record Summary(Long id, UserRole name) {
	}
}
