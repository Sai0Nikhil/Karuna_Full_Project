package com.karuna.dto.domain;

import java.time.LocalDateTime;

import com.karuna.entity.enums.AdoptionStatus;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public final class AdoptionApplicationDto {
	private AdoptionApplicationDto() {
	}

	public record Request(
			Long caseId,
			Long animalId,
			Long applicantId,
			@Size(max = 255) String applicantName,
			@Email @Size(max = 255) String contactEmail,
			@Pattern(regexp = "^$|^[+]?[0-9]{7,20}$") String contactPhone,
			@Size(max = 5000) String reason,
			@Size(max = 500) String adopterIdUrl) {
	}

	public record Update(AdoptionStatus status, @Size(max = 5000) String notes, Long decidedById) {
	}

	public record Response(
			Long id,
			Long caseId,
			Long animalId,
			Long applicantId,
			String applicantName,
			String contactEmail,
			String contactPhone,
			String reason,
			String adopterIdUrl,
			AdoptionStatus status,
			String notes,
			Long decidedById,
			LocalDateTime decidedAt,
			LocalDateTime createdAt,
			LocalDateTime updatedAt,
			Long version) {
	}

	public record Summary(Long id, Long caseId, Long animalId, AdoptionStatus status, LocalDateTime createdAt) {
	}
}
