package com.karuna.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
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

import com.karuna.config.KarunaProperties;
import com.karuna.dto.VolunteerAvailabilityDTO;
import com.karuna.dto.domain.VolunteerDto;
import com.karuna.entity.RescueCase;
import com.karuna.entity.enums.CaseStatus;
import com.karuna.entity.User;
import com.karuna.entity.Volunteer;
import com.karuna.entity.enums.VolunteerStatus;
import com.karuna.exception.BusinessException;
import com.karuna.exception.ResourceNotFoundException;
import com.karuna.mapper.VolunteerMapper;
import com.karuna.repository.CaseRepository;
import com.karuna.repository.LocationRepository;
import com.karuna.repository.UserRepository;
import com.karuna.repository.VolunteerRepository;

@ExtendWith(MockitoExtension.class)
class VolunteerServiceTest {

	@Mock
	private VolunteerRepository volunteerRepository;
	@Mock
	private VolunteerMapper volunteerMapper;
	@Mock
	private UserRepository userRepository;
	@Mock
	private LocationRepository locationRepository;
	@Mock
	private CaseRepository caseRepository;
	@Mock
	private KarunaProperties karunaProperties;

	private VolunteerService volunteerService;

	private static final java.util.List<CaseStatus> TERMINAL =
			java.util.List.of(CaseStatus.ADOPTED, CaseStatus.RELEASED, CaseStatus.CANCELLED);

	@BeforeEach
	void setUp() {
		volunteerService = new VolunteerService(volunteerRepository, volunteerMapper, userRepository, locationRepository, caseRepository, karunaProperties);
	}

	@Test
	void createDefaultsToAvailable() {
		VolunteerDto.Request request = new VolunteerDto.Request(10L, "+919999999999", null, "Rescue", 1L);
		Volunteer entity = new Volunteer();
		VolunteerDto.Response response = new VolunteerDto.Response(1L, 10L, "+919999999999", VolunteerStatus.AVAILABLE, "Rescue", 1L, true, null, null, 0L);

		when(volunteerRepository.existsByUserId(10L)).thenReturn(false);
		when(userRepository.findById(10L)).thenReturn(Optional.of(new User()));
		when(volunteerMapper.toEntity(request)).thenReturn(entity);
		when(locationRepository.findById(1L)).thenReturn(Optional.of(new com.karuna.entity.Location()));
		when(volunteerRepository.save(entity)).thenReturn(entity);
		when(volunteerMapper.toResponse(entity)).thenReturn(response);

		assertEquals(VolunteerStatus.AVAILABLE, volunteerService.create(request).status());
	}

	@Test
	void assignCaseRejectsWhenUnavailable() {
		Volunteer volunteer = new Volunteer();
		volunteer.setId(1L);
		volunteer.setStatus(VolunteerStatus.BUSY);
		when(volunteerRepository.findById(1L)).thenReturn(Optional.of(volunteer));

		assertThrows(BusinessException.class, () -> volunteerService.assignCase(1L, 5L));
		verify(caseRepository, never()).save(any());
	}

	@Test
	void assignCaseRejectsAtCapacity() {
		Volunteer volunteer = new Volunteer();
		volunteer.setId(1L);
		volunteer.setStatus(VolunteerStatus.AVAILABLE);
		when(volunteerRepository.findById(1L)).thenReturn(Optional.of(volunteer));
		when(karunaProperties.getAssignment()).thenReturn(new com.karuna.config.KarunaProperties.Assignment());
		when(caseRepository.countByPrimaryVolunteerIdAndStatusNotIn(eq(1L), eq(TERMINAL)))
				.thenReturn(5L);

		assertThrows(BusinessException.class, () -> volunteerService.assignCase(1L, 5L));
	}

	@Test
	void assignCaseSucceedsWhenAvailableAndUnderCapacity() {
		Volunteer volunteer = new Volunteer();
		volunteer.setId(1L);
		volunteer.setStatus(VolunteerStatus.AVAILABLE);
		RescueCase rescueCase = new RescueCase();
		VolunteerDto.Response response = new VolunteerDto.Response(1L, 10L, null, VolunteerStatus.AVAILABLE, null, null, true, null, null, 0L);

		when(volunteerRepository.findById(1L)).thenReturn(Optional.of(volunteer));
		when(karunaProperties.getAssignment()).thenReturn(new com.karuna.config.KarunaProperties.Assignment());
		when(caseRepository.countByPrimaryVolunteerIdAndStatusNotIn(eq(1L), eq(TERMINAL))).thenReturn(1L);
		when(caseRepository.findById(5L)).thenReturn(Optional.of(rescueCase));
		when(caseRepository.save(rescueCase)).thenReturn(rescueCase);
		when(volunteerMapper.toResponse(volunteer)).thenReturn(response);

		volunteerService.assignCase(1L, 5L);

		assertEquals(volunteer, rescueCase.getPrimaryVolunteer());
		verify(caseRepository).save(rescueCase);
	}

	@Test
	void setAvailabilityUpdatesStatus() {
		Volunteer volunteer = new Volunteer();
		VolunteerDto.Response response = new VolunteerDto.Response(1L, 10L, null, VolunteerStatus.OFFLINE, null, null, true, null, null, 0L);
		when(volunteerRepository.findById(1L)).thenReturn(Optional.of(volunteer));
		when(volunteerRepository.save(volunteer)).thenReturn(volunteer);
		when(volunteerMapper.toResponse(volunteer)).thenReturn(response);

		volunteerService.setAvailability(1L, new VolunteerAvailabilityDTO() {{
			setStatus(VolunteerStatus.OFFLINE);
		}});

		assertEquals(VolunteerStatus.OFFLINE, volunteer.getStatus());
	}

	@Test
	void getThrowsWhenMissing() {
		when(volunteerRepository.findById(9L)).thenReturn(Optional.empty());
		assertThrows(ResourceNotFoundException.class, () -> volunteerService.get(9L));
	}
}
