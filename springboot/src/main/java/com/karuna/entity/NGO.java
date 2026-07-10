package com.karuna.entity;

import java.time.LocalDateTime;
import java.util.LinkedHashSet;
import java.util.Set;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
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
@SQLDelete(sql = "UPDATE ngos SET deleted_at = NOW() WHERE id = ?")
@Table(
		name = "ngos",
		uniqueConstraints = {
				@UniqueConstraint(name = "uk_ngos_registration_number", columnNames = "registration_number"),
				@UniqueConstraint(name = "uk_ngos_email", columnNames = "email")
		}
)
public class NGO extends BaseEntity {

	@NotBlank
	@Size(max = 255)
	@Column(nullable = false)
	private String name;

	@NotBlank
	@Size(max = 100)
	@Column(name = "registration_number", nullable = false, unique = true)
	private String registrationNumber;

	@Email
	@Size(max = 255)
	@Column(unique = true)
	private String email;

	@Pattern(regexp = "^$|^[+]?[0-9]{7,20}$")
	@Column(name = "phone_number", length = 30)
	private String phoneNumber;

	@Column(columnDefinition = "TEXT")
	private String description;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "headquarters_location_id")
	private Location headquartersLocation;

	@OneToMany(mappedBy = "ngo")
	private Set<RescueCase> rescueCases = new LinkedHashSet<>();

	@ManyToMany(mappedBy = "ngos")
	private Set<Volunteer> volunteers = new LinkedHashSet<>();

	@Column(nullable = false)
	private boolean verified = false;

	@Column(nullable = false)
	private boolean active = true;

	@Column(name = "deleted_at")
	private LocalDateTime deletedAt;
}
