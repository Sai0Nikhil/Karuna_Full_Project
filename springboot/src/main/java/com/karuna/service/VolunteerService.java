package com.karuna.service;

import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.karuna.config.KarunaProperties;
import com.karuna.dto.VolunteerAvailabilityDTO;
import com.karuna.dto.domain.VolunteerDto;
import com.karuna.dto.MessageResponseDTO;
import com.karuna.entity.Location;
import com.karuna.entity.RescueCase;
import com.karuna.entity.User;
import com.karuna.entity.Volunteer;
import com.karuna.entity.enums.CaseStatus;
import com.karuna.entity.enums.VolunteerStatus;
import com.karuna.exception.BusinessException;
import com.karuna.exception.ResourceNotFoundException;
import com.karuna.mapper.VolunteerMapper;
import com.karuna.repository.CaseRepository;
import com.karuna.repository.LocationRepository;
import com.karuna.repository.UserRepository;
import com.karuna.repository.VolunteerRepository;
import com.karuna.repository.specification.VolunteerSpecification;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class VolunteerService {

	private static final List<CaseStatus> TERMINAL_STATUSES = List.of(
			CaseStatus.ADOPTED, CaseStatus.RELEASED, CaseStatus.CANCELLED);

	private final VolunteerRepository volunteerRepository;
	private final VolunteerMapper volunteerMapper;
	private final UserRepository userRepository;
	private final LocationRepository locationRepository;
	private final CaseRepository caseRepository;
	private final KarunaProperties karunaProperties;

	@Transactional
	public VolunteerDto.Response create(VolunteerDto.Request request) {
		if (volunteerRepository.existsByUserId(request.userId())) {
			throw new BusinessException("A volunteer profile already exists for this user");
		}
		User user = userRepository.findById(request.userId())
				.orElseThrow(() -> new ResourceNotFoundException("User not found with id " + request.userId()));
		Volunteer entity = volunteerMapper.toEntity(request);
		entity.setUser(user);
		if (request.serviceLocationId() != null) {
			entity.setServiceLocation(resolveLocation(request.serviceLocationId()));
		}
		if (entity.getStatus() == null) {
			entity.setStatus(VolunteerStatus.AVAILABLE);
		}
		return volunteerMapper.toResponse(volunteerRepository.save(entity));
	}

	@Transactional(readOnly = true)
	public VolunteerDto.Response get(Long id) {
		return volunteerMapper.toResponse(findOrThrow(id));
	}

	@Transactional(readOnly = true)
	public Page<VolunteerDto.Response> list(
			VolunteerStatus status, Long locationId, Long ngoId, String keyword, Pageable pageable) {
		var specification = VolunteerSpecification.withFilters(status, locationId, ngoId, keyword);
		return volunteerRepository.findAll(specification, pageable).map(volunteerMapper::toResponse);
	}

	@Transactional
	public VolunteerDto.Response update(Long id, VolunteerDto.Update request) {
		Volunteer entity = findOrThrow(id);
		volunteerMapper.updateEntity(request, entity);
		if (request.serviceLocationId() != null) {
			entity.setServiceLocation(resolveLocation(request.serviceLocationId()));
		}
		if (request.active() != null) {
			entity.setActive(request.active());
		}
		return volunteerMapper.toResponse(volunteerRepository.save(entity));
	}

	@Transactional
	public MessageResponseDTO delete(Long id) {
		volunteerRepository.delete(findOrThrow(id));
		return new MessageResponseDTO("Volunteer deleted successfully");
	}

	@Transactional
	public VolunteerDto.Response setAvailability(Long id, VolunteerAvailabilityDTO request) {
		Volunteer entity = findOrThrow(id);
		entity.setStatus(request.getStatus());
		return volunteerMapper.toResponse(volunteerRepository.save(entity));
	}

	@Transactional
	public VolunteerDto.Response assignCase(Long id, Long caseId) {
		Volunteer volunteer = findOrThrow(id);
		if (volunteer.getStatus() != VolunteerStatus.AVAILABLE) {
			throw new BusinessException("Volunteer is not available for assignment");
		}
		long activeCases = caseRepository.countByPrimaryVolunteerIdAndStatusNotIn(volunteer.getId(), TERMINAL_STATUSES);
		if (activeCases >= karunaProperties.getAssignment().getMaxActiveCases()) {
			throw new BusinessException("Volunteer has reached the maximum number of active cases");
		}
		RescueCase rescueCase = caseRepository.findById(caseId)
				.orElseThrow(() -> new ResourceNotFoundException("Rescue case not found with id " + caseId));
		rescueCase.setPrimaryVolunteer(volunteer);
		rescueCase.getAssignedVolunteers().add(volunteer);
		caseRepository.save(rescueCase);
		return volunteerMapper.toResponse(volunteer);
	}

	private Volunteer findOrThrow(Long id) {
		return volunteerRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("Volunteer not found with id " + id));
	}

	private Location resolveLocation(Long id) {
		return locationRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("Location not found with id " + id));
	}
}
