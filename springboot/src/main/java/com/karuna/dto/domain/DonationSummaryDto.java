package com.karuna.dto.domain;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

import com.karuna.entity.enums.DonationStatus;

public final class DonationSummaryDto {

	private DonationSummaryDto() {
	}

	public record StatusStat(long count, BigDecimal total) {
	}

	public record CurrencyStat(String currency, long count, BigDecimal total) {
	}

	public record Response(
			long totalDonations,
			BigDecimal totalCompletedAmount,
			BigDecimal pendingAmount,
			BigDecimal failedAmount,
			BigDecimal cancelledAmount,
			Map<DonationStatus, StatusStat> byStatus,
			List<CurrencyStat> byCurrency) {
	}
}
