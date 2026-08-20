package com.karuna.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "audit_logs")
public class AuditLog extends BaseEntity {

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "actor_user_id")
	private User actor;

	@NotBlank
	@Size(max = 120)
	@Column(nullable = false, length = 120)
	private String action;

	@NotBlank
	@Size(max = 120)
	@Column(name = "entity_type", nullable = false, length = 120)
	private String entityType;

	@Size(max = 120)
	@Column(name = "entity_id", length = 120)
	private String entityId;

	@Size(max = 80)
	@Column(name = "ip_address", length = 80)
	private String ipAddress;

	@Size(max = 500)
	@Column(name = "user_agent", length = 500)
	private String userAgent;

	@Column(columnDefinition = "TEXT")
	private String metadata;
}
