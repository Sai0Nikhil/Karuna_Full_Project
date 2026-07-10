package com.karuna.dto.domain;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public final class LocationDto {
	private LocationDto() {
	}

	public record Request(
			@NotBlank @Size(max = 255) String label,
			@Size(max = 255) String addressLine1,
			@Size(max = 255) String addressLine2,
			@Size(max = 120) String city,
			@Size(max = 120) String state,
			@Size(max = 30) String postalCode,
			@Size(max = 120) String country,
			@DecimalMin("-90.0") @DecimalMax("90.0") BigDecimal latitude,
			@DecimalMin("-180.0") @DecimalMax("180.0") BigDecimal longitude) {
	}

	public record Update(
			@Size(max = 255) String label,
			@Size(max = 255) String addressLine1,
			@Size(max = 255) String addressLine2,
			@Size(max = 120) String city,
			@Size(max = 120) String state,
			@Size(max = 30) String postalCode,
			@Size(max = 120) String country,
			@DecimalMin("-90.0") @DecimalMax("90.0") BigDecimal latitude,
			@DecimalMin("-180.0") @DecimalMax("180.0") BigDecimal longitude) {
	}

	public record Response(
			Long id,
			String label,
			String addressLine1,
			String addressLine2,
			String city,
			String state,
			String postalCode,
			String country,
			BigDecimal latitude,
			BigDecimal longitude,
			LocalDateTime createdAt,
			LocalDateTime updatedAt,
			Long version) {
	}

	public record Summary(Long id, String label, String city, String state, BigDecimal latitude, BigDecimal longitude) {
	}
}
