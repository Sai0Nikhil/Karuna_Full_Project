package com.karuna.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

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
import org.springframework.data.jpa.domain.Specification;

import com.karuna.dto.domain.NgoDto;
import com.karuna.entity.NGO;
import com.karuna.entity.RescueCase;
import com.karuna.entity.Volunteer;
import com.karuna.exception.BusinessException;
import com.karuna.exception.ResourceNotFoundException;
import com.karuna.mapper.NgoMapper;
import com.karuna.repository.CaseRepository;
import com.karuna.repository.LocationRepository;
import com.karuna.repository.NGORepository;
import com.karuna.repository.VeterinarianRepository;
import com.karuna.repository.VolunteerRepository;

@ExtendWith(MockitoExtension.class)
class NGOServiceTest {

	@Mock
	private NGORepository ngoRepository;
	@Mock
	private NgoMapper ngoMapper;
	@Mock
	private LocationRepository locationRepository;
	@Mock
	private CaseRepository caseRepository;
	@Mock
	private VolunteerRepository volunteerRepository;
	@Mock
	private VeterinarianRepository veterinarianRepository;

	private NGOService ngoService;

	@BeforeEach
	void setUp() {
		ngoService = new NGOService(ngoRepository, ngoMapper, locationRepository, caseRepository, volunteerRepository, veterinarianRepository);
	}

	@Test
	void createRejectsDuplicateRegistration() {
		NgoDto.Request request = new NgoDto.Request("Helping Paws", "REG-1", "x@y.org", null, null, 1L);
		when(ngoRepository.existsByRegistrationNumber("REG-1")).thenReturn(true);

		assertThrows(BusinessException.class, () -> ngoService.create(request));
		verify(ngoRepository, never()).save(any());
	}

	@Test
	void createSavesNgo() {
		NgoDto.Request request = new NgoDto.Request("Helping Paws", "REG-1", "x@y.org", null, null, 1L);
		NGO entity = new NGO();
		NgoDto.Response response = new NgoDto.Response(1L, "Helping Paws", "REG-1", "x@y.org", null, null, 1L, false, true, null, null, 0L);

		when(ngoRepository.existsByRegistrationNumber("REG-1")).thenReturn(false);
		when(ngoMapper.toEntity(request)).thenReturn(entity);
		when(locationRepository.findById(1L)).thenReturn(Optional.of(new com.karuna.entity.Location()));
		when(ngoRepository.save(entity)).thenReturn(entity);
		when(ngoMapper.toResponse(entity)).thenReturn(response);

		assertEquals(1L, ngoService.create(request).id());
	}

	@Test
	void getThrowsWhenMissing() {
		when(ngoRepository.findById(7L)).thenReturn(Optional.empty());
		assertThrows(ResourceNotFoundException.class, () -> ngoService.get(7L));
	}

	@Test
	void assignVolunteerLinksBidirectional() {
		NGO ngo = new NGO();
		Volunteer volunteer = new Volunteer();
		NgoDto.Response response = new NgoDto.Response(1L, "NGO", "REG", null, null, null, null, false, true, null, null, 0L);

		when(ngoRepository.findById(1L)).thenReturn(Optional.of(ngo));
		when(volunteerRepository.findById(3L)).thenReturn(Optional.of(volunteer));
		when(volunteerRepository.save(volunteer)).thenReturn(volunteer);
		when(ngoRepository.save(ngo)).thenReturn(ngo);
		when(ngoMapper.toResponse(ngo)).thenReturn(response);

		ngoService.assignVolunteer(1L, 3L);

		verify(volunteerRepository).save(volunteer);
	}

	@Test
	void assignCaseSetsNgoOnCase() {
		NGO ngo = new NGO();
		RescueCase rescueCase = new RescueCase();
		NgoDto.Response response = new NgoDto.Response(1L, "NGO", "REG", null, null, null, null, false, true, null, null, 0L);

		when(ngoRepository.findById(1L)).thenReturn(Optional.of(ngo));
		when(caseRepository.findById(5L)).thenReturn(Optional.of(rescueCase));
		when(caseRepository.save(rescueCase)).thenReturn(rescueCase);
		when(ngoMapper.toResponse(ngo)).thenReturn(response);

		ngoService.assignCase(1L, 5L);

		assertEquals(ngo, rescueCase.getNgo());
	}

	@Test
	void listUsesSpecification() {
		Page<NGO> page = new PageImpl<>(List.of(new NGO()));
		when(ngoRepository.findAll(any(Specification.class), any(Pageable.class))).thenReturn(page);
		when(ngoMapper.toResponse(any(NGO.class)))
				.thenReturn(new NgoDto.Response(1L, "NGO", "REG", null, null, null, null, false, true, null, null, 0L));

		Page<NgoDto.Response> result = ngoService.list("Helping", null, null, null, Pageable.ofSize(10));

		assertEquals(1, result.getTotalElements());
	}
}
