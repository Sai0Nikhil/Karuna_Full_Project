package com.karuna.dto.domain;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.karuna.entity.enums.TreatmentStatus;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

public final class TreatmentDto {
	private TreatmentDto() {
	}

	public record Request(
			@NotNull Long animalId,
			Long caseId,
			Long veterinarianId,
			TreatmentStatus status,
			@Size(max = 5000) String diagnosis,
			@Size(max = 5000) String procedureSummary,
			@Size(max = 5000) String medicationPlan,
			LocalDateTime startedAt,
			LocalDateTime completedAt,
			LocalDateTime nextFollowUpAt,
			@PositiveOrZero BigDecimal costAmount,
			@Size(min = 3, max = 10) String costCurrency) {
	}

	public record Update(
			TreatmentStatus status,
			@Size(max = 5000) String diagnosis,
			@Size(max = 5000) String procedureSummary,
			@Size(max = 5000) String medicationPlan,
			LocalDateTime completedAt,
			LocalDateTime nextFollowUpAt,
			@PositiveOrZero BigDecimal costAmount) {
	}

	public record Response(
			Long id,
			Long animalId,
			Long caseId,
			Long veterinarianId,
			TreatmentStatus status,
			String diagnosis,
			String procedureSummary,
			String medicationPlan,
			LocalDateTime startedAt,
			LocalDateTime completedAt,
			LocalDateTime nextFollowUpAt,
			BigDecimal costAmount,
			String costCurrency,
			LocalDateTime createdAt,
			LocalDateTime updatedAt,
			Long version) {
	}

	public record Summary(Long id, Long animalId, Long caseId, TreatmentStatus status, LocalDateTime startedAt) {
	}
}
