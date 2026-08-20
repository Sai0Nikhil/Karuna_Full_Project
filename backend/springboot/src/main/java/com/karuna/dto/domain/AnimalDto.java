package com.karuna.dto.domain;

import java.time.LocalDateTime;

import com.karuna.entity.enums.AnimalCondition;
import com.karuna.entity.enums.AnimalSpecies;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public final class AnimalDto {
	private AnimalDto() {
	}

	public record Request(
			@Size(max = 120) String name,
			@NotNull AnimalSpecies species,
			@Size(max = 120) String breed,
			@NotNull AnimalCondition condition,
			@Size(max = 50) String color,
			@Size(max = 40) String sex,
			@Size(max = 80) String estimatedAge,
			@Positive Long lastKnownLocationId) {
	}

	public record Update(
			@Size(max = 120) String name,
			AnimalSpecies species,
			@Size(max = 120) String breed,
			AnimalCondition condition,
			@Size(max = 50) String color,
			@Size(max = 40) String sex,
			@Size(max = 80) String estimatedAge,
			Boolean active,
			@Positive Long lastKnownLocationId) {
	}

	public record Response(
			Long id,
			String name,
			AnimalSpecies species,
			String breed,
			AnimalCondition condition,
			String color,
			String sex,
			String estimatedAge,
			Long lastKnownLocationId,
			Boolean active,
			LocalDateTime createdAt,
			LocalDateTime updatedAt,
			Long version) {
	}

	public record Summary(Long id, String name, AnimalSpecies species, AnimalCondition condition) {
	}
}
