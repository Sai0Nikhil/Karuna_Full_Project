package com.karuna.service;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.karuna.dto.domain.VeterinarianDto;
import com.karuna.dto.MessageResponseDTO;
import com.karuna.entity.Location;
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
import com.karuna.repository.specification.VeterinarianSpecification;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class VeterinarianService {

	private final VeterinarianRepository veterinarianRepository;
	private final VeterinarianMapper veterinarianMapper;
	private final UserRepository userRepository;
	private final LocationRepository locationRepository;
	private final CaseRepository caseRepository;

	@Transactional
	public VeterinarianDto.Response create(VeterinarianDto.Request request) {
		if (veterinarianRepository.existsByLicenseNumber(request.licenseNumber())) {
			throw new BusinessException("A veterinarian with this license number already exists");
		}
		User user = userRepository.findById(request.userId())
				.orElseThrow(() -> new ResourceNotFoundException("User not found with id " + request.userId()));
		Veterinarian entity = veterinarianMapper.toEntity(request);
		entity.setUser(user);
		if (request.clinicLocationId() != null) {
			entity.setClinicLocation(resolveLocation(request.clinicLocationId()));
		}
		return veterinarianMapper.toResponse(veterinarianRepository.save(entity));
	}

	@Transactional(readOnly = true)
	public VeterinarianDto.Response get(Long id) {
		return veterinarianMapper.toResponse(findOrThrow(id));
	}

	@Transactional(readOnly = true)
	public Page<VeterinarianDto.Response> list(
			String specialization, Long locationId, String keyword, Pageable pageable) {
		var specification = VeterinarianSpecification.withFilters(specialization, locationId, keyword);
		return veterinarianRepository.findAll(specification, pageable).map(veterinarianMapper::toResponse);
	}

	@Transactional
	public VeterinarianDto.Response update(Long id, VeterinarianDto.Update request) {
		Veterinarian entity = findOrThrow(id);
		veterinarianMapper.updateEntity(request, entity);
		if (request.clinicLocationId() != null) {
			entity.setClinicLocation(resolveLocation(request.clinicLocationId()));
		}
		if (request.active() != null) {
			entity.setActive(request.active());
		}
		return veterinarianMapper.toResponse(veterinarianRepository.save(entity));
	}

	@Transactional
	public MessageResponseDTO delete(Long id) {
		veterinarianRepository.delete(findOrThrow(id));
		return new MessageResponseDTO("Veterinarian deleted successfully");
	}

	@Transactional
	public VeterinarianDto.Response assignCase(Long id, Long caseId) {
		Veterinarian veterinarian = findOrThrow(id);
		caseRepository.findById(caseId)
				.orElseThrow(() -> new ResourceNotFoundException("Rescue case not found with id " + caseId));
		// NOTE: RescueCase has no veterinarian FK column; veterinarian-case linkage is realized through Treatment.
		// Existence of both entities is validated here; persistence requires a schema relationship (see technical debt).
		return veterinarianMapper.toResponse(veterinarian);
	}

	private Veterinarian findOrThrow(Long id) {
		return veterinarianRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("Veterinarian not found with id " + id));
	}

	private Location resolveLocation(Long id) {
		return locationRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("Location not found with id " + id));
	}
}
