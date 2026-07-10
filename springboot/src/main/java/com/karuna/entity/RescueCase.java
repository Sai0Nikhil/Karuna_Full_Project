package com.karuna.entity;

import java.time.LocalDateTime;
import java.util.LinkedHashSet;
import java.util.Set;

import com.karuna.entity.enums.CaseStatus;
import com.karuna.entity.enums.PriorityLevel;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.JoinTable;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.SQLDelete;
import org.hibernate.annotations.SQLRestriction;

@Getter
@Setter
@Entity
@SQLRestriction("deleted_at IS NULL")
@SQLDelete(sql = "UPDATE cases SET deleted_at = NOW() WHERE id = ?")
@Table(name = "cases")
public class RescueCase extends BaseEntity {

	@NotBlank
	@Size(max = 255)
	@Column(nullable = false)
	private String title;

	@Column(columnDefinition = "TEXT")
	private String description;

	@NotNull
	@Enumerated(EnumType.STRING)
	@Column(nullable = false, length = 50)
	private CaseStatus status = CaseStatus.REPORTED;

	@Size(max = 255)
	private String location;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "location_id")
	private Location geoLocation;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "reporter_id")
	private User reporter;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "animal_id")
	private Animal animal;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "ngo_id")
	private NGO ngo;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "primary_volunteer_id")
	private Volunteer primaryVolunteer;

	@ManyToMany
	@JoinTable(
			name = "case_volunteers",
			joinColumns = @JoinColumn(name = "case_id"),
			inverseJoinColumns = @JoinColumn(name = "volunteer_id")
	)
	private Set<Volunteer> assignedVolunteers = new LinkedHashSet<>();

	@Size(max = 100)
	@Column(name = "animal_type")
	private String animalType;

	@NotNull
	@Enumerated(EnumType.STRING)
	@Column(name = "severity", nullable = false, length = 50)
	private PriorityLevel priority = PriorityLevel.ROUTINE;

	@Column(name = "payload_json", columnDefinition = "TEXT")
	private String payloadJson;

	@OneToMany(mappedBy = "rescueCase")
	private Set<Donation> donations = new LinkedHashSet<>();

	@OneToMany(mappedBy = "rescueCase")
	private Set<AdoptionApplication> adoptionApplications = new LinkedHashSet<>();

	@OneToMany(mappedBy = "rescueCase")
	private Set<Treatment> treatments = new LinkedHashSet<>();

	@Column(nullable = false)
	private boolean active = true;

	@Column(name = "deleted_at")
	private LocalDateTime deletedAt;

	public String getStatus() {
		return status == null ? null : status.name().toLowerCase();
	}

	public void setStatus(String status) {
		this.status = parseCaseStatus(status);
	}

	public CaseStatus getCaseStatus() {
		return status;
	}

	public void setCaseStatus(CaseStatus caseStatus) {
		this.status = caseStatus;
	}

	public String getSeverity() {
		return priority == null ? null : priority.name().toLowerCase();
	}

	public void setSeverity(String severity) {
		this.priority = parsePriority(severity);
	}

	private CaseStatus parseCaseStatus(String value) {
		if (value == null || value.isBlank()) {
			return CaseStatus.REPORTED;
		}
		try {
			return CaseStatus.valueOf(value.trim().toUpperCase());
		} catch (IllegalArgumentException ex) {
			return CaseStatus.REPORTED;
		}
	}

	private PriorityLevel parsePriority(String value) {
		if (value == null || value.isBlank()) {
			return PriorityLevel.ROUTINE;
		}
		String normalized = value.trim().toUpperCase();
		if ("HIGH".equals(normalized)) {
			return PriorityLevel.HIGH;
		}
		try {
			return PriorityLevel.valueOf(normalized);
		} catch (IllegalArgumentException ex) {
			return PriorityLevel.ROUTINE;
		}
	}
}
