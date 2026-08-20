package com.karuna.repository.specification;

import java.util.ArrayList;
import java.util.List;

import org.springframework.data.jpa.domain.Specification;
import org.springframework.util.StringUtils;

import com.karuna.entity.RescueCase;
import com.karuna.entity.Volunteer;
import com.karuna.entity.enums.CaseStatus;
import com.karuna.entity.enums.PriorityLevel;

import jakarta.persistence.criteria.Join;
import jakarta.persistence.criteria.JoinType;
import jakarta.persistence.criteria.Predicate;

public final class RescueCaseSpecification {

	private RescueCaseSpecification() {
	}

	public static Specification<RescueCase> withFilters(
			CaseStatus status,
			PriorityLevel priority,
			Long reporterId,
			Long ngoId,
			Long volunteerId,
			String search) {
		return (root, query, builder) -> {
			List<Predicate> predicates = new ArrayList<>();

			if (status != null) {
				predicates.add(builder.equal(root.get("status"), status));
			}
			if (priority != null) {
				predicates.add(builder.equal(root.get("priority"), priority));
			}
			if (reporterId != null) {
				predicates.add(builder.equal(root.get("reporter").get("id"), reporterId));
			}
			if (ngoId != null) {
				predicates.add(builder.equal(root.get("ngo").get("id"), ngoId));
			}
			if (volunteerId != null) {
				Join<RescueCase, Volunteer> assigned = root.join("assignedVolunteers", JoinType.LEFT);
				predicates.add(builder.or(
						builder.equal(root.get("primaryVolunteer").get("id"), volunteerId),
						builder.equal(assigned.get("id"), volunteerId)));
			}
			if (StringUtils.hasText(search)) {
				String like = "%" + search.toLowerCase() + "%";
				predicates.add(builder.or(
						builder.like(builder.lower(root.get("title")), like),
						builder.like(builder.lower(root.get("description")), like),
						builder.like(builder.lower(root.get("location")), like)));
			}

			return predicates.isEmpty()
					? builder.conjunction()
					: builder.and(predicates.toArray(new Predicate[0]));
		};
	}
}
