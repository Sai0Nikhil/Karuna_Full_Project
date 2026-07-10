package com.karuna.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;

import com.karuna.dto.AdoptionStatusChangeDTO;
import com.karuna.dto.MessageResponseDTO;
import com.karuna.dto.domain.AdoptionApplicationDto;
import com.karuna.entity.AdoptionApplication;
import com.karuna.entity.Animal;
import com.karuna.entity.RescueCase;
import com.karuna.entity.User;
import com.karuna.entity.enums.AdoptionStatus;
import com.karuna.entity.enums.UserRole;
import com.karuna.exception.BusinessException;
import com.karuna.exception.ResourceNotFoundException;
import com.karuna.mapper.AdoptionApplicationMapper;
import com.karuna.repository.AdoptionApplicationRepository;
import com.karuna.repository.AnimalRepository;
import com.karuna.repository.CaseRepository;
import com.karuna.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class AdoptionServiceTest {

	@Mock
	private AdoptionApplicationRepository adoptionApplicationRepository;
	@Mock
	private AdoptionApplicationMapper adoptionApplicationMapper;
	@Mock
	private UserRepository userRepository;
	@Mock
	private AnimalRepository animalRepository;
	@Mock
	private CaseRepository caseRepository;

	private AdoptionService adoptionService;

	private User applicant;
	private Animal animal;
	private RescueCase rescueCase;
	private AdoptionApplication application;

	@BeforeEach
	void setUp() {
		adoptionService = new AdoptionService(adoptionApplicationRepository, adoptionApplicationMapper, userRepository,
				animalRepository, caseRepository);

		applicant = new User();
		applicant.setId(1L);
		applicant.setPrimaryRole(UserRole.CITIZEN);

		animal = new Animal();
		animal.setId(2L);

		rescueCase = new RescueCase();
		rescueCase.setId(3L);

		application = new AdoptionApplication();
		application.setId(10L);
		application.setApplicant(applicant);
		application.setAnimal(animal);
		application.setRescueCase(rescueCase);
		application.setAdoptionStatus(AdoptionStatus.SUBMITTED);
	}

	@Test
	void createRejectsDuplicateActiveApplication() {
		AdoptionApplicationDto.Request request = new AdoptionApplicationDto.Request(3L, 2L, 1L, "John", "john@test.com",
				"+919999999999", "Reason", null);
		when(caseRepository.findById(3L)).thenReturn(Optional.of(rescueCase));
		when(animalRepository.findById(2L)).thenReturn(Optional.of(animal));
		when(adoptionApplicationRepository
				.findByApplicantIdAndAnimalIdAndStatusIn(1L, 2L,
						List.of(AdoptionStatus.SUBMITTED, AdoptionStatus.UNDER_REVIEW, AdoptionStatus.APPROVED)))
				.thenReturn(List.of(new AdoptionApplication()));

		assertThrows(BusinessException.class, () -> adoptionService.create(request, applicant));
		verify(adoptionApplicationRepository, never()).save(any());
	}

	@Test
	void createRejectsApprovedApplicationForSameAnimal() {
		AdoptionApplicationDto.Request request = new AdoptionApplicationDto.Request(3L, 2L, 1L, "John", "john@test.com",
				"+919999999999", "Reason", null);
		when(caseRepository.findById(3L)).thenReturn(Optional.of(rescueCase));
		when(animalRepository.findById(2L)).thenReturn(Optional.of(animal));
		when(adoptionApplicationRepository
				.findByApplicantIdAndAnimalIdAndStatusIn(1L, 2L,
						List.of(AdoptionStatus.SUBMITTED, AdoptionStatus.UNDER_REVIEW, AdoptionStatus.APPROVED)))
				.thenReturn(Collections.emptyList());
		when(adoptionApplicationRepository.existsByAnimalIdAndStatus(2L, AdoptionStatus.APPROVED)).thenReturn(true);

		assertThrows(BusinessException.class, () -> adoptionService.create(request, applicant));
		verify(adoptionApplicationRepository, never()).save(any());
	}

	@Test
	void createSetsSubmittedAndSaves() {
		AdoptionApplicationDto.Request request = new AdoptionApplicationDto.Request(3L, 2L, 1L, "John", "john@test.com",
				"+919999999999", "Reason", null);
		AdoptionApplication entity = new AdoptionApplication();
		AdoptionApplicationDto.Response response = new AdoptionApplicationDto.Response(10L, 3L, 2L, 1L, "John",
				"john@test.com", "+919999999999", "Reason", null, AdoptionStatus.SUBMITTED, null, null,
				LocalDateTime.now(), LocalDateTime.now(), LocalDateTime.now(), 0L);

		when(caseRepository.findById(3L)).thenReturn(Optional.of(rescueCase));
		when(animalRepository.findById(2L)).thenReturn(Optional.of(animal));
		when(adoptionApplicationRepository
				.findByApplicantIdAndAnimalIdAndStatusIn(1L, 2L,
						List.of(AdoptionStatus.SUBMITTED, AdoptionStatus.UNDER_REVIEW, AdoptionStatus.APPROVED)))
				.thenReturn(Collections.emptyList());
		when(adoptionApplicationRepository.existsByAnimalIdAndStatus(2L, AdoptionStatus.APPROVED)).thenReturn(false);
		when(adoptionApplicationMapper.toEntity(request)).thenReturn(entity);
		when(adoptionApplicationRepository.save(entity)).thenReturn(entity);
		when(adoptionApplicationMapper.toResponse(entity)).thenReturn(response);

		AdoptionApplicationDto.Response result = adoptionService.create(request, applicant);

		assertEquals(AdoptionStatus.SUBMITTED, entity.getAdoptionStatus());
		assertEquals(applicant, entity.getApplicant());
		verify(adoptionApplicationRepository).save(entity);
	}

	@Test
	void getThrowsWhenMissing() {
		when(adoptionApplicationRepository.findById(7L)).thenReturn(Optional.empty());
		assertThrows(ResourceNotFoundException.class, () -> adoptionService.get(7L, applicant));
	}

	@Test
	void listUsesSpecification() {
		Page<AdoptionApplication> page = new PageImpl<>(List.of(application));
		when(adoptionApplicationRepository.findAll(any(org.springframework.data.jpa.domain.Specification.class), any(Pageable.class)))
				.thenReturn(page);
		when(adoptionApplicationMapper.toResponse(any(AdoptionApplication.class)))
				.thenReturn(new AdoptionApplicationDto.Response(10L, 3L, 2L, 1L, "John", "john@test.com", "+919999999999",
						"Reason", null, AdoptionStatus.SUBMITTED, null, null,
						LocalDateTime.now(), LocalDateTime.now(), LocalDateTime.now(), 0L));

		Page<AdoptionApplicationDto.Response> result = adoptionService.list(null, null, null, null, null, null, null,
				applicant, Pageable.ofSize(10));

		assertEquals(1, result.getTotalElements());
	}

	@Test
	void updateThrowsWhenNotSubmitted() {
		application.setAdoptionStatus(AdoptionStatus.UNDER_REVIEW);
		when(adoptionApplicationRepository.findById(10L)).thenReturn(Optional.of(application));

		assertThrows(BusinessException.class,
				() -> adoptionService.update(10L, new AdoptionApplicationDto.Update(null, null, null), applicant));
	}

	@Test
	void approveValidatesTransition() {
		application.setAdoptionStatus(AdoptionStatus.SUBMITTED);
		when(adoptionApplicationRepository.findById(10L)).thenReturn(Optional.of(application));

		assertThrows(BusinessException.class, () -> adoptionService.approve(10L, applicant));
	}

	@Test
	void approveSucceedsForUnderReview() {
		User ngoUser = new User();
		ngoUser.setId(50L);
		ngoUser.setPrimaryRole(UserRole.NGO);

		application.setAdoptionStatus(AdoptionStatus.UNDER_REVIEW);
		when(adoptionApplicationRepository.findById(10L)).thenReturn(Optional.of(application));
		when(adoptionApplicationRepository.existsByAnimalIdAndStatus(2L, AdoptionStatus.APPROVED)).thenReturn(false);
		when(adoptionApplicationRepository.save(application)).thenReturn(application);
		when(adoptionApplicationMapper.toResponse(application))
				.thenReturn(new AdoptionApplicationDto.Response(10L, 3L, 2L, 1L, "John", "john@test.com", "+919999999999",
						"Reason", null, AdoptionStatus.APPROVED, null, ngoUser.getId(), LocalDateTime.now(),
						LocalDateTime.now(), LocalDateTime.now(), 0L));

		AdoptionApplicationDto.Response result = adoptionService.approve(10L, ngoUser);

		assertEquals(AdoptionStatus.APPROVED, application.getAdoptionStatus());
		assertEquals(ngoUser, application.getDecidedBy());
	}

	@Test
	void rejectThrowsWhenNotUnderReview() {
		application.setAdoptionStatus(AdoptionStatus.SUBMITTED);
		when(adoptionApplicationRepository.findById(10L)).thenReturn(Optional.of(application));

		assertThrows(BusinessException.class, () -> adoptionService.reject(10L, "No", applicant));
	}

	@Test
	void withdrawThrowsForNonApplicant() {
		User otherUser = new User();
		otherUser.setId(99L);
		otherUser.setPrimaryRole(UserRole.CITIZEN);

		assertThrows(BusinessException.class, () -> adoptionService.withdraw(10L, otherUser));
	}

	@Test
	void withdrawSucceedsForSubmitted() {
		when(adoptionApplicationRepository.findById(10L)).thenReturn(Optional.of(application));
		when(adoptionApplicationRepository.save(application)).thenReturn(application);
		when(adoptionApplicationMapper.toResponse(application))
		.thenReturn(new AdoptionApplicationDto.Response(10L, 3L, 2L, 1L, "John", "john@test.com", "+919999999999",
				"Reason", null, AdoptionStatus.WITHDRAWN, null, null,
				LocalDateTime.now(), LocalDateTime.now(), LocalDateTime.now(), 0L));

		AdoptionApplicationDto.Response result = adoptionService.withdraw(10L, applicant);

		assertEquals(AdoptionStatus.WITHDRAWN, application.getAdoptionStatus());
	}

	@Test
	void deleteRemovesApplication() {
		when(adoptionApplicationRepository.findById(10L)).thenReturn(Optional.of(application));

		MessageResponseDTO result = adoptionService.delete(10L);

		assertEquals("Adoption application deleted successfully", result.getMessage());
		verify(adoptionApplicationRepository).delete(application);
	}

	@Test
	void assertReadableThrowsForNonOwnerCitizen() {
		User otherUser = new User();
		otherUser.setId(99L);
		otherUser.setPrimaryRole(UserRole.CITIZEN);

		assertThrows(BusinessException.class, () -> adoptionService.get(10L, otherUser));
	}

	@Test
	void assertManageableThrowsForNonOwnerNonAdmin() {
		User otherUser = new User();
		otherUser.setId(99L);
		otherUser.setPrimaryRole(UserRole.CITIZEN);

		assertThrows(BusinessException.class,
				() -> adoptionService.update(10L, new AdoptionApplicationDto.Update(null, null, null), otherUser));
	}
}
