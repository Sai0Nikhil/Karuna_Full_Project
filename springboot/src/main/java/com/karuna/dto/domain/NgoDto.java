package com.karuna.dto.domain;

import java.time.LocalDateTime;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public final class NgoDto {
	private NgoDto() {
	}

	public record Request(
			@NotBlank @Size(max = 255) String name,
			@NotBlank @Size(max = 100) String registrationNumber,
			@Email @Size(max = 255) String email,
			@Pattern(regexp = "^$|^[+]?[0-9]{7,20}$") String phoneNumber,
			@Size(max = 5000) String description,
			Long headquartersLocationId) {
	}

	public record Update(
			@Size(max = 255) String name,
			@Email @Size(max = 255) String email,
			@Pattern(regexp = "^$|^[+]?[0-9]{7,20}$") String phoneNumber,
			@Size(max = 5000) String description,
			Boolean verified,
			Boolean active,
			Long headquartersLocationId) {
	}

	public record Response(
			Long id,
			String name,
			String registrationNumber,
			String email,
			String phoneNumber,
			String description,
			Long headquartersLocationId,
			Boolean verified,
			Boolean active,
			LocalDateTime createdAt,
			LocalDateTime updatedAt,
			Long version) {
	}

	public record Summary(Long id, String name, String email, String phoneNumber, Boolean verified) {
	}
}
