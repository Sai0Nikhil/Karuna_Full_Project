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

import com.karuna.dto.domain.VeterinarianDto;
import com.karuna.entity.RescueCase;
import com.karuna.entity.User;
import com.karuna.entity.Veterinarian;
import com.karuna.exception.BusinessException;
import com.karuna.exception.ResourceNotFoundException;
import com.karuna.mapper.VeterinarianMapper;
import com.karuna.repository.CaseRepository;
import com.karuna.repository.LocationRepository;
import com.karuna.repository.UserRepository;
import com.karuna.repository.VeterinarianRepository;

@ExtendWith(MockitoExtension.class)
class VeterinarianServiceTest {

	@Mock
	private VeterinarianRepository veterinarianRepository;
	@Mock
	private VeterinarianMapper veterinarianMapper;
	@Mock
	private UserRepository userRepository;
	@Mock
	private LocationRepository locationRepository;
	@Mock
	private CaseRepository caseRepository;

	private VeterinarianService veterinarianService;

	@BeforeEach
	void setUp() {
		veterinarianService = new VeterinarianService(veterinarianRepository, veterinarianMapper, userRepository, locationRepository, caseRepository);
	}

	@Test
	void createRejectsDuplicateLicense() {
		VeterinarianDto.Request request = new VeterinarianDto.Request(20L, "LIC-1", null, "Surgery", null, null, 1L);
		when(veterinarianRepository.existsByLicenseNumber("LIC-1")).thenReturn(true);

		assertThrows(BusinessException.class, () -> veterinarianService.create(request));
		verify(veterinarianRepository, never()).save(any());
	}

	@Test
	void createSavesVeterinarian() {
		VeterinarianDto.Request request = new VeterinarianDto.Request(20L, "LIC-1", null, "Surgery", null, null, 1L);
		Veterinarian entity = new Veterinarian();
		VeterinarianDto.Response response = new VeterinarianDto.Response(1L, 20L, "LIC-1", null, "Surgery", null, null, 1L, true, null, null, 0L);

		when(veterinarianRepository.existsByLicenseNumber("LIC-1")).thenReturn(false);
		when(userRepository.findById(20L)).thenReturn(Optional.of(new User()));
		when(veterinarianMapper.toEntity(request)).thenReturn(entity);
		when(locationRepository.findById(1L)).thenReturn(Optional.of(new com.karuna.entity.Location()));
		when(veterinarianRepository.save(entity)).thenReturn(entity);
		when(veterinarianMapper.toResponse(entity)).thenReturn(response);

		assertEquals(1L, veterinarianService.create(request).id());
	}

	@Test
	void assignCaseValidatesCaseExists() {
		Veterinarian veterinarian = new Veterinarian();
		VeterinarianDto.Response response = new VeterinarianDto.Response(1L, 20L, "LIC-1", null, "Surgery", null, null, 1L, true, null, null, 0L);

		when(veterinarianRepository.findById(1L)).thenReturn(Optional.of(veterinarian));
		when(caseRepository.findById(5L)).thenReturn(Optional.of(new RescueCase()));
		when(veterinarianMapper.toResponse(veterinarian)).thenReturn(response);

		veterinarianService.assignCase(1L, 5L);

		verify(caseRepository).findById(5L);
	}

	@Test
	void getThrowsWhenMissing() {
		when(veterinarianRepository.findById(4L)).thenReturn(Optional.empty());
		assertThrows(ResourceNotFoundException.class, () -> veterinarianService.get(4L));
	}

	@Test
	void listUsesSpecification() {
		Page<Veterinarian> page = new PageImpl<>(List.of(new Veterinarian()));
		when(veterinarianRepository.findAll(any(Specification.class), any(Pageable.class))).thenReturn(page);
		when(veterinarianMapper.toResponse(any(Veterinarian.class)))
				.thenReturn(new VeterinarianDto.Response(1L, 20L, "LIC-1", null, "Surgery", null, null, 1L, true, null, null, 0L));

		Page<VeterinarianDto.Response> result = veterinarianService.list("Surgery", null, null, Pageable.ofSize(10));

		assertEquals(1, result.getTotalElements());
	}
}
