package com.karuna.entity;

import java.time.LocalDateTime;
import java.util.LinkedHashSet;
import java.util.Set;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
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
@SQLDelete(sql = "UPDATE veterinarians SET deleted_at = NOW() WHERE id = ?")
@Table(
		name = "veterinarians",
		uniqueConstraints = {
				@UniqueConstraint(name = "uk_veterinarians_user_id", columnNames = "user_id"),
				@UniqueConstraint(name = "uk_veterinarians_license_number", columnNames = "license_number")
		}
)
public class Veterinarian extends BaseEntity {

	@NotNull
	@OneToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "user_id", nullable = false, unique = true)
	private User user;

	@NotBlank
	@Size(max = 120)
	@Column(name = "license_number", nullable = false, unique = true)
	private String licenseNumber;

	@Size(max = 255)
	@Column(name = "clinic_name")
	private String clinicName;

	@Size(max = 120)
	private String specialization;

	@Email
	@Size(max = 255)
	private String email;

	@Pattern(regexp = "^$|^[+]?[0-9]{7,20}$")
	@Column(name = "phone_number", length = 30)
	private String phoneNumber;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "clinic_location_id")
	private Location clinicLocation;

	@OneToMany(mappedBy = "veterinarian")
	private Set<Treatment> treatments = new LinkedHashSet<>();

	@Column(nullable = false)
	private boolean active = true;

	@Column(name = "deleted_at")
	private LocalDateTime deletedAt;
}
