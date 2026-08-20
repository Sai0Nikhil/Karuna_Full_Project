package com.karuna.dto.domain;

import java.time.LocalDateTime;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public final class RefreshTokenDto {
	private RefreshTokenDto() {
	}

	public record Request(
			@NotNull Long userId,
			@NotBlank @Size(max = 255) String tokenHash,
			@NotNull LocalDateTime expiresAt,
			@Size(max = 80) String createdByIp) {
	}

	public record Update(LocalDateTime revokedAt) {
	}

	public record Response(
			Long id,
			Long userId,
			String tokenHash,
			LocalDateTime expiresAt,
			LocalDateTime revokedAt,
			String createdByIp,
			LocalDateTime createdAt,
			LocalDateTime updatedAt,
			Long version) {
	}

	public record Summary(Long id, Long userId, LocalDateTime expiresAt, LocalDateTime revokedAt) {
	}
}
