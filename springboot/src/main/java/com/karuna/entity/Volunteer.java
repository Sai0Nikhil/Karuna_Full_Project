package com.karuna.entity;

import java.time.LocalDateTime;
import java.util.LinkedHashSet;
import java.util.Set;

import com.karuna.entity.enums.VolunteerStatus;

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
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.SQLDelete;
import org.hibernate.annotations.SQLRestriction;

@Getter
@Setter
@Entity
@SQLRestriction("deleted_at IS NULL")
@SQLDelete(sql = "UPDATE volunteers SET deleted_at = NOW() WHERE id = ?")
@Table(name = "volunteers", uniqueConstraints = @UniqueConstraint(name = "uk_volunteers_user_id", columnNames = "user_id"))
public class Volunteer extends BaseEntity {

	@NotNull
	@OneToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "user_id", nullable = false, unique = true)
	private User user;

	@Pattern(regexp = "^$|^[+]?[0-9]{7,20}$")
	@Column(name = "phone_number", length = 30)
	private String phoneNumber;

	@Enumerated(EnumType.STRING)
	@Column(nullable = false, length = 50)
	private VolunteerStatus status = VolunteerStatus.AVAILABLE;

	@Size(max = 255)
	private String skills;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "service_location_id")
	private Location serviceLocation;

	@ManyToMany
	@JoinTable(
			name = "ngo_volunteers",
			joinColumns = @JoinColumn(name = "volunteer_id"),
			inverseJoinColumns = @JoinColumn(name = "ngo_id")
	)
	private Set<NGO> ngos = new LinkedHashSet<>();

	@OneToMany(mappedBy = "primaryVolunteer")
	private Set<RescueCase> primaryCases = new LinkedHashSet<>();

	@ManyToMany(mappedBy = "assignedVolunteers")
	private Set<RescueCase> assignedCases = new LinkedHashSet<>();

	@Column(nullable = false)
	private boolean active = true;

	@Column(name = "deleted_at")
	private LocalDateTime deletedAt;
}
