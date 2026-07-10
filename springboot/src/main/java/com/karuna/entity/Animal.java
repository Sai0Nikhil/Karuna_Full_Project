package com.karuna.entity;

import java.time.LocalDateTime;
import java.util.LinkedHashSet;
import java.util.Set;

import com.karuna.entity.enums.AnimalCondition;
import com.karuna.entity.enums.AnimalSpecies;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
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
@SQLDelete(sql = "UPDATE animals SET deleted_at = NOW() WHERE id = ?")
@Table(name = "animals")
public class Animal extends BaseEntity {

	@Size(max = 120)
	private String name;

	@NotNull
	@Enumerated(EnumType.STRING)
	@Column(nullable = false, length = 50)
	private AnimalSpecies species = AnimalSpecies.UNKNOWN;

	@Size(max = 120)
	private String breed;

	@NotNull
	@Enumerated(EnumType.STRING)
	@Column(nullable = false, length = 50)
	private AnimalCondition condition = AnimalCondition.UNKNOWN;

	@Size(max = 50)
	private String color;

	@Size(max = 40)
	private String sex;

	@Size(max = 80)
	@Column(name = "estimated_age")
	private String estimatedAge;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "last_known_location_id")
	private Location lastKnownLocation;

	@OneToMany(mappedBy = "animal")
	private Set<RescueCase> rescueCases = new LinkedHashSet<>();

	@OneToMany(mappedBy = "animal")
	private Set<Treatment> treatments = new LinkedHashSet<>();

	@OneToMany(mappedBy = "animal")
	private Set<AdoptionApplication> adoptionApplications = new LinkedHashSet<>();

	@Column(nullable = false)
	private boolean active = true;

	@Column(name = "deleted_at")
	private LocalDateTime deletedAt;
}
