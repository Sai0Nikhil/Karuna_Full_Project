package com.karuna.entity;

import java.time.LocalDateTime;
import java.util.LinkedHashSet;
import java.util.Set;

import com.karuna.entity.enums.UserRole;

import jakarta.persistence.CascadeType;
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
@SQLDelete(sql = "UPDATE users SET deleted_at = NOW() WHERE id = ?")
@Table(
		name = "users",
		uniqueConstraints = {
				@UniqueConstraint(name = "uk_users_email", columnNames = "email"),
				@UniqueConstraint(name = "uk_users_phone_number", columnNames = "phone_number")
		}
)
public class User extends BaseEntity {

	@NotBlank
	@Size(max = 255)
	@Column(nullable = false)
	private String name;

	@NotBlank
	@Email
	@Size(max = 255)
	@Column(nullable = false, unique = true)
	private String email;

	@Pattern(regexp = "^$|^[+]?[0-9]{7,20}$")
	@Column(name = "phone_number", unique = true, length = 30)
	private String phoneNumber;

	@NotBlank
	@Column(name = "password_hash", nullable = false)
	private String passwordHash;

	@Enumerated(EnumType.STRING)
	@Column(name = "role", nullable = false, length = 50)
	private UserRole primaryRole = UserRole.CITIZEN;

	@ManyToMany(fetch = FetchType.LAZY)
	@JoinTable(
			name = "user_roles",
			joinColumns = @JoinColumn(name = "user_id"),
			inverseJoinColumns = @JoinColumn(name = "role_id")
	)
	private Set<Role> roles = new LinkedHashSet<>();

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "location_id")
	private Location location;

	@OneToOne(mappedBy = "user", cascade = CascadeType.ALL, orphanRemoval = true)
	private Volunteer volunteerProfile;

	@OneToOne(mappedBy = "user", cascade = CascadeType.ALL, orphanRemoval = true)
	private Veterinarian veterinarianProfile;

	@OneToMany(mappedBy = "reporter")
	private Set<RescueCase> reportedCases = new LinkedHashSet<>();

	@OneToMany(mappedBy = "donor")
	private Set<Donation> donations = new LinkedHashSet<>();

	@OneToMany(mappedBy = "applicant")
	private Set<AdoptionApplication> adoptionApplications = new LinkedHashSet<>();

	@Column(nullable = false)
	private boolean active = true;

	@Column(name = "email_verified", nullable = false)
	private boolean emailVerified;

	@Column(name = "account_locked", nullable = false)
	private boolean accountLocked;

	@Column(name = "failed_login_attempts", nullable = false)
	private int failedLoginAttempts;

	@Column(name = "locked_until")
	private LocalDateTime lockedUntil;

	@Column(name = "deleted_at")
	private LocalDateTime deletedAt;

	public String getRole() {
		return primaryRole == null ? null : primaryRole.name();
	}

	public void setRole(String role) {
		this.primaryRole = parseRole(role);
	}

	public UserRole getUserRole() {
		return primaryRole;
	}

	public void setUserRole(UserRole userRole) {
		this.primaryRole = userRole;
	}

	private UserRole parseRole(String role) {
		if (role == null || role.isBlank()) {
			return UserRole.CITIZEN;
		}
		try {
			return UserRole.valueOf(role.trim().toUpperCase());
		} catch (IllegalArgumentException ex) {
			return UserRole.CITIZEN;
		}
	}
}
