package com.karuna.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.karuna.entity.enums.TreatmentStatus;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "treatments")
public class Treatment extends BaseEntity {

	@NotNull
	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "animal_id", nullable = false)
	private Animal animal;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "case_id")
	private RescueCase rescueCase;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "veterinarian_id")
	private Veterinarian veterinarian;

	@NotNull
	@Enumerated(EnumType.STRING)
	@Column(nullable = false, length = 50)
	private TreatmentStatus status = TreatmentStatus.PLANNED;

	@Column(columnDefinition = "TEXT")
	private String diagnosis;

	@Column(name = "procedure_summary", columnDefinition = "TEXT")
	private String procedureSummary;

	@Column(name = "medication_plan", columnDefinition = "TEXT")
	private String medicationPlan;

	@Column(name = "started_at")
	private LocalDateTime startedAt;

	@Column(name = "completed_at")
	private LocalDateTime completedAt;

	@Column(name = "next_follow_up_at")
	private LocalDateTime nextFollowUpAt;

	@PositiveOrZero
	@Column(name = "cost_amount", precision = 12, scale = 2)
	private BigDecimal costAmount;

	@Column(name = "cost_currency", length = 10)
	private String costCurrency = "INR";
}
