package com.karuna.service;

import java.math.BigDecimal;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.karuna.dto.DonationStatusChangeDTO;
import com.karuna.dto.MessageResponseDTO;
import com.karuna.dto.domain.DonationDto;
import com.karuna.dto.domain.DonationSummaryDto;
import com.karuna.dto.domain.DonationSummaryDto.CurrencyStat;
import com.karuna.dto.domain.DonationSummaryDto.Response;
import com.karuna.dto.domain.DonationSummaryDto.StatusStat;
import com.karuna.entity.Donation;
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

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class DonationService {

	private final DonationRepository donationRepository;
	private final DonationMapper donationMapper;
	private final UserRepository userRepository;
	private final CaseRepository caseRepository;
	private final PaymentProvider paymentProvider;

	@Transactional
	public DonationDto.Response create(DonationDto.Request request, User donor) {
		if (request.amount() == null || request.amount().compareTo(BigDecimal.ZERO) <= 0) {
			throw new BusinessException("Donation amount must be greater than zero");
		}
		Donation entity = donationMapper.toEntity(request);
		entity.setDonor(donor);
		if (request.caseId() != null) {
			RescueCase rescueCase = caseRepository.findById(request.caseId())
					.orElseThrow(() -> new ResourceNotFoundException("Rescue case not found with id " + request.caseId()));
			entity.setRescueCase(rescueCase);
		}
		entity.setDonationStatus(DonationStatus.PENDING);

		String providerName = request.paymentProvider() != null ? request.paymentProvider() : DummyPaymentProvider.class.getSimpleName();
		String reference = request.paymentReference();
		if (reference == null || reference.isBlank()) {
			PaymentResponse response = paymentProvider.process(
					new PaymentRequest(entity.getAmount(), entity.getCurrency(), providerName, null, Map.of()));
			reference = response.transactionId();
		}
		if (donationRepository.findByPaymentReference(reference).isPresent()) {
			throw new BusinessException("A donation with this payment reference already exists");
		}
		entity.setPaymentReference(reference);
		entity.setPaymentProvider(providerName);

		return donationMapper.toResponse(donationRepository.save(entity));
	}

	@Transactional(readOnly = true)
	public DonationDto.Response get(Long id, User currentUser) {
		Donation donation = findOrThrow(id);
		assertReadable(donation, currentUser);
		return donationMapper.toResponse(donation);
	}

	@Transactional(readOnly = true)
	public Page<DonationDto.Response> list(
			DonationStatus status,
			String currency,
			Long donorId,
			Long ngoId,
			Long caseId,
			String keyword,
			BigDecimal amountMin,
			BigDecimal amountMax,
			java.time.LocalDateTime dateFrom,
			java.time.LocalDateTime dateTo,
			User currentUser,
			Pageable pageable) {
		Long effectiveDonorId = donorId;
		if (!isAdmin(currentUser) && !isNgo(currentUser)) {
			effectiveDonorId = currentUser.getId();
		}
		var specification = DonationSpecification.withFilters(
				status, currency, effectiveDonorId, ngoId, caseId, keyword, amountMin, amountMax, dateFrom, dateTo);
		return donationRepository.findAll(specification, pageable).map(donationMapper::toResponse);
	}

	@Transactional
	public DonationDto.Response update(Long id, DonationDto.Update request, User currentUser) {
		Donation donation = findOrThrow(id);
		assertManageable(donation, currentUser);
		if (donation.getDonationStatus() != DonationStatus.PENDING) {
			throw new BusinessException("Only pending donations can be edited");
		}
		if (request.message() != null) {
			donation.setMessage(request.message());
		}
		return donationMapper.toResponse(donationRepository.save(donation));
	}

	@Transactional
	public DonationDto.Response changeStatus(Long id, DonationStatusChangeDTO request, User currentUser) {
		Donation donation = findOrThrow(id);
		assertManageable(donation, currentUser);
		DonationStatusMachine.validate(donation.getDonationStatus(), request.getStatus());
		donation.setDonationStatus(request.getStatus());
		return donationMapper.toResponse(donationRepository.save(donation));
	}

	@Transactional
	public DonationDto.Response cancel(Long id, User currentUser) {
		Donation donation = findOrThrow(id);
		assertManageable(donation, currentUser);
		if (donation.getDonationStatus() != DonationStatus.PENDING) {
			throw new BusinessException("Only pending donations can be cancelled");
		}
		donation.setDonationStatus(DonationStatus.CANCELLED);
		return donationMapper.toResponse(donationRepository.save(donation));
	}

	@Transactional
	public MessageResponseDTO delete(Long id) {
		donationRepository.delete(findOrThrow(id));
		return new MessageResponseDTO("Donation deleted successfully");
	}

	@Transactional(readOnly = true)
	public Page<DonationDto.Response> search(String keyword, User currentUser, Pageable pageable) {
		return list(null, null, null, null, null, keyword, null, null, null, null, currentUser, pageable);
	}

	@Transactional(readOnly = true)
	public Response summary() {
		long total = donationRepository.count();
		Map<DonationStatus, StatusStat> byStatus = new EnumMap<>(DonationStatus.class);
		for (DonationStatus status : DonationStatus.values()) {
			byStatus.put(status, new StatusStat(
					donationRepository.countByStatus(status),
					orZero(donationRepository.sumAmountByStatus(status))));
		}
		List<CurrencyStat> byCurrency = donationRepository.aggregateByCurrency().stream()
				.map(stat -> new CurrencyStat(stat.getCurrency(), stat.getCount(), orZero(stat.getTotal())))
				.toList();

		return new Response(
				total,
				orZero(donationRepository.sumAmountByStatus(DonationStatus.COMPLETED)),
				orZero(donationRepository.sumAmountByStatus(DonationStatus.PENDING)),
				orZero(donationRepository.sumAmountByStatus(DonationStatus.FAILED)),
				orZero(donationRepository.sumAmountByStatus(DonationStatus.CANCELLED)),
				byStatus,
				byCurrency);
	}

	private Donation findOrThrow(Long id) {
		return donationRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("Donation not found with id " + id));
	}

	private void assertReadable(Donation donation, User currentUser) {
		if (isAdmin(currentUser) || isNgo(currentUser)) {
			return;
		}
		if (donation.getDonor() == null || !donation.getDonor().getId().equals(currentUser.getId())) {
			throw new BusinessException("You are not authorized to view this donation");
		}
	}

	private void assertManageable(Donation donation, User currentUser) {
		if (isAdmin(currentUser)) {
			return;
		}
		if (donation.getDonor() == null || !donation.getDonor().getId().equals(currentUser.getId())) {
			throw new BusinessException("You are not authorized to manage this donation");
		}
	}

	private boolean isAdmin(User user) {
		return "ADMIN".equals(user.getRole());
	}

	private boolean isNgo(User user) {
		return "NGO".equals(user.getRole());
	}

	private BigDecimal orZero(BigDecimal value) {
		return value == null ? BigDecimal.ZERO : value;
	}
}
