package com.karuna.dto.domain;

import java.time.LocalDateTime;

import com.karuna.entity.enums.VolunteerStatus;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public final class VolunteerDto {
	private VolunteerDto() {
	}

	public record Request(
			@NotNull Long userId,
			@Pattern(regexp = "^$|^[+]?[0-9]{7,20}$") String phoneNumber,
			VolunteerStatus status,
			@Size(max = 255) String skills,
			Long serviceLocationId) {
	}

	public record Update(
			@Pattern(regexp = "^$|^[+]?[0-9]{7,20}$") String phoneNumber,
			VolunteerStatus status,
			@Size(max = 255) String skills,
			Boolean active,
			Long serviceLocationId) {
	}

	public record Response(
			Long id,
			Long userId,
			String phoneNumber,
			VolunteerStatus status,
			String skills,
			Long serviceLocationId,
			Boolean active,
			LocalDateTime createdAt,
			LocalDateTime updatedAt,
			Long version) {
		
		public boolean getAvailable() {
			return status == VolunteerStatus.AVAILABLE;
		}
	}

	public record Summary(Long id, Long userId, VolunteerStatus status, String skills) {
	}
}
