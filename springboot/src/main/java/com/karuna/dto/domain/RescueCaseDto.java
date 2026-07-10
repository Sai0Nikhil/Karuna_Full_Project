package com.karuna.dto.domain;

import java.time.LocalDateTime;

import com.karuna.entity.enums.CaseStatus;
import com.karuna.entity.enums.PriorityLevel;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public final class RescueCaseDto {
	private RescueCaseDto() {
	}

	public record Request(
			@NotBlank @Size(max = 255) String title,
			@Size(max = 5000) String description,
			@NotNull CaseStatus status,
			@NotNull PriorityLevel priority,
			@Size(max = 255) String location,
			@Size(max = 100) String animalType,
			Long reporterId,
			Long animalId,
			Long ngoId,
			Long primaryVolunteerId,
			Long locationId) {
	}

	public record Update(
			@Size(max = 255) String title,
			@Size(max = 5000) String description,
			CaseStatus status,
			PriorityLevel priority,
			@Size(max = 255) String location,
			@Size(max = 100) String animalType,
			Boolean active,
			Long ngoId,
			Long primaryVolunteerId,
			Long locationId) {
	}

	public record Response(
			Long id,
			String title,
			String description,
			CaseStatus status,
			PriorityLevel priority,
			String location,
			String animalType,
			Long reporterId,
			Long animalId,
			Long ngoId,
			Long primaryVolunteerId,
			Long locationId,
			Boolean active,
			LocalDateTime createdAt,
			LocalDateTime updatedAt,
			Long version) {
	}

	public record Summary(Long id, String title, CaseStatus status, PriorityLevel priority, Long ngoId, LocalDateTime createdAt) {
	}
}
