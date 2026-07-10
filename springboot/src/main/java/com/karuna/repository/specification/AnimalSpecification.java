package com.karuna.repository.specification;

import java.util.ArrayList;
import java.util.List;

import org.springframework.data.jpa.domain.Specification;
import org.springframework.util.StringUtils;

import com.karuna.entity.Animal;
import com.karuna.entity.enums.AnimalCondition;
import com.karuna.entity.enums.AnimalSpecies;

import jakarta.persistence.criteria.Predicate;

public final class AnimalSpecification {

	private AnimalSpecification() {
	}

	public static Specification<Animal> withFilters(
			AnimalSpecies species,
			AnimalCondition condition,
			Long locationId,
			Long caseId,
			String keyword) {
		return (root, query, builder) -> {
			List<Predicate> predicates = new ArrayList<>();

			if (species != null) {
				predicates.add(builder.equal(root.get("species"), species));
			}
			if (condition != null) {
				predicates.add(builder.equal(root.get("condition"), condition));
			}
			if (locationId != null) {
				predicates.add(builder.equal(root.get("lastKnownLocation").get("id"), locationId));
			}
			if (caseId != null) {
				predicates.add(builder.equal(root.join("rescueCases").get("id"), caseId));
			}
			if (StringUtils.hasText(keyword)) {
				String like = "%" + keyword.toLowerCase() + "%";
				predicates.add(builder.or(
						builder.like(builder.lower(root.get("name")), like),
						builder.like(builder.lower(root.get("breed")), like),
						builder.like(builder.lower(root.get("color")), like)));
			}

			return predicates.isEmpty()
					? builder.conjunction()
					: builder.and(predicates.toArray(new Predicate[0]));
		};
	}
}
