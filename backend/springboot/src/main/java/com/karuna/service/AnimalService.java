package com.karuna.service;

import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.karuna.dto.domain.AnimalDto;
import com.karuna.dto.MessageResponseDTO;
import com.karuna.entity.Animal;
import com.karuna.entity.Location;
import com.karuna.entity.RescueCase;
import com.karuna.entity.enums.AnimalCondition;
import com.karuna.entity.enums.AnimalSpecies;
import com.karuna.exception.ResourceNotFoundException;
import com.karuna.mapper.AnimalMapper;
import com.karuna.repository.AnimalRepository;
import com.karuna.repository.CaseRepository;
import com.karuna.repository.LocationRepository;
import com.karuna.repository.specification.AnimalSpecification;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class AnimalService {

	private final AnimalRepository animalRepository;
	private final AnimalMapper animalMapper;
	private final LocationRepository locationRepository;
	private final CaseRepository caseRepository;

	@Transactional
	public AnimalDto.Response create(AnimalDto.Request request) {
		Animal entity = animalMapper.toEntity(request);
		if (request.lastKnownLocationId() != null) {
			entity.setLastKnownLocation(resolveLocation(request.lastKnownLocationId()));
		}
		return animalMapper.toResponse(animalRepository.save(entity));
	}

	@Transactional(readOnly = true)
	public AnimalDto.Response get(Long id) {
		return animalMapper.toResponse(findOrThrow(id));
	}

	@Transactional(readOnly = true)
	public Page<AnimalDto.Response> list(
			AnimalSpecies species,
			AnimalCondition condition,
			Long locationId,
			Long caseId,
			String keyword,
			Pageable pageable) {
		var specification = AnimalSpecification.withFilters(species, condition, locationId, caseId, keyword);
		return animalRepository.findAll(specification, pageable).map(animalMapper::toResponse);
	}

	@Transactional
	public AnimalDto.Response update(Long id, AnimalDto.Update request) {
		Animal entity = findOrThrow(id);
		animalMapper.updateEntity(request, entity);
		if (request.lastKnownLocationId() != null) {
			entity.setLastKnownLocation(resolveLocation(request.lastKnownLocationId()));
		}
		if (request.active() != null) {
			entity.setActive(request.active());
		}
		return animalMapper.toResponse(animalRepository.save(entity));
	}

	@Transactional
	public MessageResponseDTO delete(Long id) {
		animalRepository.delete(findOrThrow(id));
		return new MessageResponseDTO("Animal deleted successfully");
	}

	@Transactional
	public AnimalDto.Response assignToCase(Long animalId, Long caseId) {
		Animal animal = findOrThrow(animalId);
		RescueCase rescueCase = caseRepository.findById(caseId)
				.orElseThrow(() -> new ResourceNotFoundException("Rescue case not found with id " + caseId));
		rescueCase.setAnimal(animal);
		caseRepository.save(rescueCase);
		return animalMapper.toResponse(animal);
	}

	@Transactional
	public AnimalDto.Response detachFromCase(Long animalId) {
		Animal animal = findOrThrow(animalId);
		List<RescueCase> cases = caseRepository.findByAnimalId(animal.getId());
		for (RescueCase rescueCase : cases) {
			rescueCase.setAnimal(null);
		}
		caseRepository.saveAll(cases);
		return animalMapper.toResponse(animal);
	}

	private Animal findOrThrow(Long id) {
		return animalRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("Animal not found with id " + id));
	}

	private Location resolveLocation(Long id) {
		return locationRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("Location not found with id " + id));
	}
}
