package com.karuna.entity;

import java.time.LocalDateTime;

import com.karuna.entity.enums.AdoptionStatus;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "adoption_applications")
public class AdoptionApplication extends BaseEntity {

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "case_id")
	private RescueCase rescueCase;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "animal_id")
	private Animal animal;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "applicant_id")
	private User applicant;

	@Size(max = 255)
	@Column(name = "applicant_name")
	private String applicantName;

	@Email
	@Size(max = 255)
	@Column(name = "contact_email")
	private String contactEmail;

	@Pattern(regexp = "^$|^[+]?[0-9]{7,20}$")
	@Column(name = "contact_phone", length = 30)
	private String contactPhone;

	@Column(columnDefinition = "TEXT")
	private String reason;

	@Size(max = 500)
	@Column(name = "adopter_id_url")
	private String adopterIdUrl;

	@NotNull
	@Enumerated(EnumType.STRING)
	@Column(nullable = false, length = 50)
	private AdoptionStatus status = AdoptionStatus.SUBMITTED;

	@Column(columnDefinition = "TEXT")
	private String notes;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "decided_by_id")
	private User decidedBy;

	@Column(name = "decided_at")
	private LocalDateTime decidedAt;

	public String getStatus() {
		return status == null ? null : status.name().toLowerCase();
	}

	public void setStatus(String status) {
		this.status = parseStatus(status);
	}

	public AdoptionStatus getAdoptionStatus() {
		return status;
	}

	public void setAdoptionStatus(AdoptionStatus adoptionStatus) {
		this.status = adoptionStatus;
	}

	private AdoptionStatus parseStatus(String value) {
		if (value == null || value.isBlank()) {
			return AdoptionStatus.SUBMITTED;
		}
		try {
			return AdoptionStatus.valueOf(value.trim().toUpperCase());
		} catch (IllegalArgumentException ex) {
			return AdoptionStatus.SUBMITTED;
		}
	}
}
