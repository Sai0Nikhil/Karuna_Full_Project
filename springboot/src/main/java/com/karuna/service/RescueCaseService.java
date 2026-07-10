package com.karuna.service;

import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.karuna.dto.CaseAssignmentDTO;
import com.karuna.dto.CaseStatusChangeDTO;
import com.karuna.dto.MessageResponseDTO;
import com.karuna.dto.domain.RescueCaseDto;
import com.karuna.entity.Animal;
import com.karuna.entity.Location;
import com.karuna.entity.NGO;
import com.karuna.entity.RescueCase;
import com.karuna.entity.User;
import com.karuna.entity.Volunteer;
import com.karuna.entity.enums.CaseStatus;
import com.karuna.entity.enums.PriorityLevel;
import com.karuna.exception.ResourceNotFoundException;
import com.karuna.mapper.RescueCaseMapper;
import com.karuna.repository.AnimalRepository;
import com.karuna.repository.CaseRepository;
import com.karuna.repository.LocationRepository;
import com.karuna.repository.NGORepository;
import com.karuna.repository.VolunteerRepository;
import com.karuna.repository.specification.RescueCaseSpecification;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class RescueCaseService {

	private final CaseRepository caseRepository;
	private final RescueCaseMapper rescueCaseMapper;
	private final AnimalRepository animalRepository;
	private final NGORepository ngoRepository;
	private final VolunteerRepository volunteerRepository;
	private final LocationRepository locationRepository;

	@Transactional
	public RescueCaseDto.Response create(RescueCaseDto.Request request, User reporter) {
		RescueCase entity = rescueCaseMapper.toEntity(request);
		entity.setReporter(reporter);
		applyAssociations(entity, request.animalId(), request.ngoId(), request.primaryVolunteerId(), request.locationId());
		if (entity.getCaseStatus() == null) {
			entity.setCaseStatus(CaseStatus.REPORTED);
		}
		return rescueCaseMapper.toResponse(caseRepository.save(entity));
	}

	@Transactional(readOnly = true)
	public RescueCaseDto.Response get(Long id) {
		return rescueCaseMapper.toResponse(findOrThrow(id));
	}

	@Transactional(readOnly = true)
	public Page<RescueCaseDto.Response> list(
			CaseStatus status,
			PriorityLevel priority,
			Long reporterId,
			Long ngoId,
			Long volunteerId,
			String search,
			Pageable pageable) {
		var specification = RescueCaseSpecification.withFilters(status, priority, reporterId, ngoId, volunteerId, search);
		return caseRepository.findAll(specification, pageable).map(rescueCaseMapper::toResponse);
	}

	@Transactional
	public RescueCaseDto.Response update(Long id, RescueCaseDto.Update request) {
		RescueCase entity = findOrThrow(id);
		rescueCaseMapper.updateEntity(request, entity);
		if (request.ngoId() != null) {
			entity.setNgo(resolveNgo(request.ngoId()));
		}
		if (request.primaryVolunteerId() != null) {
			entity.setPrimaryVolunteer(resolveVolunteer(request.primaryVolunteerId()));
		}
		if (request.locationId() != null) {
			entity.setGeoLocation(resolveLocation(request.locationId()));
		}
		if (request.active() != null) {
			entity.setActive(request.active());
		}
		return rescueCaseMapper.toResponse(caseRepository.save(entity));
	}

	@Transactional
	public MessageResponseDTO delete(Long id) {
		caseRepository.delete(findOrThrow(id));
		return new MessageResponseDTO("Rescue case deleted successfully");
	}

	@Transactional
	public RescueCaseDto.Response assign(Long id, CaseAssignmentDTO request) {
		RescueCase entity = findOrThrow(id);
		if (request.getNgoId() != null) {
			entity.setNgo(resolveNgo(request.getNgoId()));
		}
		if (request.getPrimaryVolunteerId() != null) {
			Volunteer volunteer = resolveVolunteer(request.getPrimaryVolunteerId());
			entity.setPrimaryVolunteer(volunteer);
			entity.getAssignedVolunteers().add(volunteer);
		}
		return rescueCaseMapper.toResponse(caseRepository.save(entity));
	}

	@Transactional
	public RescueCaseDto.Response changeStatus(Long id, CaseStatusChangeDTO request) {
		RescueCase entity = findOrThrow(id);
		RescueCaseStatusMachine.validate(entity.getCaseStatus(), request.getStatus());
		entity.setCaseStatus(request.getStatus());
		return rescueCaseMapper.toResponse(caseRepository.save(entity));
	}

	private RescueCase findOrThrow(Long id) {
		return caseRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("Rescue case not found with id " + id));
	}

	private void applyAssociations(RescueCase entity, Long animalId, Long ngoId, Long volunteerId, Long locationId) {
		if (animalId != null) {
			entity.setAnimal(resolveAnimal(animalId));
		}
		if (ngoId != null) {
			entity.setNgo(resolveNgo(ngoId));
		}
		if (volunteerId != null) {
			entity.setPrimaryVolunteer(resolveVolunteer(volunteerId));
		}
		if (locationId != null) {
			entity.setGeoLocation(resolveLocation(locationId));
		}
	}

	private Animal resolveAnimal(Long id) {
		return animalRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("Animal not found with id " + id));
	}

	private NGO resolveNgo(Long id) {
		return ngoRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("NGO not found with id " + id));
	}

	private Volunteer resolveVolunteer(Long id) {
		return volunteerRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("Volunteer not found with id " + id));
	}

	private Location resolveLocation(Long id) {
		return locationRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("Location not found with id " + id));
	}
}
