package com.karuna.service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.karuna.dto.domain.AnalyticsDto;
import com.karuna.entity.enums.AdoptionStatus;
import com.karuna.entity.enums.AnimalCondition;
import com.karuna.entity.enums.AnimalSpecies;
import com.karuna.entity.enums.CaseStatus;
import com.karuna.entity.enums.DonationStatus;
import com.karuna.entity.enums.PriorityLevel;
import com.karuna.entity.enums.VolunteerStatus;
import com.karuna.repository.AdoptionAnimalCount;
import com.karuna.repository.AdoptionApplicationRepository;
import com.karuna.repository.AdoptionNgoCount;
import com.karuna.repository.AnimalRepository;
import com.karuna.repository.CaseLocationCount;
import com.karuna.repository.CaseMonthCount;
import com.karuna.repository.CaseNgoCount;
import com.karuna.repository.CaseRepository;
import com.karuna.repository.CaseVolunteerCount;
import com.karuna.repository.DonationCurrencyStat;
import com.karuna.repository.DonationMonthCount;
import com.karuna.repository.DonationNgoCount;
import com.karuna.repository.DonationRepository;
import com.karuna.repository.NGORepository;
import com.karuna.repository.VeterinarianCaseCount;
import com.karuna.repository.VeterinarianRepository;
import com.karuna.repository.VeterinarianSpecializationCount;
import com.karuna.repository.VolunteerCaseCount;
import com.karuna.repository.VolunteerRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class AnalyticsService {

	private final CaseRepository caseRepository;
	private final AnimalRepository animalRepository;
	private final DonationRepository donationRepository;
	private final AdoptionApplicationRepository adoptionApplicationRepository;
	private final VolunteerRepository volunteerRepository;
	private final VeterinarianRepository veterinarianRepository;
	private final NGORepository ngoRepository;

	@Transactional(readOnly = true)
	public AnalyticsDto.DashboardResponse getDashboard() {
		long totalCases = caseRepository.count();
		long totalAnimals = animalRepository.count();
		long totalNgos = ngoRepository.count();
		long totalVolunteers = volunteerRepository.count();
		long totalVeterinarians = veterinarianRepository.count();
		long totalDonations = donationRepository.count();
		long totalAdoptions = adoptionApplicationRepository.count();

		Map<String, Long> casesByStatus = new java.util.HashMap<>();
		for (CaseStatus status : CaseStatus.values()) {
			long count = caseRepository.countByStatus(status);
			if (count > 0) {
				casesByStatus.put(status.name(), count);
			}
		}

		Map<String, Long> casesByPriority = new java.util.HashMap<>();
		for (PriorityLevel priority : PriorityLevel.values()) {
			long count = caseRepository.countByPriority(priority);
			if (count > 0) {
				casesByPriority.put(priority.name(), count);
			}
		}

		Map<String, Long> animalsBySpecies = new java.util.HashMap<>();
		for (AnimalSpecies species : AnimalSpecies.values()) {
			long count = animalRepository.countBySpecies(species);
			if (count > 0) {
				animalsBySpecies.put(species.name(), count);
			}
		}

		Map<String, Long> animalsByCondition = new java.util.HashMap<>();
		for (AnimalCondition condition : AnimalCondition.values()) {
			long count = animalRepository.countByCondition(condition);
			if (count > 0) {
				animalsByCondition.put(condition.name(), count);
			}
		}

		Map<String, Long> adoptionsByStatus = new java.util.HashMap<>();
		for (AdoptionStatus status : AdoptionStatus.values()) {
			long count = adoptionApplicationRepository.countByStatus(status);
			if (count > 0) {
				adoptionsByStatus.put(status.name(), count);
			}
		}

		BigDecimal completedAmount = orZero(donationRepository.sumAmountByStatus(DonationStatus.COMPLETED));
		BigDecimal pendingAmount = orZero(donationRepository.sumAmountByStatus(DonationStatus.PENDING));
		BigDecimal failedAmount = orZero(donationRepository.sumAmountByStatus(DonationStatus.FAILED));
		BigDecimal cancelledAmount = orZero(donationRepository.sumAmountByStatus(DonationStatus.CANCELLED));

		long recentActivity = countRecentActivity();

		return new AnalyticsDto.DashboardResponse(
				totalCases,
				casesByStatus,
				casesByPriority,
				totalAnimals,
				animalsBySpecies,
				animalsByCondition,
				totalNgos,
				totalVolunteers,
				totalVeterinarians,
				totalDonations,
				completedAmount,
				pendingAmount,
				failedAmount,
				cancelledAmount,
				totalAdoptions,
				adoptionsByStatus,
				recentActivity);
	}

	@Transactional(readOnly = true)
	public AnalyticsDto.CaseAnalyticsResponse getCaseAnalytics() {
		List<CaseMonthCount> monthCounts = caseRepository.countByMonth();
		List<CaseNgoCount> ngoCounts = caseRepository.findCaseCountsByNgo();
		List<CaseVolunteerCount> volunteerCounts = caseRepository.findCaseCountsByVolunteer();
		List<CaseLocationCount> locationCounts = caseRepository.countByLocation();

		Map<String, Long> casesByPriority = new java.util.HashMap<>();
		for (PriorityLevel priority : PriorityLevel.values()) {
			long count = caseRepository.countByPriority(priority);
			if (count > 0) {
				casesByPriority.put(priority.name(), count);
			}
		}

		Double avgSeconds = caseRepository.findAverageResolutionSeconds(
				List.of(CaseStatus.DISCHARGED, CaseStatus.ADOPTED, CaseStatus.RELEASED, CaseStatus.CANCELLED));
		double avgHours = avgSeconds != null ? avgSeconds / 3600.0 : 0.0;

		List<CaseStatus> openStatuses = List.of(CaseStatus.REPORTED, CaseStatus.ASSIGNED, CaseStatus.COLLECTED,
				CaseStatus.AT_CLINIC, CaseStatus.IN_TREATMENT);
		long openCases = openStatuses.stream().mapToLong(caseRepository::countByStatus).sum();

		List<CaseStatus> closedStatuses = List.of(CaseStatus.DISCHARGED, CaseStatus.ADOPTED, CaseStatus.RELEASED,
				CaseStatus.CANCELLED);
		long closedCases = closedStatuses.stream().mapToLong(caseRepository::countByStatus).sum();

		List<AnalyticsDto.CaseAnalyticsResponse.MonthlyCount> monthlyCounts = monthCounts.stream()
				.map(m -> new AnalyticsDto.CaseAnalyticsResponse.MonthlyCount(m.getMonth(), m.getCount()))
				.collect(Collectors.toList());

		List<AnalyticsDto.CaseAnalyticsResponse.EntityCount> ngoEntities = ngoCounts.stream()
				.map(c -> new AnalyticsDto.CaseAnalyticsResponse.EntityCount(c.getNgoId(), c.getNgoName(), c.getCount()))
				.collect(Collectors.toList());

		List<AnalyticsDto.CaseAnalyticsResponse.EntityCount> volunteerEntities = volunteerCounts.stream()
				.map(c -> new AnalyticsDto.CaseAnalyticsResponse.EntityCount(c.getVolunteerId(), null, c.getCount()))
				.collect(Collectors.toList());

		List<AnalyticsDto.CaseAnalyticsResponse.EntityCount> locationEntities = locationCounts.stream()
				.map(c -> new AnalyticsDto.CaseAnalyticsResponse.EntityCount(null, c.getLocation(), c.getCount()))
				.collect(Collectors.toList());

		return new AnalyticsDto.CaseAnalyticsResponse(
				monthlyCounts,
				ngoEntities,
				volunteerEntities,
				casesByPriority,
				locationEntities,
				avgHours,
				openCases,
				closedCases);
	}

	@Transactional(readOnly = true)
	public AnalyticsDto.AnimalAnalyticsResponse getAnimalAnalytics() {
		Map<String, Long> speciesDistribution = new java.util.HashMap<>();
		for (AnimalSpecies species : AnimalSpecies.values()) {
			long count = animalRepository.countBySpecies(species);
			if (count > 0) {
				speciesDistribution.put(species.name(), count);
			}
		}

		Map<String, Long> conditionDistribution = new java.util.HashMap<>();
		for (AnimalCondition condition : AnimalCondition.values()) {
			long count = animalRepository.countByCondition(condition);
			if (count > 0) {
				conditionDistribution.put(condition.name(), count);
			}
		}

		List<com.karuna.repository.AnimalRescueCaseCount> rescueCaseCounts = animalRepository.countByRescueCase();
		List<AnalyticsDto.AnimalAnalyticsResponse.EntityCount> byCase = rescueCaseCounts.stream()
				.map(c -> new AnalyticsDto.AnimalAnalyticsResponse.EntityCount(c.getCaseId(), null, c.getCount()))
				.collect(Collectors.toList());

		List<com.karuna.repository.AnimalLocationCount> locationCounts = animalRepository.countByLastKnownLocation();
		List<AnalyticsDto.AnimalAnalyticsResponse.EntityCount> byLocation = locationCounts.stream()
				.map(c -> new AnalyticsDto.AnimalAnalyticsResponse.EntityCount(null, c.getLocation(), c.getCount()))
				.collect(Collectors.toList());

		return new AnalyticsDto.AnimalAnalyticsResponse(
				speciesDistribution,
				conditionDistribution,
				byCase,
				byLocation);
	}

	@Transactional(readOnly = true)
	public AnalyticsDto.DonationAnalyticsResponse getDonationAnalytics() {
		long total = donationRepository.count();
		BigDecimal avg = orZero(donationRepository.findAverageAmount());
		BigDecimal max = orZero(donationRepository.findMaxAmount());

		List<DonationCurrencyStat> currencyStats = donationRepository.aggregateByCurrency();
		List<AnalyticsDto.DonationAnalyticsResponse.CurrencyBreakdown> byCurrency = currencyStats.stream()
				.map(s -> new AnalyticsDto.DonationAnalyticsResponse.CurrencyBreakdown(
						s.getCurrency(), s.getCount(), orZero(s.getTotal())))
				.collect(Collectors.toList());

		List<DonationMonthCount> monthCounts = donationRepository.countByMonth();
		List<AnalyticsDto.DonationAnalyticsResponse.MonthlyAmount> byMonth = monthCounts.stream()
				.map(m -> new AnalyticsDto.DonationAnalyticsResponse.MonthlyAmount(
						m.getMonth(), m.getCount(), orZero(m.getTotal())))
				.collect(Collectors.toList());

		List<DonationNgoCount> ngoCounts = donationRepository.countByNgo();
		List<AnalyticsDto.DonationAnalyticsResponse.EntityAmount> byNgo = ngoCounts.stream()
				.map(c -> new AnalyticsDto.DonationAnalyticsResponse.EntityAmount(
						c.getNgoId(), c.getNgoName(), c.getCount(), orZero(c.getTotal())))
				.collect(Collectors.toList());

		Map<String, Long> byStatus = new java.util.HashMap<>();
		for (DonationStatus status : DonationStatus.values()) {
			long count = donationRepository.countByStatus(status);
			if (count > 0) {
				byStatus.put(status.name(), count);
			}
		}

		return new AnalyticsDto.DonationAnalyticsResponse(
				total,
				avg,
				max,
				byCurrency,
				byMonth,
				byNgo,
				byStatus);
	}

	@Transactional(readOnly = true)
	public AnalyticsDto.AdoptionAnalyticsResponse getAdoptionAnalytics() {
		long total = adoptionApplicationRepository.count();

		Map<String, Long> byStatus = new java.util.HashMap<>();
		for (AdoptionStatus status : AdoptionStatus.values()) {
			long count = adoptionApplicationRepository.countByStatus(status);
			if (count > 0) {
				byStatus.put(status.name(), count);
			}
		}

		long approved = adoptionApplicationRepository.countByStatus(AdoptionStatus.APPROVED);
		long rejected = adoptionApplicationRepository.countByStatus(AdoptionStatus.REJECTED);
		long completed = adoptionApplicationRepository.countByStatus(AdoptionStatus.COMPLETED);
		long withdrawn = adoptionApplicationRepository.countByStatus(AdoptionStatus.WITHDRAWN);

		double approvalRate = total > 0 ? (approved * 100.0 / total) : 0.0;
		double rejectionRate = total > 0 ? (rejected * 100.0 / total) : 0.0;
		double completionRate = total > 0 ? (completed * 100.0 / total) : 0.0;
		double withdrawnRate = total > 0 ? (withdrawn * 100.0 / total) : 0.0;

		List<AdoptionAnimalCount> animalCounts = adoptionApplicationRepository.countByAnimal();
		List<AnalyticsDto.AdoptionAnalyticsResponse.EntityCount> perAnimal = animalCounts.stream()
				.map(c -> new AnalyticsDto.AdoptionAnalyticsResponse.EntityCount(c.getAnimalId(), null, c.getCount()))
				.collect(Collectors.toList());

		List<AdoptionNgoCount> ngoCounts = adoptionApplicationRepository.countByNgo();
		List<AnalyticsDto.AdoptionAnalyticsResponse.EntityCount> perNgo = ngoCounts.stream()
				.map(c -> new AnalyticsDto.AdoptionAnalyticsResponse.EntityCount(c.getNgoId(), c.getNgoName(), c.getCount()))
				.collect(Collectors.toList());

		return new AnalyticsDto.AdoptionAnalyticsResponse(
				byStatus,
				approvalRate,
				rejectionRate,
				completionRate,
				withdrawnRate,
				perAnimal,
				perNgo);
	}

	@Transactional(readOnly = true)
	public AnalyticsDto.VolunteerAnalyticsResponse getVolunteerAnalytics() {
		long available = volunteerRepository.countByStatus(VolunteerStatus.AVAILABLE);
		long busy = volunteerRepository.countByStatus(VolunteerStatus.BUSY);

		Double avgCases = volunteerRepository.findAverageAssignedCases();
		double average = avgCases != null ? avgCases : 0.0;

		List<VolunteerCaseCount> caseCounts = volunteerRepository.findCaseCountsByVolunteer();
		List<AnalyticsDto.VolunteerAnalyticsResponse.EntityCount> perVolunteer = caseCounts.stream()
				.map(c -> new AnalyticsDto.VolunteerAnalyticsResponse.EntityCount(
						c.getVolunteerId(), c.getUserName(), c.getCaseCount()))
				.collect(Collectors.toList());

		return new AnalyticsDto.VolunteerAnalyticsResponse(
				available,
				busy,
				average,
				perVolunteer);
	}

	@Transactional(readOnly = true)
	public AnalyticsDto.VeterinarianAnalyticsResponse getVeterinarianAnalytics() {
		long active = veterinarianRepository.countByActiveTrue();

		Double avgCases = veterinarianRepository.findAverageCasesPerVeterinarian();
		double average = avgCases != null ? avgCases : 0.0;

		List<VeterinarianSpecializationCount> specCounts = veterinarianRepository.countBySpecialization();
		Map<String, Long> specializationDistribution = specCounts.stream()
				.collect(Collectors.toMap(
						VeterinarianSpecializationCount::getSpecialization,
						VeterinarianSpecializationCount::getCount));

		return new AnalyticsDto.VeterinarianAnalyticsResponse(
				active,
				average,
				specializationDistribution);
	}

	private long countRecentActivity() {
		LocalDateTime thirtyDaysAgo = LocalDateTime.now().minusDays(30);
		long cases = caseRepository.countByCreatedAtAfter(thirtyDaysAgo);
		long animals = animalRepository.countByCreatedAtAfter(thirtyDaysAgo);
		long donations = donationRepository.countByCreatedAtAfter(thirtyDaysAgo);
		long adoptions = adoptionApplicationRepository.countByCreatedAtAfter(thirtyDaysAgo);
		return cases + animals + donations + adoptions;
	}

	private BigDecimal orZero(BigDecimal value) {
		return value != null ? value : BigDecimal.ZERO;
	}
}
