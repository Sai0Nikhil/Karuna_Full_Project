package com.karuna.service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.karuna.dto.MessageResponseDTO;
import com.karuna.dto.domain.AdoptionApplicationDto;
import com.karuna.entity.AdoptionApplication;
import com.karuna.entity.Animal;
import com.karuna.entity.RescueCase;
import com.karuna.entity.User;
import com.karuna.entity.enums.AdoptionStatus;
import com.karuna.exception.BusinessException;
import com.karuna.exception.ResourceNotFoundException;
import com.karuna.mapper.AdoptionApplicationMapper;
import com.karuna.repository.AdoptionApplicationRepository;
import com.karuna.repository.AnimalRepository;
import com.karuna.repository.CaseRepository;
import com.karuna.repository.UserRepository;
import com.karuna.repository.specification.AdoptionSpecification;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class AdoptionService {

	private final AdoptionApplicationRepository adoptionApplicationRepository;
	private final AdoptionApplicationMapper adoptionApplicationMapper;
	private final UserRepository userRepository;
	private final AnimalRepository animalRepository;
	private final CaseRepository caseRepository;

	@Transactional
	public AdoptionApplicationDto.Response create(AdoptionApplicationDto.Request request, User applicant) {
		RescueCase rescueCase = null;
		Animal animal = null;

		if (request.caseId() != null) {
			rescueCase = caseRepository.findById(request.caseId())
					.orElseThrow(() -> new ResourceNotFoundException("Rescue case not found with id " + request.caseId()));
		}
		if (request.animalId() != null) {
			animal = animalRepository.findById(request.animalId())
					.orElseThrow(() -> new ResourceNotFoundException("Animal not found with id " + request.animalId()));
		}

		List<AdoptionStatus> activeStatuses = List.of(AdoptionStatus.SUBMITTED, AdoptionStatus.UNDER_REVIEW, AdoptionStatus.APPROVED);
		if (request.animalId() != null) {
			List<AdoptionApplication> existing = adoptionApplicationRepository
					.findByApplicantIdAndAnimalIdAndStatusIn(applicant.getId(), request.animalId(), activeStatuses);
			if (!existing.isEmpty()) {
				throw new BusinessException("You already have an active adoption application for this animal");
			}
			boolean hasApproved = adoptionApplicationRepository.existsByAnimalIdAndStatus(request.animalId(), AdoptionStatus.APPROVED);
			if (hasApproved) {
				throw new BusinessException("This animal already has an approved adoption application");
			}
		}

		AdoptionApplication entity = adoptionApplicationMapper.toEntity(request);
		entity.setRescueCase(rescueCase);
		entity.setAnimal(animal);
		entity.setApplicant(applicant);
		entity.setAdoptionStatus(AdoptionStatus.SUBMITTED);

		return adoptionApplicationMapper.toResponse(adoptionApplicationRepository.save(entity));
	}

	@Transactional(readOnly = true)
	public AdoptionApplicationDto.Response get(Long id, User currentUser) {
		AdoptionApplication application = findOrThrow(id);
		assertReadable(application, currentUser);
		return adoptionApplicationMapper.toResponse(application);
	}

	@Transactional(readOnly = true)
	public Page<AdoptionApplicationDto.Response> list(
			AdoptionStatus status,
			Long animalId,
			Long applicantId,
			Long ngoId,
			String keyword,
			LocalDateTime dateFrom,
			LocalDateTime dateTo,
			User currentUser,
			Pageable pageable) {
		Long effectiveApplicantId = applicantId;
		if (!isAdmin(currentUser) && !isNgo(currentUser)) {
			effectiveApplicantId = currentUser.getId();
		}
		var specification = AdoptionSpecification.withFilters(
				status, animalId, effectiveApplicantId, ngoId, keyword, dateFrom, dateTo);
		return adoptionApplicationRepository.findAll(specification, pageable)
				.map(adoptionApplicationMapper::toResponse);
	}

	@Transactional
	public AdoptionApplicationDto.Response update(Long id, AdoptionApplicationDto.Update request, User currentUser) {
		AdoptionApplication application = findOrThrow(id);
		assertManageable(application, currentUser);
		if (application.getAdoptionStatus() != AdoptionStatus.SUBMITTED) {
			throw new BusinessException("Only submitted adoption applications can be edited");
		}
		adoptionApplicationMapper.updateEntity(request, application);
		return adoptionApplicationMapper.toResponse(adoptionApplicationRepository.save(application));
	}

	@Transactional
	public AdoptionApplicationDto.Response changeStatus(Long id, AdoptionStatus newStatus, User currentUser) {
		AdoptionApplication application = findOrThrow(id);
		assertManageable(application, currentUser);
		AdoptionStatusMachine.validate(application.getAdoptionStatus(), newStatus);
		application.setAdoptionStatus(newStatus);
		return adoptionApplicationMapper.toResponse(adoptionApplicationRepository.save(application));
	}

	@Transactional
	public AdoptionApplicationDto.Response approve(Long id, User currentUser) {
		AdoptionApplication application = findOrThrow(id);
		ensureNgoOrAdmin(currentUser);
		AdoptionStatusMachine.validate(application.getAdoptionStatus(), AdoptionStatus.APPROVED);
		if (application.getAnimal() != null && adoptionApplicationRepository
				.existsByAnimalIdAndStatus(application.getAnimal().getId(), AdoptionStatus.APPROVED)) {
			throw new BusinessException("This animal already has an approved adoption application");
		}
		application.setAdoptionStatus(AdoptionStatus.APPROVED);
		application.setDecidedBy(currentUser);
		application.setDecidedAt(LocalDateTime.now());
		return adoptionApplicationMapper.toResponse(adoptionApplicationRepository.save(application));
	}

	@Transactional
	public AdoptionApplicationDto.Response reject(Long id, String notes, User currentUser) {
		AdoptionApplication application = findOrThrow(id);
		ensureNgoOrAdmin(currentUser);
		AdoptionStatusMachine.validate(application.getAdoptionStatus(), AdoptionStatus.REJECTED);
		application.setAdoptionStatus(AdoptionStatus.REJECTED);
		application.setNotes(notes);
		application.setDecidedBy(currentUser);
		application.setDecidedAt(LocalDateTime.now());
		return adoptionApplicationMapper.toResponse(adoptionApplicationRepository.save(application));
	}

	@Transactional
	public AdoptionApplicationDto.Response complete(Long id, User currentUser) {
		AdoptionApplication application = findOrThrow(id);
		ensureNgoOrAdmin(currentUser);
		AdoptionStatusMachine.validate(application.getAdoptionStatus(), AdoptionStatus.COMPLETED);
		application.setAdoptionStatus(AdoptionStatus.COMPLETED);
		application.setDecidedBy(currentUser);
		application.setDecidedAt(LocalDateTime.now());
		return adoptionApplicationMapper.toResponse(adoptionApplicationRepository.save(application));
	}

	@Transactional
	public AdoptionApplicationDto.Response withdraw(Long id, User currentUser) {
		AdoptionApplication application = findOrThrow(id);
		if (!application.getApplicant().getId().equals(currentUser.getId())) {
			throw new BusinessException("Only the applicant may withdraw this adoption application");
		}
		AdoptionStatusMachine.validate(application.getAdoptionStatus(), AdoptionStatus.WITHDRAWN);
		application.setAdoptionStatus(AdoptionStatus.WITHDRAWN);
		return adoptionApplicationMapper.toResponse(adoptionApplicationRepository.save(application));
	}

	@Transactional
	public MessageResponseDTO delete(Long id) {
		adoptionApplicationRepository.delete(findOrThrow(id));
		return new MessageResponseDTO("Adoption application deleted successfully");
	}

	@Transactional(readOnly = true)
	public Page<AdoptionApplicationDto.Response> search(String keyword, User currentUser, Pageable pageable) {
		return list(null, null, null, null, keyword, null, null, currentUser, pageable);
	}

	private AdoptionApplication findOrThrow(Long id) {
		return adoptionApplicationRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("Adoption application not found with id " + id));
	}

	private void assertReadable(AdoptionApplication application, User currentUser) {
		if (isAdmin(currentUser) || isNgo(currentUser)) {
			return;
		}
		if (application.getApplicant() == null || !application.getApplicant().getId().equals(currentUser.getId())) {
			throw new BusinessException("You are not authorized to view this adoption application");
		}
	}

	private void assertManageable(AdoptionApplication application, User currentUser) {
		if (isAdmin(currentUser)) {
			return;
		}
		if (application.getApplicant() == null || !application.getApplicant().getId().equals(currentUser.getId())) {
			throw new BusinessException("You are not authorized to manage this adoption application");
		}
	}

	private void ensureNgoOrAdmin(User user) {
		if (!isAdmin(user) && !isNgo(user)) {
			throw new BusinessException("You are not authorized to review adoption applications");
		}
	}

	private boolean isAdmin(User user) {
		return "ADMIN".equals(user.getRole());
	}

	private boolean isNgo(User user) {
		return "NGO".equals(user.getRole());
	}
}
