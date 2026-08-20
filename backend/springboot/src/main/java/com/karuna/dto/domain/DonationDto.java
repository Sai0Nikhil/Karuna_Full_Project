package com.karuna.dto.domain;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.karuna.entity.enums.DonationStatus;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public final class DonationDto {
	private DonationDto() {
	}

	public record Request(
			Long donorId,
			Long caseId,
			@NotNull @Positive BigDecimal amount,
			@NotNull @Size(min = 3, max = 10) String currency,
			DonationStatus status,
			@Size(max = 120) String paymentReference,
			@Size(max = 80) String paymentProvider,
			@Size(max = 500) String message) {
	}

	public record Update(DonationStatus status, @Size(max = 500) String message) {
	}

	public record Response(
			Long id,
			Long donorId,
			Long caseId,
			BigDecimal amount,
			String currency,
			DonationStatus status,
			String paymentReference,
			String paymentProvider,
			String message,
			LocalDateTime createdAt,
			LocalDateTime updatedAt,
			Long version) {
	}

	public record Summary(Long id, Long caseId, BigDecimal amount, String currency, DonationStatus status, LocalDateTime createdAt) {
	}
}
