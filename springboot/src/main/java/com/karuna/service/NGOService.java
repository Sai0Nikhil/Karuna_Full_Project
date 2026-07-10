package com.karuna.service;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.karuna.dto.domain.NgoDto;
import com.karuna.dto.MessageResponseDTO;
import com.karuna.entity.Location;
import com.karuna.entity.NGO;
import com.karuna.entity.RescueCase;
import com.karuna.entity.Volunteer;
import com.karuna.entity.Veterinarian;
import com.karuna.exception.BusinessException;
import com.karuna.exception.ResourceNotFoundException;
import com.karuna.mapper.NgoMapper;
import com.karuna.repository.CaseRepository;
import com.karuna.repository.LocationRepository;
import com.karuna.repository.NGORepository;
import com.karuna.repository.VeterinarianRepository;
import com.karuna.repository.VolunteerRepository;
import com.karuna.repository.specification.NgoSpecification;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class NGOService {

	private final NGORepository ngoRepository;
	private final NgoMapper ngoMapper;
	private final LocationRepository locationRepository;
	private final CaseRepository caseRepository;
	private final VolunteerRepository volunteerRepository;
	private final VeterinarianRepository veterinarianRepository;

	@Transactional
	public NgoDto.Response create(NgoDto.Request request) {
		if (ngoRepository.existsByRegistrationNumber(request.registrationNumber())) {
			throw new BusinessException("An NGO with this registration number already exists");
		}
		NGO entity = ngoMapper.toEntity(request);
		if (request.headquartersLocationId() != null) {
			entity.setHeadquartersLocation(resolveLocation(request.headquartersLocationId()));
		}
		return ngoMapper.toResponse(ngoRepository.save(entity));
	}

	@Transactional(readOnly = true)
	public NgoDto.Response get(Long id) {
		return ngoMapper.toResponse(findOrThrow(id));
	}

	@Transactional(readOnly = true)
	public Page<NgoDto.Response> list(
			String keyword, Long locationId, Boolean active, Boolean verified, Pageable pageable) {
		var specification = NgoSpecification.withFilters(keyword, locationId, active, verified);
		return ngoRepository.findAll(specification, pageable).map(ngoMapper::toResponse);
	}

	@Transactional
	public NgoDto.Response update(Long id, NgoDto.Update request) {
		NGO entity = findOrThrow(id);
		ngoMapper.updateEntity(request, entity);
		if (request.headquartersLocationId() != null) {
			entity.setHeadquartersLocation(resolveLocation(request.headquartersLocationId()));
		}
		if (request.active() != null) {
			entity.setActive(request.active());
		}
		if (request.verified() != null) {
			entity.setVerified(request.verified());
		}
		return ngoMapper.toResponse(ngoRepository.save(entity));
	}

	@Transactional
	public MessageResponseDTO delete(Long id) {
		ngoRepository.delete(findOrThrow(id));
		return new MessageResponseDTO("NGO deleted successfully");
	}

	@Transactional
	public NgoDto.Response assignCase(Long id, Long caseId) {
		NGO ngo = findOrThrow(id);
		RescueCase rescueCase = caseRepository.findById(caseId)
				.orElseThrow(() -> new ResourceNotFoundException("Rescue case not found with id " + caseId));
		rescueCase.setNgo(ngo);
		caseRepository.save(rescueCase);
		return ngoMapper.toResponse(ngo);
	}

	@Transactional
	public NgoDto.Response assignVolunteer(Long id, Long volunteerId) {
		NGO ngo = findOrThrow(id);
		Volunteer volunteer = volunteerRepository.findById(volunteerId)
				.orElseThrow(() -> new ResourceNotFoundException("Volunteer not found with id " + volunteerId));
		ngo.getVolunteers().add(volunteer);
		volunteer.getNgos().add(ngo);
		volunteerRepository.save(volunteer);
		return ngoMapper.toResponse(ngoRepository.save(ngo));
	}

	@Transactional
	public NgoDto.Response assignVeterinarian(Long id, Long vetId) {
		NGO ngo = findOrThrow(id);
		veterinarianRepository.findById(vetId)
				.orElseThrow(() -> new ResourceNotFoundException("Veterinarian not found with id " + vetId));
		return ngoMapper.toResponse(ngo);
	}

	private NGO findOrThrow(Long id) {
		return ngoRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("NGO not found with id " + id));
	}

	private Location resolveLocation(Long id) {
		return locationRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("Location not found with id " + id));
	}
}
