package com.karuna.entity;

import java.time.LocalDateTime;

import com.karuna.entity.enums.NotificationStatus;
import com.karuna.entity.enums.NotificationType;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "notifications")
public class Notification extends BaseEntity {

	@NotNull
	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "recipient_id", nullable = false)
	private User recipient;

	@NotNull
	@Enumerated(EnumType.STRING)
	@Column(nullable = false, length = 80)
	private NotificationType type;

	@NotNull
	@Enumerated(EnumType.STRING)
	@Column(nullable = false, length = 50)
	private NotificationStatus status = NotificationStatus.PENDING;

	@NotBlank
	@Size(max = 255)
	@Column(nullable = false)
	private String title;

	@NotBlank
	@Column(nullable = false, columnDefinition = "TEXT")
	private String message;

	@Size(max = 50)
	private String channel;

	@Column(name = "read_at")
	private LocalDateTime readAt;
}
