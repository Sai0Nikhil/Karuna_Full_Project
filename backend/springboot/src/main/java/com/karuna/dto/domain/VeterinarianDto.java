package com.karuna.dto.domain;

import java.time.LocalDateTime;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public final class VeterinarianDto {
	private VeterinarianDto() {
	}

	public record Request(
			@NotNull Long userId,
			@NotBlank @Size(max = 120) String licenseNumber,
			@Size(max = 255) String clinicName,
			@Size(max = 120) String specialization,
			@Email @Size(max = 255) String email,
			@Pattern(regexp = "^$|^[+]?[0-9]{7,20}$") String phoneNumber,
			Long clinicLocationId) {
	}

	public record Update(
			@Size(max = 255) String clinicName,
			@Size(max = 120) String specialization,
			@Email @Size(max = 255) String email,
			@Pattern(regexp = "^$|^[+]?[0-9]{7,20}$") String phoneNumber,
			Boolean active,
			Long clinicLocationId) {
	}

	public record Response(
			Long id,
			Long userId,
			String licenseNumber,
			String clinicName,
			String specialization,
			String email,
			String phoneNumber,
			Long clinicLocationId,
			Boolean active,
			LocalDateTime createdAt,
			LocalDateTime updatedAt,
			Long version) {
	}

	public record Summary(Long id, Long userId, String licenseNumber, String clinicName, String specialization) {
	}
}
