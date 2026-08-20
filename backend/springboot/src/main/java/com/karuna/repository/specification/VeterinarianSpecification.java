package com.karuna.repository.specification;

import java.util.ArrayList;
import java.util.List;

import org.springframework.data.jpa.domain.Specification;
import org.springframework.util.StringUtils;

import com.karuna.entity.Veterinarian;

import jakarta.persistence.criteria.Predicate;

public final class VeterinarianSpecification {

	private VeterinarianSpecification() {
	}

	public static Specification<Veterinarian> withFilters(String specialization, Long locationId, String keyword) {
		return (root, query, builder) -> {
			List<Predicate> predicates = new ArrayList<>();

			if (StringUtils.hasText(specialization)) {
				predicates.add(builder.like(builder.lower(root.get("specialization")), "%" + specialization.toLowerCase() + "%"));
			}
			if (locationId != null) {
				predicates.add(builder.equal(root.get("clinicLocation").get("id"), locationId));
			}
			if (StringUtils.hasText(keyword)) {
				String like = "%" + keyword.toLowerCase() + "%";
				predicates.add(builder.or(
						builder.like(builder.lower(root.get("specialization")), like),
						builder.like(builder.lower(root.get("clinicName")), like)));
			}

			return predicates.isEmpty()
					? builder.conjunction()
					: builder.and(predicates.toArray(new Predicate[0]));
		};
	}
}
