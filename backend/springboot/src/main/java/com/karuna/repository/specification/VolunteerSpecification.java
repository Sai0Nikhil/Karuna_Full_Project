package com.karuna.repository.specification;

import java.util.ArrayList;
import java.util.List;

import org.springframework.data.jpa.domain.Specification;
import org.springframework.util.StringUtils;

import com.karuna.entity.Volunteer;
import com.karuna.entity.enums.VolunteerStatus;

import jakarta.persistence.criteria.Join;
import jakarta.persistence.criteria.JoinType;
import jakarta.persistence.criteria.Predicate;

public final class VolunteerSpecification {

	private VolunteerSpecification() {
	}

	public static Specification<Volunteer> withFilters(
			VolunteerStatus status, Long locationId, Long ngoId, String keyword) {
		return (root, query, builder) -> {
			List<Predicate> predicates = new ArrayList<>();

			if (status != null) {
				predicates.add(builder.equal(root.get("status"), status));
			}
			if (locationId != null) {
				predicates.add(builder.equal(root.get("serviceLocation").get("id"), locationId));
			}
			if (ngoId != null) {
				Join<Volunteer, com.karuna.entity.NGO> ngos = root.join("ngos", JoinType.LEFT);
				predicates.add(builder.equal(ngos.get("id"), ngoId));
			}
			if (StringUtils.hasText(keyword)) {
				predicates.add(builder.like(builder.lower(root.get("skills")), "%" + keyword.toLowerCase() + "%"));
			}

			return predicates.isEmpty()
					? builder.conjunction()
					: builder.and(predicates.toArray(new Predicate[0]));
		};
	}
}
