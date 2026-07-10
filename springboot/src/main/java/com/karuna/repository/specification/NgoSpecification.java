package com.karuna.repository.specification;

import java.util.ArrayList;
import java.util.List;

import org.springframework.data.jpa.domain.Specification;
import org.springframework.util.StringUtils;

import com.karuna.entity.NGO;

import jakarta.persistence.criteria.Predicate;

public final class NgoSpecification {

	private NgoSpecification() {
	}

	public static Specification<NGO> withFilters(String keyword, Long locationId, Boolean active, Boolean verified) {
		return (root, query, builder) -> {
			List<Predicate> predicates = new ArrayList<>();

			if (StringUtils.hasText(keyword)) {
				predicates.add(builder.like(builder.lower(root.get("name")), "%" + keyword.toLowerCase() + "%"));
			}
			if (locationId != null) {
				predicates.add(builder.equal(root.get("headquartersLocation").get("id"), locationId));
			}
			if (active != null) {
				predicates.add(builder.equal(root.get("active"), active));
			}
			if (verified != null) {
				predicates.add(builder.equal(root.get("verified"), verified));
			}

			return predicates.isEmpty()
					? builder.conjunction()
					: builder.and(predicates.toArray(new Predicate[0]));
		};
	}
}
