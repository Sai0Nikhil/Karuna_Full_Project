package com.karuna.entity;

import java.math.BigDecimal;

import com.karuna.entity.enums.DonationStatus;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "donations", uniqueConstraints = @UniqueConstraint(name = "uk_donations_payment_reference", columnNames = "payment_reference"))
public class Donation extends BaseEntity {

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "donor_id")
	private User donor;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "case_id")
	private RescueCase rescueCase;

	@NotNull
	@Positive
	@Column(nullable = false, precision = 12, scale = 2)
	private BigDecimal amount;

	@NotNull
	@Size(min = 3, max = 10)
	@Column(nullable = false, length = 10)
	private String currency = "INR";

	@NotNull
	@Enumerated(EnumType.STRING)
	@Column(nullable = false, length = 50)
	private DonationStatus status = DonationStatus.PENDING;

	@Size(max = 120)
	@Column(name = "payment_reference", unique = true)
	private String paymentReference;

	@Size(max = 80)
	@Column(name = "payment_provider")
	private String paymentProvider;

	@Size(max = 500)
	private String message;

	public String getStatus() {
		return status == null ? null : status.name().toLowerCase();
	}

	public void setStatus(String status) {
		this.status = parseStatus(status);
	}

	public DonationStatus getDonationStatus() {
		return status;
	}

	public void setDonationStatus(DonationStatus donationStatus) {
		this.status = donationStatus;
	}

	private DonationStatus parseStatus(String value) {
		if (value == null || value.isBlank()) {
			return DonationStatus.PENDING;
		}
		try {
			return DonationStatus.valueOf(value.trim().toUpperCase());
		} catch (IllegalArgumentException ex) {
			return DonationStatus.PENDING;
		}
	}
}
