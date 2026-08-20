package com.karuna.entity;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(
		name = "verification_tokens",
		uniqueConstraints = {
				@UniqueConstraint(name = "uk_verification_tokens_token_hash", columnNames = "token_hash")
		}
)
public class VerificationToken extends BaseEntity {

	@NotNull
	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "user_id", nullable = false)
	private User user;

	@NotNull
	@Enumerated(EnumType.STRING)
	@Column(name = "type", nullable = false, length = 60)
	private VerificationTokenType type;

	@NotNull
	@Size(max = 255)
	@Column(name = "token_hash", nullable = false, unique = true, length = 255)
	private String tokenHash;

	@NotNull
	@Column(name = "expires_at", nullable = false)
	private LocalDateTime expiresAt;

	@Column(name = "used_at")
	private LocalDateTime usedAt;

	@Column(name = "revoked_at")
	private LocalDateTime revokedAt;

	@Size(max = 80)
	@Column(name = "created_by_ip", length = 80)
	private String createdByIp;
}

