package com.karuna.service;

import java.util.List;
import java.util.Map;
import java.util.Set;

import com.karuna.entity.enums.CaseStatus;
import com.karuna.exception.BusinessException;

public final class RescueCaseStatusMachine {

	private RescueCaseStatusMachine() {
	}

	private static final Map<CaseStatus, List<CaseStatus>> TRANSITIONS = Map.of(
			CaseStatus.REPORTED, List.of(CaseStatus.ASSIGNED, CaseStatus.CANCELLED),
			CaseStatus.ASSIGNED, List.of(CaseStatus.COLLECTED, CaseStatus.CANCELLED),
			CaseStatus.COLLECTED, List.of(CaseStatus.AT_CLINIC, CaseStatus.CANCELLED),
			CaseStatus.AT_CLINIC, List.of(CaseStatus.IN_TREATMENT, CaseStatus.CANCELLED),
			CaseStatus.IN_TREATMENT, List.of(CaseStatus.DISCHARGED, CaseStatus.CANCELLED),
			CaseStatus.DISCHARGED, List.of(CaseStatus.ADOPTED, CaseStatus.RELEASED, CaseStatus.CANCELLED),
			CaseStatus.ADOPTED, List.of(),
			CaseStatus.RELEASED, List.of(),
			CaseStatus.CANCELLED, List.of());

	public static boolean canTransition(CaseStatus from, CaseStatus to) {
		if (from == null || to == null) {
			return false;
		}
		return TRANSITIONS.getOrDefault(from, List.of()).contains(to);
	}

	public static void validate(CaseStatus from, CaseStatus to) {
		if (!canTransition(from, to)) {
			throw new BusinessException(
					"Cannot transition rescue case from " + from + " to " + to);
		}
	}

	public static Set<CaseStatus> allowedTargets(CaseStatus from) {
		return Set.copyOf(TRANSITIONS.getOrDefault(from, List.of()));
	}
}
