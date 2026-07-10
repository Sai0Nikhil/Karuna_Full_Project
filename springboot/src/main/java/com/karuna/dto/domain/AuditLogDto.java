package com.karuna.dto.domain;

import java.time.LocalDateTime;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public final class AuditLogDto {
	private AuditLogDto() {
	}

	public record Request(
			Long actorUserId,
			@NotBlank @Size(max = 120) String action,
			@NotBlank @Size(max = 120) String entityType,
			@Size(max = 120) String entityId,
			@Size(max = 80) String ipAddress,
			@Size(max = 500) String userAgent,
			String metadata) {
	}

	public record Response(
			Long id,
			Long actorUserId,
			String action,
			String entityType,
			String entityId,
			String ipAddress,
			String userAgent,
			String metadata,
			LocalDateTime createdAt,
			Long version) {
	}

	public record Summary(Long id, Long actorUserId, String action, String entityType, String entityId, LocalDateTime createdAt) {
	}
}
