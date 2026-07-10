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

import com.karuna.dto.domain.AnimalDto;
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

@ExtendWith(MockitoExtension.class)
class AnimalServiceTest {

	@Mock
	private AnimalRepository animalRepository;
	@Mock
	private AnimalMapper animalMapper;
	@Mock
	private LocationRepository locationRepository;
	@Mock
	private CaseRepository caseRepository;

	private AnimalService animalService;

	@BeforeEach
	void setUp() {
		animalService = new AnimalService(animalRepository, animalMapper, locationRepository, caseRepository);
	}

	@Test
	void createResolvesLocationAndReturnsResponse() {
		AnimalDto.Request request = new AnimalDto.Request("Buddy", AnimalSpecies.DOG, "Pariah",
				AnimalCondition.INJURED, "Brown", "MALE", "2y", 1L);
		Animal entity = new Animal();
		AnimalDto.Response response = new AnimalDto.Response(1L, "Buddy", AnimalSpecies.DOG, "Pariah",
				AnimalCondition.INJURED, "Brown", "MALE", "2y", 1L, true, null, null, 0L);

		when(animalMapper.toEntity(request)).thenReturn(entity);
		when(locationRepository.findById(1L)).thenReturn(Optional.of(new Location()));
		when(animalRepository.save(entity)).thenReturn(entity);
		when(animalMapper.toResponse(entity)).thenReturn(response);

		AnimalDto.Response result = animalService.create(request);

		assertEquals(1L, result.id());
		verify(animalRepository).save(entity);
	}

	@Test
	void getThrowsWhenMissing() {
		when(animalRepository.findById(99L)).thenReturn(Optional.empty());
		assertThrows(ResourceNotFoundException.class, () -> animalService.get(99L));
	}

	@Test
	void updateAppliesFields() {
		Animal entity = new Animal();
		AnimalDto.Update update = new AnimalDto.Update("Max", AnimalSpecies.CAT, "Domestic",
				AnimalCondition.HEALTHY, "Black", "FEMALE", "3y", true, 2L);
		AnimalDto.Response response = new AnimalDto.Response(1L, "Max", AnimalSpecies.CAT, "Domestic",
				AnimalCondition.HEALTHY, "Black", "FEMALE", "3y", 2L, true, null, null, 0L);

		when(animalRepository.findById(1L)).thenReturn(Optional.of(entity));
		when(locationRepository.findById(2L)).thenReturn(Optional.of(new Location()));
		when(animalRepository.save(entity)).thenReturn(entity);
		when(animalMapper.toResponse(entity)).thenReturn(response);

		AnimalDto.Response result = animalService.update(1L, update);

		assertEquals("Max", result.name());
		verify(animalRepository).save(entity);
	}

	@Test
	void deleteRemovesEntity() {
		Animal entity = new Animal();
		when(animalRepository.findById(1L)).thenReturn(Optional.of(entity));

		animalService.delete(1L);

		verify(animalRepository).delete(entity);
	}

	@Test
	void assignToCaseLinksAnimal() {
		Animal animal = new Animal();
		RescueCase rescueCase = new RescueCase();
		AnimalDto.Response response = new AnimalDto.Response(1L, "Buddy", AnimalSpecies.DOG, null,
				AnimalCondition.INJURED, null, null, null, null, true, null, null, 0L);

		when(animalRepository.findById(1L)).thenReturn(Optional.of(animal));
		when(caseRepository.findById(5L)).thenReturn(Optional.of(rescueCase));
		when(caseRepository.save(rescueCase)).thenReturn(rescueCase);
		when(animalMapper.toResponse(animal)).thenReturn(response);

		animalService.assignToCase(1L, 5L);

		assertEquals(animal, rescueCase.getAnimal());
		verify(caseRepository).save(rescueCase);
	}

	@Test
	void listUsesSpecificationAndPagination() {
		Page<Animal> page = new PageImpl<>(List.of(new Animal()));
		when(animalRepository.findAll(any(Specification.class), any(Pageable.class))).thenReturn(page);
		when(animalMapper.toResponse(any(Animal.class)))
				.thenReturn(new AnimalDto.Response(1L, "Buddy", AnimalSpecies.DOG, null,
						AnimalCondition.INJURED, null, null, null, null, true, null, null, 0L));

		Page<AnimalDto.Response> result = animalService.list(
				AnimalSpecies.DOG, null, null, null, "bud", org.springframework.data.domain.Pageable.ofSize(10));

		assertEquals(1, result.getTotalElements());
		verify(animalRepository).findAll(any(Specification.class), any(Pageable.class));
	}

	@Test
	void assignToCaseMissingCaseThrows() {
		when(animalRepository.findById(1L)).thenReturn(Optional.of(new Animal()));
		when(caseRepository.findById(5L)).thenReturn(Optional.empty());

		assertThrows(ResourceNotFoundException.class, () -> animalService.assignToCase(1L, 5L));
		verify(caseRepository, never()).save(any());
	}
}
