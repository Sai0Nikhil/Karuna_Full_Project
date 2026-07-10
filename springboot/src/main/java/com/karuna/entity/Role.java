package com.karuna.entity;

import java.util.LinkedHashSet;
import java.util.Set;

import com.karuna.entity.enums.UserRole;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "roles", uniqueConstraints = @UniqueConstraint(name = "uk_roles_name", columnNames = "name"))
public class Role extends BaseEntity {

	@NotNull
	@Enumerated(EnumType.STRING)
	@Column(nullable = false, length = 50, unique = true)
	private UserRole name;

	@Size(max = 255)
	private String description;

	@ManyToMany(mappedBy = "roles")
	private Set<User> users = new LinkedHashSet<>();
}
