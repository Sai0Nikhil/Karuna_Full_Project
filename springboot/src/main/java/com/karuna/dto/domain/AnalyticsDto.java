package com.karuna.dto.domain;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public final class AnalyticsDto {
	private AnalyticsDto() {
	}

	public record DashboardResponse(
			long totalRescueCases,
			Map<String, Long> casesByStatus,
			Map<String, Long> casesByPriority,
			long totalAnimals,
			Map<String, Long> animalsBySpecies,
			Map<String, Long> animalsByCondition,
			long totalNgos,
			long totalVolunteers,
			long totalVeterinarians,
			long totalDonations,
			BigDecimal completedDonationAmount,
			BigDecimal pendingDonationAmount,
			BigDecimal failedDonationAmount,
			BigDecimal cancelledDonationAmount,
			long totalAdoptionApplications,
			Map<String, Long> adoptionsByStatus,
			long recentActivityCount) {
	}

	public record CaseAnalyticsResponse(
			List<MonthlyCount> casesByMonth,
			List<EntityCount> casesByNgo,
			List<EntityCount> casesByVolunteer,
			Map<String, Long> casesByPriority,
			List<EntityCount> casesByLocation,
			Double averageResolutionHours,
			long openCases,
			long closedCases) {
		public record MonthlyCount(String month, long count) {
		}

		public record EntityCount(Long id, String name, long count) {
		}
	}

	public record AnimalAnalyticsResponse(
			Map<String, Long> speciesDistribution,
			Map<String, Long> conditionDistribution,
			List<EntityCount> animalsByRescueCase,
			List<EntityCount> animalsByLocation) {
		public record EntityCount(Long id, String name, long count) {
		}
	}

	public record DonationAnalyticsResponse(
			long totalDonations,
			BigDecimal averageDonation,
			BigDecimal largestDonation,
			List<CurrencyBreakdown> donationsByCurrency,
			List<MonthlyAmount> donationsByMonth,
			List<EntityAmount> donationsByNgo,
			Map<String, Long> donationsByStatus) {
		public record CurrencyBreakdown(String currency, long count, BigDecimal total) {
		}

		public record MonthlyAmount(String month, long count, BigDecimal total) {
		}

		public record EntityAmount(Long id, String name, long count, BigDecimal total) {
		}
	}

	public record AdoptionAnalyticsResponse(
			Map<String, Long> applicationsByStatus,
			double approvalRate,
			double rejectionRate,
			double completionRate,
			double withdrawnRate,
			List<EntityCount> applicationsPerAnimal,
			List<EntityCount> applicationsPerNgo) {
		public record EntityCount(Long id, String name, long count) {
		}
	}

	public record VolunteerAnalyticsResponse(
			long availableVolunteers,
			long busyVolunteers,
			Double averageAssignedCases,
			List<EntityCount> casesPerVolunteer) {
		public record EntityCount(Long volunteerId, String userName, long caseCount) {
		}
	}

	public record VeterinarianAnalyticsResponse(
			long activeVeterinarians,
			Double averageCasesPerVeterinarian,
			Map<String, Long> specializationDistribution) {
	}
}
