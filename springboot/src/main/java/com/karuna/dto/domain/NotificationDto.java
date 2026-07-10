package com.karuna.dto.domain;

import java.time.LocalDateTime;

import com.karuna.entity.enums.NotificationStatus;
import com.karuna.entity.enums.NotificationType;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public final class NotificationDto {
	private NotificationDto() {
	}

	public record Request(
			@NotNull Long recipientId,
			@NotNull NotificationType type,
			@NotBlank @Size(max = 255) String title,
			@NotBlank @Size(max = 5000) String message,
			@Size(max = 50) String channel) {
	}

	public record Update(NotificationStatus status, LocalDateTime readAt) {
	}

	public record Response(
			Long id,
			Long recipientId,
			NotificationType type,
			NotificationStatus status,
			String title,
			String message,
			String channel,
			LocalDateTime readAt,
			LocalDateTime createdAt,
			LocalDateTime updatedAt,
			Long version) {
	}

	public record Summary(Long id, Long recipientId, NotificationType type, NotificationStatus status, String title) {
	}
}
