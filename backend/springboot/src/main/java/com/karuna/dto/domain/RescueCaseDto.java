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

	/** Request to create a new rescue case */
	public record Request(
			@NotBlank @Size(max = 255) String title,
			@Size(max = 5000) String description,
			CaseStatus status,
			PriorityLevel priority,
			@Size(max = 255) String location,
			@Size(max = 100) String animalType,
			// Flutter-aligned fields
			@Size(max = 500) String imageUrl,
			@Size(max = 255) String locationLabel,
			Double latitude,
			Double longitude,
			@Size(max = 100) String species,
			@Size(max = 100) String injuryType,
			String probableCondition,
			String firstAidSteps,
			Integer estimatedCostInr,
			String notes,
			// IDs
			Long reporterId,
			Long animalId,
			Long ngoId,
			Long primaryVolunteerId,
			Long locationId) {
	}

	/** Partial update request */
	public record Update(
			@Size(max = 255) String title,
			@Size(max = 5000) String description,
			CaseStatus status,
			PriorityLevel priority,
			@Size(max = 255) String location,
			@Size(max = 100) String animalType,
			String imageUrl,
			String locationLabel,
			Double latitude,
			Double longitude,
			String species,
			String injuryType,
			String probableCondition,
			String firstAidSteps,
			Integer estimatedCostInr,
			String notes,
			Boolean active,
			Long ngoId,
			Long primaryVolunteerId,
			Long locationId) {
	}

	/** Full response — Flutter-aligned field names */
	public record Response(
			Long id,
			String title,
			String description,
			CaseStatus caseStatus,
			// Flutter expects lowercase string "reported", "assigned" etc.
			String status,
			PriorityLevel priorityLevel,
			// Flutter expects "critical"/"urgent"/"routine"
			String severity,
			String location,
			String animalType,
			// Flutter-aligned fields
			String imageUrl,
			String imageDataUrl, // alias for imageUrl
			String locationLabel,
			Double latitude,
			Double longitude,
			String species,
			String injuryType,
			String probableCondition,
			String firstAidSteps,
			Integer estimatedCostInr,
			Integer donatedAmountInr,
			String notes,
			// Reporter info
			Long reporterId,
			String reporterName,
			String reporterContact,
			// Assigned responder
			Long primaryVolunteerId,
			String assignedResponder,
			// NGO
			Long ngoId,
			String ngo,
			// Other IDs
			Long animalId,
			Long locationId,
			Boolean active,
			LocalDateTime createdAt,
			LocalDateTime updatedAt,
			Long version) {
	}

	public record Summary(Long id, String title, CaseStatus status, PriorityLevel priority, Long ngoId, LocalDateTime createdAt) {
	}
}
