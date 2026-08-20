package com.karuna.repository.specification;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import org.springframework.data.jpa.domain.Specification;
import org.springframework.util.StringUtils;

import com.karuna.entity.Donation;
import com.karuna.entity.enums.DonationStatus;

import jakarta.persistence.criteria.Join;
import jakarta.persistence.criteria.JoinType;
import jakarta.persistence.criteria.Predicate;

public final class DonationSpecification {

	private DonationSpecification() {
	}

	public static Specification<Donation> withFilters(
			DonationStatus status,
			String currency,
			Long donorId,
			Long ngoId,
			Long caseId,
			String keyword,
			BigDecimal amountMin,
			BigDecimal amountMax,
			LocalDateTime dateFrom,
			LocalDateTime dateTo) {
		return (root, query, builder) -> {
			List<Predicate> predicates = new ArrayList<>();

			if (status != null) {
				predicates.add(builder.equal(root.get("status"), status));
			}
			if (StringUtils.hasText(currency)) {
				predicates.add(builder.equal(builder.lower(root.get("currency")), currency.toLowerCase()));
			}
			if (donorId != null) {
				predicates.add(builder.equal(root.get("donor").get("id"), donorId));
			}
			if (ngoId != null) {
				Join<Donation, com.karuna.entity.RescueCase> rescueCase = root.join("rescueCase", JoinType.LEFT);
				Join<com.karuna.entity.RescueCase, com.karuna.entity.NGO> ngo = rescueCase.join("ngo", JoinType.LEFT);
				predicates.add(builder.equal(ngo.get("id"), ngoId));
			}
			if (caseId != null) {
				predicates.add(builder.equal(root.get("rescueCase").get("id"), caseId));
			}
			if (StringUtils.hasText(keyword)) {
				predicates.add(builder.like(builder.lower(root.get("message")), "%" + keyword.toLowerCase() + "%"));
			}
			if (amountMin != null) {
				predicates.add(builder.greaterThanOrEqualTo(root.get("amount"), amountMin));
			}
			if (amountMax != null) {
				predicates.add(builder.lessThanOrEqualTo(root.get("amount"), amountMax));
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
