package com.karuna.repository.specification;

import java.util.ArrayList;
import java.util.List;

import org.springframework.data.jpa.domain.Specification;
import org.springframework.util.StringUtils;

import com.karuna.entity.AdoptionApplication;

import jakarta.persistence.criteria.Join;
import jakarta.persistence.criteria.JoinType;
import jakarta.persistence.criteria.Predicate;

public final class AdoptionSpecification {

	private AdoptionSpecification() {
	}

	public static Specification<AdoptionApplication> withFilters(
			com.karuna.entity.enums.AdoptionStatus status,
			Long animalId,
			Long applicantId,
			Long ngoId,
			String keyword,
			java.time.LocalDateTime dateFrom,
			java.time.LocalDateTime dateTo) {
		return (root, query, builder) -> {
			List<Predicate> predicates = new ArrayList<>();

			if (status != null) {
				predicates.add(builder.equal(root.get("status"), status));
			}
			if (animalId != null) {
				predicates.add(builder.equal(root.get("animal").get("id"), animalId));
			}
			if (applicantId != null) {
				predicates.add(builder.equal(root.get("applicant").get("id"), applicantId));
			}
			if (ngoId != null) {
				Join<AdoptionApplication, com.karuna.entity.RescueCase> rescueCase = root.join("rescueCase", JoinType.LEFT);
				Join<com.karuna.entity.RescueCase, com.karuna.entity.NGO> ngo = rescueCase.join("ngo", JoinType.LEFT);
				predicates.add(builder.equal(ngo.get("id"), ngoId));
			}
			if (StringUtils.hasText(keyword)) {
				String like = "%" + keyword.toLowerCase() + "%";
				predicates.add(builder.or(
						builder.like(builder.lower(root.get("reason")), like),
						builder.like(builder.lower(root.get("applicantName")), like)));
			}
			if (dateFrom != null) {
				predicates.add(builder.greaterThanOrEqualTo(root.get("createdAt"), dateFrom));
			}
			if (dateTo != null) {
				predicates.add(builder.lessThanOrEqualTo(root.get("createdAt"), dateTo));
			}

			return predicates.isEmpty()
					? builder.conjunction()
					: builder.and(predicates.toArray(new Predicate[0]));
		};
	}
}
