package com.karuna.service;

import java.util.List;
import java.util.Map;
import java.util.Set;

import com.karuna.entity.enums.AdoptionStatus;
import com.karuna.exception.BusinessException;

public final class AdoptionStatusMachine {

	private AdoptionStatusMachine() {
	}

	private static final Map<AdoptionStatus, List<AdoptionStatus>> TRANSITIONS = Map.of(
			AdoptionStatus.SUBMITTED, List.of(AdoptionStatus.UNDER_REVIEW, AdoptionStatus.WITHDRAWN),
			AdoptionStatus.UNDER_REVIEW, List.of(AdoptionStatus.APPROVED, AdoptionStatus.REJECTED, AdoptionStatus.WITHDRAWN),
			AdoptionStatus.APPROVED, List.of(AdoptionStatus.COMPLETED),
			AdoptionStatus.REJECTED, List.of(),
			AdoptionStatus.COMPLETED, List.of(),
			AdoptionStatus.WITHDRAWN, List.of());

	public static boolean canTransition(AdoptionStatus from, AdoptionStatus to) {
		if (from == null || to == null) {
			return false;
		}
		return TRANSITIONS.getOrDefault(from, List.of()).contains(to);
	}

	public static void validate(AdoptionStatus from, AdoptionStatus to) {
		if (!canTransition(from, to)) {
			throw new BusinessException(
					"Cannot transition adoption application from " + from + " to " + to);
		}
	}

	public static Set<AdoptionStatus> allowedTargets(AdoptionStatus from) {
		return Set.copyOf(TRANSITIONS.getOrDefault(from, List.of()));
	}
}
