package com.karuna.dto.domain;

import java.time.LocalDateTime;

import com.karuna.entity.enums.UserRole;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public final class UserDto {
	private UserDto() {
	}

	public record Request(
			@NotBlank @Size(max = 255) String name,
			@NotBlank @Email @Size(max = 255) String email,
			@Pattern(regexp = "^$|^[+]?[0-9]{7,20}$") String phoneNumber,
			@NotNull UserRole role,
			Long locationId) {
	}

	public record Update(
			@Size(max = 255) String name,
			@Email @Size(max = 255) String email,
			@Pattern(regexp = "^$|^[+]?[0-9]{7,20}$") String phoneNumber,
			UserRole role,
			Boolean active,
			Long locationId) {
	}

	public record Response(
			Long id,
			String name,
			String email,
			String phoneNumber,
			UserRole role,
			Boolean active,
			Long locationId,
			LocalDateTime createdAt,
			LocalDateTime updatedAt,
			Long version) {
	}

	public record Summary(Long id, String name, String email, String phoneNumber, UserRole role) {
	}
}
