package com.karuna.service;

import java.util.List;
import java.util.Map;
import java.util.Set;

import com.karuna.entity.enums.DonationStatus;
import com.karuna.exception.BusinessException;

public final class DonationStatusMachine {

	private DonationStatusMachine() {
	}

	private static final Map<DonationStatus, List<DonationStatus>> TRANSITIONS = Map.of(
			DonationStatus.PENDING, List.of(DonationStatus.PROCESSING, DonationStatus.FAILED, DonationStatus.CANCELLED),
			DonationStatus.PROCESSING, List.of(DonationStatus.COMPLETED, DonationStatus.FAILED, DonationStatus.CANCELLED),
			DonationStatus.COMPLETED, List.of(),
			DonationStatus.FAILED, List.of(DonationStatus.PROCESSING),
			DonationStatus.CANCELLED, List.of());

	public static boolean canTransition(DonationStatus from, DonationStatus to) {
		if (from == null || to == null) {
			return false;
		}
		return TRANSITIONS.getOrDefault(from, List.of()).contains(to);
	}

	public static void validate(DonationStatus from, DonationStatus to) {
		if (!canTransition(from, to)) {
			throw new BusinessException(
					"Cannot transition donation from " + from + " to " + to);
		}
	}

	public static Set<DonationStatus> allowedTargets(DonationStatus from) {
		return Set.copyOf(TRANSITIONS.getOrDefault(from, List.of()));
	}
}
