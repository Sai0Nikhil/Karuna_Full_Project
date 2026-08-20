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
import com.karuna.service.auth.EmailService;

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
	private final EmailService emailService;

	@Transactional
	public NgoDto.Response create(NgoDto.Request request) {
		if (ngoRepository.existsByRegistrationNumber(request.registrationNumber())) {
			throw new BusinessException("An NGO with this registration number already exists");
		}
		NGO entity = ngoMapper.toEntity(request);
		if (request.headquartersLocationId() != null) {
			entity.setHeadquartersLocation(resolveLocation(request.headquartersLocationId()));
		}
		
		NGO savedNgo = ngoRepository.save(entity);
		
		// Send email notification to Admin for verification
		try {
			String adminEmail = "reachsainikhil@gmail.com";
			String subject = "Karuṇā - ACTION REQUIRED: New NGO Registration Pending Verification";
			String body = "Hello Arjun,\n\n" +
					"A new NGO has registered on Karuṇā and is currently unverified:\n\n" +
					"NGO Name: " + savedNgo.getName() + "\n" +
					"Registration ID / Darpan Number: " + savedNgo.getRegistrationNumber() + "\n" +
					"Contact Email: " + savedNgo.getEmail() + "\n" +
					"Phone: " + (savedNgo.getPhoneNumber() != null ? savedNgo.getPhoneNumber() : "N/A") + "\n" +
					"Description: " + (savedNgo.getDescription() != null ? savedNgo.getDescription() : "N/A") + "\n\n" +
					"Action Item:\n" +
					"1. Verify their license details against the Darpan portal (https://ngodarpan.gov.in/).\n" +
					"2. Once checked, approve their registration from your Admin panel or by making a POST request to: http://localhost:8081/api/ngos/" + savedNgo.getId() + "/verify\n\n" +
					"Best,\n" +
					"Karuṇā Security Team";
			emailService.sendEmail(adminEmail, subject, body);
		} catch (Exception e) {
			System.err.println("Could not dispatch NGO registration email to Admin: " + e.getMessage());
		}

		return ngoMapper.toResponse(savedNgo);
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

	@Transactional
	public NgoDto.Response verifyNGO(Long id) {
		NGO ngo = findOrThrow(id);
		String regNum = ngo.getRegistrationNumber();
		if (regNum == null || regNum.trim().length() < 4) {
			throw new BusinessException("Verification failed: Registration number format is invalid");
		}
		ngo.setVerified(true);
		return ngoMapper.toResponse(ngoRepository.save(ngo));
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
