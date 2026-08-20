package com.karuna.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

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

@ExtendWith(MockitoExtension.class)
class AnalyticsServiceTest {

	@Mock
	private CaseRepository caseRepository;
	@Mock
	private AnimalRepository animalRepository;
	@Mock
	private DonationRepository donationRepository;
	@Mock
	private AdoptionApplicationRepository adoptionApplicationRepository;
	@Mock
	private VolunteerRepository volunteerRepository;
	@Mock
	private VeterinarianRepository veterinarianRepository;
	@Mock
	private NGORepository ngoRepository;

	private AnalyticsService analyticsService;

	@BeforeEach
	void setUp() {
		analyticsService = new AnalyticsService(caseRepository, animalRepository, donationRepository,
				adoptionApplicationRepository, volunteerRepository, veterinarianRepository, ngoRepository);
	}

	@Test
	void getDashboardReturnsAggregates() {
		when(caseRepository.count()).thenReturn(10L);
		when(animalRepository.count()).thenReturn(20L);
		when(ngoRepository.count()).thenReturn(3L);
		when(volunteerRepository.count()).thenReturn(5L);
		when(veterinarianRepository.count()).thenReturn(2L);
		when(donationRepository.count()).thenReturn(50L);
		when(adoptionApplicationRepository.count()).thenReturn(8L);

		for (CaseStatus status : CaseStatus.values()) {
			lenient().when(caseRepository.countByStatus(status)).thenReturn(0L);
		}
		lenient().when(caseRepository.countByStatus(CaseStatus.REPORTED)).thenReturn(3L);

		for (PriorityLevel priority : PriorityLevel.values()) {
			lenient().when(caseRepository.countByPriority(priority)).thenReturn(0L);
		}
		lenient().when(caseRepository.countByPriority(PriorityLevel.HIGH)).thenReturn(2L);

		for (AnimalSpecies species : AnimalSpecies.values()) {
			lenient().when(animalRepository.countBySpecies(species)).thenReturn(0L);
		}
		lenient().when(animalRepository.countBySpecies(AnimalSpecies.DOG)).thenReturn(10L);

		for (AnimalCondition condition : AnimalCondition.values()) {
			lenient().when(animalRepository.countByCondition(condition)).thenReturn(0L);
		}
		lenient().when(animalRepository.countByCondition(AnimalCondition.INJURED)).thenReturn(4L);

		for (AdoptionStatus status : AdoptionStatus.values()) {
			lenient().when(adoptionApplicationRepository.countByStatus(status)).thenReturn(0L);
		}
		lenient().when(adoptionApplicationRepository.countByStatus(AdoptionStatus.SUBMITTED)).thenReturn(5L);

		for (DonationStatus status : DonationStatus.values()) {
			lenient().when(donationRepository.sumAmountByStatus(status)).thenReturn(null);
		}
		lenient().when(donationRepository.sumAmountByStatus(DonationStatus.COMPLETED)).thenReturn(new BigDecimal("1000.00"));
		lenient().when(donationRepository.sumAmountByStatus(DonationStatus.PENDING)).thenReturn(new BigDecimal("200.00"));
		lenient().when(donationRepository.sumAmountByStatus(DonationStatus.FAILED)).thenReturn(BigDecimal.ZERO);
		lenient().when(donationRepository.sumAmountByStatus(DonationStatus.CANCELLED)).thenReturn(new BigDecimal("50.00"));

		lenient().when(caseRepository.countByCreatedAtAfter(org.mockito.ArgumentMatchers.any(LocalDateTime.class))).thenReturn(2L);
		lenient().when(animalRepository.countByCreatedAtAfter(org.mockito.ArgumentMatchers.any(LocalDateTime.class))).thenReturn(3L);
		lenient().when(donationRepository.countByCreatedAtAfter(org.mockito.ArgumentMatchers.any(LocalDateTime.class))).thenReturn(10L);
		lenient().when(adoptionApplicationRepository.countByCreatedAtAfter(org.mockito.ArgumentMatchers.any(LocalDateTime.class))).thenReturn(1L);

		AnalyticsDto.DashboardResponse result = analyticsService.getDashboard();

		assertEquals(10L, result.totalRescueCases());
		assertEquals(20L, result.totalAnimals());
		assertEquals(3L, result.totalNgos());
		assertEquals(50L, result.totalDonations());
		assertEquals(new BigDecimal("1000.00"), result.completedDonationAmount());
		assertEquals(new BigDecimal("200.00"), result.pendingDonationAmount());
		assertEquals(BigDecimal.ZERO, result.failedDonationAmount());
		assertEquals(new BigDecimal("50.00"), result.cancelledDonationAmount());
		assertEquals(16L, result.recentActivityCount());
	}

	@Test
	void getCaseAnalyticsReturnsBreakdowns() {
		when(caseRepository.countByMonth()).thenReturn(List.of(new CaseMonthCount() {
			@Override
			public String getMonth() {
				return "2025-01";
			}

			@Override
			public long getCount() {
				return 5L;
			}
		}));
		when(caseRepository.findCaseCountsByNgo()).thenReturn(List.of(new CaseNgoCount() {
			@Override
			public Long getNgoId() {
				return 1L;
			}

			@Override
			public String getNgoName() {
				return "NGO 1";
			}

			@Override
			public long getCount() {
				return 3L;
			}
		}));
		when(caseRepository.findCaseCountsByVolunteer()).thenReturn(List.of(new CaseVolunteerCount() {
			@Override
			public Long getVolunteerId() {
				return 1L;
			}

			@Override
			public long getCount() {
				return 2L;
			}
		}));
		when(caseRepository.countByLocation()).thenReturn(List.of(new CaseLocationCount() {
			@Override
			public String getLocation() {
				return "Bangalore";
			}

			@Override
			public long getCount() {
				return 4L;
			}
		}));

		for (PriorityLevel priority : PriorityLevel.values()) {
			lenient().when(caseRepository.countByPriority(priority)).thenReturn(0L);
		}
		lenient().when(caseRepository.countByPriority(PriorityLevel.HIGH)).thenReturn(2L);

		for (CaseStatus status : CaseStatus.values()) {
			lenient().when(caseRepository.countByStatus(status)).thenReturn(0L);
		}
		lenient().when(caseRepository.countByStatus(CaseStatus.REPORTED)).thenReturn(3L);
		lenient().when(caseRepository.countByStatus(CaseStatus.ASSIGNED)).thenReturn(2L);
		lenient().when(caseRepository.countByStatus(CaseStatus.DISCHARGED)).thenReturn(1L);
		lenient().when(caseRepository.countByStatus(CaseStatus.CANCELLED)).thenReturn(1L);

		when(caseRepository.findAverageResolutionSeconds(org.mockito.ArgumentMatchers.anyList())).thenReturn(7200.0);

		AnalyticsDto.CaseAnalyticsResponse result = analyticsService.getCaseAnalytics();

		assertEquals(1, result.casesByMonth().size());
		assertEquals(1, result.casesByNgo().size());
		assertEquals(1, result.casesByVolunteer().size());
		assertEquals(1, result.casesByLocation().size());
		assertEquals(2.0, result.averageResolutionHours());
		assertEquals(5L, result.openCases());
		assertEquals(2L, result.closedCases());
	}

	@Test
	void getAnimalAnalyticsReturnsDistributions() {
		for (AnimalSpecies species : AnimalSpecies.values()) {
			lenient().when(animalRepository.countBySpecies(species)).thenReturn(0L);
		}
		lenient().when(animalRepository.countBySpecies(AnimalSpecies.DOG)).thenReturn(10L);

		for (AnimalCondition condition : AnimalCondition.values()) {
			lenient().when(animalRepository.countByCondition(condition)).thenReturn(0L);
		}
		lenient().when(animalRepository.countByCondition(AnimalCondition.HEALTHY)).thenReturn(8L);

		when(animalRepository.countByRescueCase()).thenReturn(List.of(new com.karuna.repository.AnimalRescueCaseCount() {
			@Override
			public Long getCaseId() {
				return 1L;
			}

			@Override
			public long getCount() {
				return 3L;
			}
		}));
		when(animalRepository.countByLastKnownLocation()).thenReturn(List.of(new com.karuna.repository.AnimalLocationCount() {
			@Override
			public String getLocation() {
				return "Mumbai";
			}

			@Override
			public long getCount() {
				return 5L;
			}
		}));

		AnalyticsDto.AnimalAnalyticsResponse result = analyticsService.getAnimalAnalytics();

		assertEquals(1, result.speciesDistribution().size());
		assertEquals(1, result.conditionDistribution().size());
		assertEquals(1, result.animalsByRescueCase().size());
		assertEquals(1, result.animalsByLocation().size());
	}

	@Test
	void getDonationAnalyticsReturnsStats() {
		when(donationRepository.count()).thenReturn(100L);
		when(donationRepository.findAverageAmount()).thenReturn(new BigDecimal("50.00"));
		when(donationRepository.findMaxAmount()).thenReturn(new BigDecimal("500.00"));
		when(donationRepository.aggregateByCurrency()).thenReturn(List.of(new DonationCurrencyStat() {
			@Override
			public String getCurrency() {
				return "INR";
			}

			@Override
			public Long getCount() {
				return 80L;
			}

			@Override
			public BigDecimal getTotal() {
				return new BigDecimal("4000.00");
			}
		}));
		when(donationRepository.countByMonth()).thenReturn(List.of(new DonationMonthCount() {
			@Override
			public String getMonth() {
				return "2025-01";
			}

			@Override
			public long getCount() {
				return 10L;
			}

			@Override
			public BigDecimal getTotal() {
				return new BigDecimal("500.00");
			}
		}));
		when(donationRepository.countByNgo()).thenReturn(List.of(new DonationNgoCount() {
			@Override
			public Long getNgoId() {
				return 1L;
			}

			@Override
			public String getNgoName() {
				return "NGO 1";
			}

			@Override
			public long getCount() {
				return 20L;
			}

			@Override
			public BigDecimal getTotal() {
				return new BigDecimal("1000.00");
			}
		}));

		for (DonationStatus status : DonationStatus.values()) {
			lenient().when(donationRepository.countByStatus(status)).thenReturn(0L);
		}
		lenient().when(donationRepository.countByStatus(DonationStatus.COMPLETED)).thenReturn(60L);
		lenient().when(donationRepository.countByStatus(DonationStatus.PENDING)).thenReturn(30L);

		AnalyticsDto.DonationAnalyticsResponse result = analyticsService.getDonationAnalytics();

		assertEquals(100L, result.totalDonations());
		assertEquals(new BigDecimal("50.00"), result.averageDonation());
		assertEquals(new BigDecimal("500.00"), result.largestDonation());
		assertEquals(1, result.donationsByCurrency().size());
		assertEquals(1, result.donationsByMonth().size());
		assertEquals(1, result.donationsByNgo().size());
	}

	@Test
	void getAdoptionAnalyticsReturnsRates() {
		when(adoptionApplicationRepository.count()).thenReturn(100L);

		for (AdoptionStatus status : AdoptionStatus.values()) {
			lenient().when(adoptionApplicationRepository.countByStatus(status)).thenReturn(0L);
		}
		lenient().when(adoptionApplicationRepository.countByStatus(AdoptionStatus.APPROVED)).thenReturn(40L);
		lenient().when(adoptionApplicationRepository.countByStatus(AdoptionStatus.REJECTED)).thenReturn(20L);
		lenient().when(adoptionApplicationRepository.countByStatus(AdoptionStatus.COMPLETED)).thenReturn(10L);
		lenient().when(adoptionApplicationRepository.countByStatus(AdoptionStatus.WITHDRAWN)).thenReturn(5L);
		lenient().when(adoptionApplicationRepository.countByStatus(AdoptionStatus.SUBMITTED)).thenReturn(25L);

		when(adoptionApplicationRepository.countByAnimal()).thenReturn(List.of(new AdoptionAnimalCount() {
			@Override
			public Long getAnimalId() {
				return 1L;
			}

			@Override
			public long getCount() {
				return 3L;
			}
		}));
		when(adoptionApplicationRepository.countByNgo()).thenReturn(List.of(new AdoptionNgoCount() {
			@Override
			public Long getNgoId() {
				return 1L;
			}

			@Override
			public String getNgoName() {
				return "NGO 1";
			}

			@Override
			public long getCount() {
				return 15L;
			}
		}));

		AnalyticsDto.AdoptionAnalyticsResponse result = analyticsService.getAdoptionAnalytics();

		assertEquals(40.0, result.approvalRate(), 0.01);
		assertEquals(20.0, result.rejectionRate(), 0.01);
		assertEquals(10.0, result.completionRate(), 0.01);
		assertEquals(5.0, result.withdrawnRate(), 0.01);
		assertEquals(1, result.applicationsPerAnimal().size());
		assertEquals(1, result.applicationsPerNgo().size());
	}

	@Test
	void getVolunteerAnalyticsReturnsAvailability() {
		for (VolunteerStatus status : VolunteerStatus.values()) {
			lenient().when(volunteerRepository.countByStatus(status)).thenReturn(0L);
		}
		lenient().when(volunteerRepository.countByStatus(VolunteerStatus.AVAILABLE)).thenReturn(8L);
		lenient().when(volunteerRepository.countByStatus(VolunteerStatus.BUSY)).thenReturn(4L);
		lenient().when(volunteerRepository.findAverageAssignedCases()).thenReturn(3.5);
		lenient().when(volunteerRepository.findCaseCountsByVolunteer()).thenReturn(List.of(new VolunteerCaseCount() {
			@Override
			public Long getVolunteerId() {
				return 1L;
			}

			@Override
			public String getUserName() {
				return "John";
			}

			@Override
			public long getCaseCount() {
				return 5L;
			}
		}));

		AnalyticsDto.VolunteerAnalyticsResponse result = analyticsService.getVolunteerAnalytics();

		assertEquals(8L, result.availableVolunteers());
		assertEquals(4L, result.busyVolunteers());
		assertEquals(3.5, result.averageAssignedCases());
		assertEquals(1, result.casesPerVolunteer().size());
	}

	@Test
	void getVeterinarianAnalyticsReturnsSpecializations() {
		lenient().when(veterinarianRepository.countByActiveTrue()).thenReturn(6L);
		lenient().when(veterinarianRepository.findAverageCasesPerVeterinarian()).thenReturn(4.2);
		lenient().when(veterinarianRepository.countBySpecialization()).thenReturn(List.of(new VeterinarianSpecializationCount() {
			@Override
			public String getSpecialization() {
				return "Surgery";
			}

			@Override
			public long getCount() {
				return 3L;
			}
		}));

		AnalyticsDto.VeterinarianAnalyticsResponse result = analyticsService.getVeterinarianAnalytics();

		assertEquals(6L, result.activeVeterinarians());
		assertEquals(4.2, result.averageCasesPerVeterinarian());
		assertEquals(1, result.specializationDistribution().size());
	}
}
