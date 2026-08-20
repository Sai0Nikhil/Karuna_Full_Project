package com.karuna.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;

import com.karuna.dto.DonationStatusChangeDTO;
import com.karuna.dto.MessageResponseDTO;
import com.karuna.dto.domain.DonationDto;
import com.karuna.dto.domain.DonationSummaryDto;
import com.karuna.entity.Donation;
import com.karuna.entity.NGO;
import com.karuna.entity.RescueCase;
import com.karuna.entity.User;
import com.karuna.entity.enums.DonationStatus;
import com.karuna.exception.BusinessException;
import com.karuna.exception.ResourceNotFoundException;
import com.karuna.mapper.DonationMapper;
import com.karuna.payment.DummyPaymentProvider;
import com.karuna.payment.PaymentProvider;
import com.karuna.payment.PaymentRequest;
import com.karuna.payment.PaymentResponse;
import com.karuna.repository.CaseRepository;
import com.karuna.repository.DonationRepository;
import com.karuna.repository.UserRepository;
import com.karuna.repository.specification.DonationSpecification;

@ExtendWith(MockitoExtension.class)
class DonationServiceTest {

	@Mock
	private DonationRepository donationRepository;
	@Mock
	private DonationMapper donationMapper;
	@Mock
	private UserRepository userRepository;
	@Mock
	private CaseRepository caseRepository;
	@Mock
	private PaymentProvider paymentProvider;

	private DonationService donationService;

	private User donor;
	private RescueCase rescueCase;
	private Donation donation;

	@BeforeEach
	void setUp() {
		donationService = new DonationService(donationRepository, donationMapper, userRepository, caseRepository,
				paymentProvider);

		donor = new User();
		donor.setId(1L);
		donor.setPrimaryRole(com.karuna.entity.enums.UserRole.CITIZEN);

		rescueCase = new RescueCase();
		rescueCase.setId(2L);

		donation = new Donation();
		donation.setId(10L);
		donation.setDonor(donor);
		donation.setRescueCase(rescueCase);
		donation.setAmount(new BigDecimal("100.00"));
		donation.setCurrency("INR");
		donation.setDonationStatus(DonationStatus.PENDING);
	}

	@Test
	void createRejectsZeroAmount() {
		DonationDto.Request request = new DonationDto.Request(null, null, BigDecimal.ZERO, "INR", null, null, null, null);

		assertThrows(BusinessException.class, () -> donationService.create(request, donor));
		verify(donationRepository, never()).save(any());
	}

	@Test
	void createRejectsDuplicatePaymentReference() {
		DonationDto.Request request = new DonationDto.Request(null, null, new BigDecimal("100.00"), "INR", null,
				"DUPLICATE-REF", null, null);
		Donation entity = new Donation();
		when(donationRepository.findByPaymentReference("DUPLICATE-REF")).thenReturn(Optional.of(new Donation()));
		when(donationMapper.toEntity(request)).thenReturn(entity);

		assertThrows(BusinessException.class, () -> donationService.create(request, donor));
		verify(donationRepository, never()).save(any());
	}

	@Test
	void createSetsPendingAndSaves() {
		DonationDto.Request request = new DonationDto.Request(null, null, new BigDecimal("100.00"), "INR", null, null,
				null, null);
		Donation entity = new Donation();
		DonationDto.Response response = new DonationDto.Response(10L, 1L, null, new BigDecimal("100.00"), "INR",
				DonationStatus.PENDING, null, null, null, LocalDateTime.now(), LocalDateTime.now(), 0L);

		when(paymentProvider.process(any(PaymentRequest.class)))
				.thenReturn(new PaymentResponse(true, "txn-1", "PENDING", "ok"));
		when(donationMapper.toEntity(request)).thenReturn(entity);
		when(donationRepository.save(entity)).thenReturn(entity);
		when(donationMapper.toResponse(entity)).thenReturn(response);

		DonationDto.Response result = donationService.create(request, donor);

		assertEquals(DonationStatus.PENDING, entity.getDonationStatus());
		assertEquals(donor, entity.getDonor());
		verify(donationRepository).save(entity);
	}

	@Test
	void getThrowsWhenMissing() {
		when(donationRepository.findById(7L)).thenReturn(Optional.empty());
		assertThrows(ResourceNotFoundException.class, () -> donationService.get(7L, donor));
	}

	@Test
	void listUsesSpecification() {
		Page<Donation> page = new PageImpl<>(List.of(donation));
		when(donationRepository.findAll(any(org.springframework.data.jpa.domain.Specification.class), any(Pageable.class)))
				.thenReturn(page);
		when(donationMapper.toResponse(any(Donation.class)))
				.thenReturn(new DonationDto.Response(10L, 1L, null, new BigDecimal("100.00"), "INR", DonationStatus.PENDING,
						null, null, null, LocalDateTime.now(), LocalDateTime.now(), 0L));

		Page<DonationDto.Response> result = donationService.list(null, null, null, null, null, null, null, null, null,
				null, donor, Pageable.ofSize(10));

		assertEquals(1, result.getTotalElements());
	}

	@Test
	void updateThrowsWhenNotPending() {
		donation.setDonationStatus(DonationStatus.COMPLETED);
		when(donationRepository.findById(10L)).thenReturn(Optional.of(donation));

		assertThrows(BusinessException.class,
				() -> donationService.update(10L, new DonationDto.Update(null, "msg"), donor));
	}

	@Test
	void cancelThrowsWhenNotPending() {
		donation.setDonationStatus(DonationStatus.COMPLETED);
		when(donationRepository.findById(10L)).thenReturn(Optional.of(donation));

		assertThrows(BusinessException.class, () -> donationService.cancel(10L, donor));
	}

	@Test
	void cancelSucceedsWhenPending() {
		when(donationRepository.findById(10L)).thenReturn(Optional.of(donation));
		when(donationRepository.save(donation)).thenReturn(donation);
		when(donationMapper.toResponse(donation))
				.thenReturn(new DonationDto.Response(10L, 1L, null, new BigDecimal("100.00"), "INR",
						DonationStatus.CANCELLED, null, null, null, LocalDateTime.now(), LocalDateTime.now(), 0L));

		DonationDto.Response result = donationService.cancel(10L, donor);

		assertEquals(DonationStatus.CANCELLED, donation.getDonationStatus());
		verify(donationRepository).save(donation);
	}

	@Test
	void changeStatusValidatesTransition() {
		when(donationRepository.findById(10L)).thenReturn(Optional.of(donation));
		DonationStatusChangeDTO dto = new DonationStatusChangeDTO();
		dto.setStatus(DonationStatus.COMPLETED);

		assertThrows(BusinessException.class, () -> donationService.changeStatus(10L, dto, donor));
	}

	@Test
	void changeStatusSucceedsForValidTransition() {
		when(donationRepository.findById(10L)).thenReturn(Optional.of(donation));
		when(donationRepository.save(donation)).thenReturn(donation);
		when(donationMapper.toResponse(donation))
				.thenReturn(new DonationDto.Response(10L, 1L, null, new BigDecimal("100.00"), "INR",
						DonationStatus.PROCESSING, null, null, null, LocalDateTime.now(), LocalDateTime.now(), 0L));
		DonationStatusChangeDTO dto = new DonationStatusChangeDTO();
		dto.setStatus(DonationStatus.PROCESSING);

		DonationDto.Response result = donationService.changeStatus(10L, dto, donor);

		assertEquals(DonationStatus.PROCESSING, donation.getDonationStatus());
	}

	@Test
	void deleteRemovesDonation() {
		when(donationRepository.findById(10L)).thenReturn(Optional.of(donation));

		MessageResponseDTO result = donationService.delete(10L);

		assertEquals("Donation deleted successfully", result.getMessage());
		verify(donationRepository).delete(donation);
	}

	@Test
	void summaryCalculatesStatistics() {
		when(donationRepository.count()).thenReturn(3L);
		when(donationRepository.countByStatus(DonationStatus.COMPLETED)).thenReturn(1L);
		when(donationRepository.sumAmountByStatus(DonationStatus.COMPLETED)).thenReturn(new BigDecimal("200.00"));
		when(donationRepository.countByStatus(DonationStatus.PENDING)).thenReturn(1L);
		when(donationRepository.sumAmountByStatus(DonationStatus.PENDING)).thenReturn(new BigDecimal("100.00"));
		when(donationRepository.countByStatus(DonationStatus.FAILED)).thenReturn(0L);
		when(donationRepository.sumAmountByStatus(DonationStatus.FAILED)).thenReturn(null);
		when(donationRepository.countByStatus(DonationStatus.CANCELLED)).thenReturn(1L);
		when(donationRepository.sumAmountByStatus(DonationStatus.CANCELLED)).thenReturn(new BigDecimal("50.00"));
		when(donationRepository.countByStatus(DonationStatus.PROCESSING)).thenReturn(0L);
		when(donationRepository.sumAmountByStatus(DonationStatus.PROCESSING)).thenReturn(null);
		when(donationRepository.aggregateByCurrency())
				.thenReturn(List.of(new com.karuna.repository.DonationCurrencyStat() {
					@Override
					public String getCurrency() {
						return "INR";
					}

					@Override
					public Long getCount() {
						return 3L;
					}

					@Override
					public BigDecimal getTotal() {
						return new BigDecimal("350.00");
					}
				}));

		DonationSummaryDto.Response result = donationService.summary();

		assertEquals(3L, result.totalDonations());
		assertEquals(new BigDecimal("200.00"), result.totalCompletedAmount());
		assertEquals(new BigDecimal("100.00"), result.pendingAmount());
		assertEquals(BigDecimal.ZERO, result.failedAmount());
		assertEquals(new BigDecimal("50.00"), result.cancelledAmount());
		assertEquals(1, result.byCurrency().size());
	}

	@Test
	void assertReadableThrowsForNonOwnerCitizen() {
		User otherUser = new User();
		otherUser.setId(99L);
		otherUser.setPrimaryRole(com.karuna.entity.enums.UserRole.CITIZEN);

		assertThrows(BusinessException.class, () -> donationService.get(10L, otherUser));
	}

	@Test
	void assertManageableThrowsForNonOwnerNonAdmin() {
		User otherUser = new User();
		otherUser.setId(99L);
		otherUser.setPrimaryRole(com.karuna.entity.enums.UserRole.CITIZEN);

		assertThrows(BusinessException.class, () -> donationService.cancel(10L, otherUser));
	}
}
